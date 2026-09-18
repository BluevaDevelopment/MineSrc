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
import net.blueva.mawu.runtime.MawuScripts
import java.util.Properties

/** `host`: what only the running build knows about itself. */
class HostInfo(private val classLoader: ClassLoader) {

    private val version: String by lazy {
        val properties = Properties()
        classLoader.getResourceAsStream("minesrc.properties")?.use(properties::load)
        properties.getProperty("version") ?: "dev"
    }

    /** The version this build carries, expanded into `minesrc.properties` at build time. */
    fun version(): String = version

    /** The ids of the compiled scripts under [prefix], such as every `platforms/` script. */
    fun scripts(prefix: String): LuaTable = LuaTables.list(MawuScripts.ids(classLoader).filter { it.startsWith(prefix) }.sorted())
}
