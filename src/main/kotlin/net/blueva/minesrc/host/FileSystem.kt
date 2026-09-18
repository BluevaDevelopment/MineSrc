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
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
import kotlin.io.path.ExperimentalPathApi
import kotlin.io.path.deleteRecursively
import kotlin.streams.asSequence

/** `fs`: files and folders, by path string. */
class FileSystem {

    fun exists(path: String): Boolean = Files.exists(Path.of(path))

    fun isFile(path: String): Boolean = Files.isRegularFile(Path.of(path))

    fun isDirectory(path: String): Boolean = Files.isDirectory(Path.of(path))

    /** [base] and [child] joined with the system's separator. */
    fun join(base: String, child: String): String = Path.of(base).resolve(child).toString()

    fun parent(path: String): String? = Path.of(path).parent?.toString()

    fun name(path: String): String = Path.of(path).fileName.toString()

    fun absolute(path: String): String = Path.of(path).toAbsolutePath().normalize().toString()

    /** [path] relative to [base], with `/` separators. */
    fun relative(base: String, path: String): String = Path.of(base).relativize(Path.of(path)).joinToString("/")

    /** The names inside a folder, sorted; empty when it does not exist. */
    fun list(path: String): LuaTable {
        val directory = Path.of(path)
        if (!Files.isDirectory(directory)) return LuaTable()
        return Files.list(directory).use { stream -> LuaTables.list(stream.asSequence().map { it.fileName.toString() }.sorted().toList()) }
    }

    /** Every file under [path], at most [depth] levels down, sorted. */
    fun walk(path: String, depth: Int): LuaTable {
        val root = Path.of(path)
        if (!Files.isDirectory(root)) return LuaTable()
        return Files.walk(root, depth).use { stream ->
            LuaTables.list(stream.asSequence().filter { Files.isRegularFile(it) }.map { it.toString() }.sorted().toList())
        }
    }

    fun mkdirs(path: String) {
        Files.createDirectories(Path.of(path))
    }

    /** Deletes a file, or a folder and everything in it. */
    @OptIn(ExperimentalPathApi::class)
    fun delete(path: String) {
        val target = Path.of(path)
        if (Files.exists(target)) target.deleteRecursively()
    }

    fun copy(from: String, to: String) {
        val target = Path.of(to)
        target.parent?.let(Files::createDirectories)
        Files.copy(Path.of(from), target, StandardCopyOption.REPLACE_EXISTING)
    }

    /** Copies the contents of one folder into another. */
    fun copyTree(from: String, to: String) {
        val source = Path.of(from)
        val target = Path.of(to)
        Files.walk(source).use { paths ->
            for (path in paths) {
                val destination = target.resolve(source.relativize(path).toString())
                if (Files.isDirectory(path)) Files.createDirectories(destination)
                else Files.copy(path, destination, StandardCopyOption.REPLACE_EXISTING)
            }
        }
    }

    fun move(from: String, to: String) {
        Files.move(Path.of(from), Path.of(to), StandardCopyOption.REPLACE_EXISTING)
    }

    fun read(path: String): String = Files.readString(Path.of(path))

    fun write(path: String, text: String) {
        val target = Path.of(path)
        target.parent?.let(Files::createDirectories)
        Files.writeString(target, text)
    }

    fun size(path: String): Long = Files.size(Path.of(path))

    /** Milliseconds since the epoch. */
    fun modified(path: String): Long = Files.getLastModifiedTime(Path.of(path)).toMillis()

    fun isEmpty(path: String): Boolean = Files.list(Path.of(path)).use { it.findFirst().isEmpty }

    /** A new empty folder in the system's temporary folder. */
    fun temporary(prefix: String): String = Files.createTempDirectory(prefix).toString()

    /** The hex digest of a file: `sha1`, `sha256`, `sha512` or `md5`. */
    fun digest(path: String, algorithm: String): String {
        val digest = MessageDigest.getInstance(algorithm.uppercase().replace("SHA", "SHA-"))
        Files.newInputStream(Path.of(path)).use { input ->
            val buffer = ByteArray(1 shl 16)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    /** The sha1 of a string, for cache keys. */
    fun hash(text: String): String =
        MessageDigest.getInstance("SHA-1").digest(text.toByteArray()).joinToString("") { "%02x".format(it) }
}
