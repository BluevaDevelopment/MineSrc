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
import net.blueva.luak.LuaValue

/** Moving lists and maps of strings between Lua tables and Kotlin. */
object LuaTables {

    fun list(values: List<String>): LuaTable =
        LuaTable().also { table -> values.forEachIndexed { index, value -> table.set(index + 1, LuaValue.valueOf(value)) } }

    fun field(table: LuaValue, key: String): LuaValue = table.get(key) ?: LuaValue.NIL

    fun string(table: LuaValue, key: String): String? = field(table, key).takeUnless { it.isnil() }?.tojstring()

    /** The strings of a sequence; `nil` is an empty list. */
    fun strings(value: LuaValue): List<String> {
        if (!value.istable()) return emptyList()
        return (1..value.length()).map { (value.get(it) ?: LuaValue.NIL).tojstring() }
    }

    /** Every string key of a table with its value as a string; `nil` is an empty map. */
    fun stringMap(value: LuaValue): Map<String, String> {
        if (!value.istable()) return emptyMap()
        val map = LinkedHashMap<String, String>()
        var key: LuaValue = LuaValue.NIL
        while (true) {
            val next = value.next(key) ?: break
            key = next.arg1()
            if (key.isnil()) break
            map[key.tojstring()] = next.arg(2).tojstring()
        }
        return map
    }
}
