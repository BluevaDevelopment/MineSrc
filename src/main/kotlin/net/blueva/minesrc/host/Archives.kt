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
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.attribute.PosixFilePermission
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

/** `zip`: reading jars and archives, and writing small ones. */
class Archives {

    /** The names of every file entry, in archive order. */
    fun entries(archive: String): LuaTable = ZipFile(archive).use { zip ->
        LuaTables.list(zip.entries().asSequence().filterNot { it.isDirectory }.map { it.name }.toList())
    }

    fun has(archive: String, name: String): Boolean = ZipFile(archive).use { it.getEntry(name) != null }

    /**
     * Extracts the entries [mapping] names (entry name to path under
     * [target]) and returns how many were written.
     */
    fun extract(archive: String, target: String, mapping: LuaTable): Int {
        val wanted = LuaTables.stringMap(mapping)
        var written = 0
        ZipFile(archive).use { zip ->
            for (entry in zip.entries()) {
                val relative = wanted[entry.name] ?: continue
                if (entry.isDirectory) continue
                val destination = inside(Path.of(target), relative, archive)
                Files.createDirectories(destination.parent)
                zip.getInputStream(entry).use { Files.copy(it, destination, StandardCopyOption.REPLACE_EXISTING) }
                written++
            }
        }
        return written
    }

    /** Extracts everything in a zip. */
    fun unzip(archive: String, target: String): Int = ZipFile(archive).use { zip ->
        var written = 0
        for (entry in zip.entries()) {
            val destination = inside(Path.of(target), entry.name, archive)
            if (entry.isDirectory) {
                Files.createDirectories(destination)
                continue
            }
            Files.createDirectories(destination.parent)
            zip.getInputStream(entry).use { Files.copy(it, destination, StandardCopyOption.REPLACE_EXISTING) }
            written++
        }
        written
    }

    /** Extracts a `.tar.gz`, keeping symbolic links and the executable bit. */
    fun untar(archive: String, target: String) {
        val root = Path.of(target)
        TarArchiveInputStream(GzipCompressorInputStream(Files.newInputStream(Path.of(archive)).buffered())).use { tar ->
            while (true) {
                val entry = tar.nextEntry ?: break
                val destination = inside(root, entry.name, archive)
                when {
                    entry.isDirectory -> Files.createDirectories(destination)
                    entry.isSymbolicLink -> {
                        Files.createDirectories(destination.parent)
                        Files.deleteIfExists(destination)
                        Files.createSymbolicLink(destination, Path.of(entry.linkName))
                    }
                    else -> {
                        Files.createDirectories(destination.parent)
                        Files.newOutputStream(destination).use { tar.copyTo(it) }
                        if (entry.mode and EXECUTABLE != 0) executable(destination)
                    }
                }
            }
        }
    }

    /** Writes a jar from entry names and their text content. */
    fun write(archive: String, entries: LuaTable) {
        val path = Path.of(archive)
        path.parent?.let(Files::createDirectories)
        ZipOutputStream(Files.newOutputStream(path)).use { zip ->
            for ((name, content) in LuaTables.stringMap(entries).toSortedMap()) {
                zip.putNextEntry(ZipEntry(name))
                zip.write(content.toByteArray())
                zip.closeEntry()
            }
        }
    }

    private fun executable(path: Path) {
        runCatching {
            Files.setPosixFilePermissions(
                path,
                Files.getPosixFilePermissions(path) +
                    setOf(PosixFilePermission.OWNER_EXECUTE, PosixFilePermission.GROUP_EXECUTE, PosixFilePermission.OTHERS_EXECUTE),
            )
        }
    }

    /** Refuses entries such as `../../x` that would land outside [root]. */
    private fun inside(root: Path, name: String, archive: String): Path {
        val resolved = root.resolve(name).normalize()
        if (!resolved.startsWith(root.normalize())) throw IOException("$archive has an entry outside its folder: $name")
        return resolved
    }

    private companion object {
        const val EXECUTABLE = 0b001_001_001
    }
}
