/*
 * MineSrc
 * https://github.com/BluevaDevelopment/MineSrc
 *
 * Copyright (c) 2026 Blueva Development
 *
 * SPDX-License-Identifier: MIT
 */
package net.blueva.minesrc.host

import net.blueva.luak.LuaTable
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * `process`: external programs, run in the background. A script polls a
 * [Job] for its last line or for how often a pattern has appeared, so it can
 * draw progress for several at once without Lua ever running on two threads.
 */
class Processes {

    /**
     * Starts `{ command = {...}, dir = ..., log = ..., env = {...}, count = { name = regex } }`.
     * Everything the program prints goes to `log`.
     */
    fun spawn(spec: LuaTable): Job {
        val command = LuaTables.strings(LuaTables.field(spec, "command"))
        val directory = Path.of(LuaTables.string(spec, "dir") ?: ".")
        val log = Path.of(LuaTables.string(spec, "log") ?: error("process:spawn needs a log file"))
        val patterns = LuaTables.stringMap(LuaTables.field(spec, "count")).mapValues { Regex(it.value) }

        Files.createDirectories(directory)
        Files.createDirectories(log.parent)
        val process = ProcessBuilder(command)
            .directory(directory.toFile())
            .redirectErrorStream(true)
            .also { it.environment().putAll(LuaTables.stringMap(LuaTables.field(spec, "env"))) }
            .start()
        process.outputStream.close()
        return Job(process, log, patterns)
    }

    class Job internal constructor(private val process: Process, private val log: Path, patterns: Map<String, Regex>) {

        private val counts = ConcurrentHashMap<String, AtomicInteger>()

        @Volatile
        private var line = ""

        private val reader = Thread.ofVirtual().start {
            Files.newBufferedWriter(log).use { writer ->
                process.inputStream.bufferedReader().useLines { lines ->
                    for (text in lines) {
                        writer.write(text)
                        writer.newLine()
                        if (text.isNotBlank()) line = text
                        for ((name, pattern) in patterns) {
                            if (pattern.containsMatchIn(text)) counts.computeIfAbsent(name) { AtomicInteger() }.incrementAndGet()
                        }
                    }
                }
            }
        }

        /** Waits up to [milliseconds]; true once the program has exited and its output is read. */
        fun await(milliseconds: Int): Boolean {
            if (!process.waitFor(milliseconds.toLong(), TimeUnit.MILLISECONDS)) return false
            reader.join()
            return true
        }

        fun exitCode(): Int = process.exitValue()

        /** The last line that was not blank. */
        fun line(): String = line

        /** How many lines matched the pattern registered as [name]. */
        fun count(name: String): Int = counts[name]?.get() ?: 0

        fun kill() {
            process.descendants().forEach { it.destroy() }
            process.destroy()
        }
    }

    /** Whether [program] can be started at all, such as `git`. */
    fun available(program: String): Boolean =
        runCatching { ProcessBuilder(program, "--version").redirectErrorStream(true).start().waitFor() == 0 }.getOrDefault(false)
}
