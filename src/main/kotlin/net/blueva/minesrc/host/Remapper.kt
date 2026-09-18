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
import net.fabricmc.mappingio.adapter.MappingSourceNsSwitch
import net.fabricmc.mappingio.format.proguard.ProGuardFileReader
import net.fabricmc.mappingio.tree.MemoryMappingTree
import net.fabricmc.tinyremapper.IMappingProvider
import net.fabricmc.tinyremapper.NonClassCopyMode
import net.fabricmc.tinyremapper.OutputConsumerPath
import net.fabricmc.tinyremapper.TinyRemapper
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * `remap`: applies Mojang's ProGuard mappings to a jar. The mappings are
 * written from the named side, so they are read as `named -> official` and
 * turned around.
 */
class Remapper {

    fun proguard(jar: String, mappings: String, libraries: LuaTable, output: String) {
        val target = Path.of(output)
        Files.createDirectories(target.parent)
        val partial = Files.createTempFile(target.parent, target.fileName.toString(), ".part")
        Files.delete(partial)

        val remapper = TinyRemapper.newRemapper()
            .withMappings(provider(read(Path.of(mappings))))
            .renameInvalidLocals(true)
            .rebuildSourceFilenames(true)
            .ignoreConflicts(true)
            .build()
        try {
            OutputConsumerPath.Builder(partial).assumeArchive(true).build().use { consumer ->
                consumer.addNonClassFiles(Path.of(jar), NonClassCopyMode.FIX_META_INF, remapper)
                remapper.readInputs(Path.of(jar))
                remapper.readClassPath(*LuaTables.strings(libraries).map(Path::of).toTypedArray())
                remapper.apply(consumer)
            }
        } finally {
            remapper.finish()
        }
        Files.move(partial, target, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
    }

    private fun read(mappings: Path): MemoryMappingTree {
        val tree = MemoryMappingTree()
        Files.newBufferedReader(mappings).use { reader ->
            ProGuardFileReader.read(reader, NAMED, OFFICIAL, MappingSourceNsSwitch(tree, OFFICIAL))
        }
        return tree
    }

    private fun provider(tree: MemoryMappingTree) = IMappingProvider { acceptor ->
        for (type in tree.classes) {
            val owner = type.srcName
            type.getDstName(0)?.let { acceptor.acceptClass(owner, it) }
            for (method in type.methods) {
                val name = method.getDstName(0) ?: continue
                acceptor.acceptMethod(IMappingProvider.Member(owner, method.srcName, method.srcDesc), name)
            }
            for (field in type.fields) {
                val name = field.getDstName(0) ?: continue
                acceptor.acceptField(IMappingProvider.Member(owner, field.srcName, field.srcDesc), name)
            }
        }
    }

    private companion object {
        const val NAMED = "named"
        const val OFFICIAL = "official"
    }
}
