/*
 * MineSrc
 * https://github.com/BluevaDevelopment/MineSrc
 *
 * Copyright (c) 2026 Blueva Development
 *
 * SPDX-License-Identifier: MIT
 */
package net.blueva.minesrc.decompile

import org.jetbrains.java.decompiler.main.extern.IFernflowerLogger
import java.nio.file.Files
import java.nio.file.Path
import kotlin.system.exitProcess

/**
 * The `main` of a decompiler worker JVM. `decompile/decompiler.lua` writes
 * what it should do into a file, one `key<TAB>value` per line: `destination`,
 * `source`, `library`, `option` (`name=value`) and `class`.
 *
 * It answers through its output: `@done <class>` per finished class, anything
 * else is a message for the log.
 */
object DecompileWorker {

    @JvmStatic
    fun main(args: Array<String>) {
        val spec = Files.readAllLines(Path.of(args.single()))
            .filter { it.isNotBlank() }
            .map { it.substringBefore('\t') to it.substringAfter('\t') }
        fun all(key: String) = spec.filter { it.first == key }.map { it.second }

        val out = System.out
        val options: Map<String, Any> = all("option").associate { it.substringBefore('=') to it.substringAfter('=') }
        val saver = DirectoryResultSaver(Path.of(all("destination").single()), options, Logger()) { name ->
            synchronized(out) { out.println("@done $name") }
        }
        try {
            saver.add(Path.of(all("source").single()), all("library").map(Path::of))
            all("class").forEach(saver::addToMustBeDecompiled)
            saver.decompileContext()
        } catch (failure: Throwable) {
            failure.printStackTrace(out)
            out.flush()
            exitProcess(1)
        }
        out.flush()
        exitProcess(0)
    }

    /** Fernflower's messages, prefixed with their severity, for the worker's log. */
    private class Logger : IFernflowerLogger() {

        override fun writeMessage(message: String?, severity: Severity) {
            if (accepts(severity)) synchronized(System.out) { println(severity.prefix + message) }
        }

        override fun writeMessage(message: String?, severity: Severity, t: Throwable?) {
            if (!accepts(severity)) return
            synchronized(System.out) {
                println(severity.prefix + message)
                t?.let { println("       $it") }
            }
        }
    }
}
