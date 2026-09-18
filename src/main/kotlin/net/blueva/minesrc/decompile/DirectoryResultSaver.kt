/*
 * MineSrc
 * https://github.com/BluevaDevelopment/MineSrc
 *
 * Copyright (c) 2026 Blueva Development
 *
 * SPDX-License-Identifier: MIT
 */
package net.blueva.minesrc.decompile

import org.jetbrains.java.decompiler.main.decompiler.ConsoleDecompiler
import org.jetbrains.java.decompiler.main.extern.IFernflowerLogger
import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import java.util.jar.Manifest

/**
 * Fernflower's console decompiler, writing each class of a jar as a plain
 * `.java` file under [destination] instead of into an output jar. Several
 * workers can share one destination, since each writes different files.
 */
internal class DirectoryResultSaver(
    private val destination: Path,
    options: Map<String, Any>,
    logger: IFernflowerLogger,
    private val onClass: (String) -> Unit,
) : ConsoleDecompiler(destination.toFile(), options, logger) {

    override fun saveClassEntry(path: String?, archiveName: String?, qualifiedName: String?, entryName: String, content: String?) {
        if (content != null) {
            val file = destination.resolve(entryName)
            Files.createDirectories(file.parent)
            Files.writeString(file, content)
        }
        onClass(qualifiedName ?: entryName)
    }

    override fun createArchive(path: String?, archiveName: String?, manifest: Manifest?) = Unit

    override fun saveDirEntry(path: String?, archiveName: String?, entryName: String?) = Unit

    override fun copyEntry(source: String?, path: String?, archiveName: String?, entry: String?) = Unit

    override fun closeArchive(path: String?, archiveName: String?) = Unit

    fun add(source: Path, libraries: List<Path>) {
        libraries.forEach { addLibrary(File(it.toString())) }
        addSource(File(source.toString()))
    }
}
