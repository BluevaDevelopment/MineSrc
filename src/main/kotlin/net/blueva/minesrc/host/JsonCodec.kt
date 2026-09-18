/*
 * MineSrc
 * https://github.com/BluevaDevelopment/MineSrc
 *
 * Copyright (c) 2026 Blueva Development
 *
 * SPDX-License-Identifier: MIT
 */
package net.blueva.minesrc.host

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.longOrNull
import net.blueva.luak.LuaTable
import net.blueva.luak.LuaValue

/** `json`: JSON text to Lua tables and back. */
class JsonCodec {

    private val pretty = Json { prettyPrint = true }

    fun decode(text: String): LuaValue = toLua(Json.parseToJsonElement(text))

    /** A table with keys 1..n becomes an array, any other table an object with sorted keys. */
    fun encode(value: LuaValue): String = pretty.encodeToString(JsonElement.serializer(), toJson(value))

    private fun toLua(element: JsonElement): LuaValue = when (element) {
        is JsonNull -> LuaValue.NIL
        is JsonPrimitive -> when {
            element.isString -> LuaValue.valueOf(element.content)
            element.booleanOrNull != null -> if (element.booleanOrNull == true) LuaValue.TRUE else LuaValue.FALSE
            element.longOrNull != null -> LuaValue.valueOf(element.longOrNull!!)
            else -> LuaValue.valueOf(element.content.toDouble())
        }
        is JsonArray -> LuaTable().also { table -> element.forEachIndexed { index, item -> table.set(index + 1, toLua(item)) } }
        is JsonObject -> LuaTable().also { table -> element.forEach { (key, item) -> table.set(key, toLua(item)) } }
    }

    private fun toJson(value: LuaValue): JsonElement = when {
        value.isnil() -> JsonNull
        value.isboolean() -> JsonPrimitive(value.toboolean())
        value.isint() -> JsonPrimitive(value.tolong())
        value.isnumber() && value.type() == LuaValue.TNUMBER -> JsonPrimitive(value.todouble())
        value.istable() -> {
            val length = value.length()
            val keys = LuaTables.stringMap(value).keys
            if (length > 0 && keys.size == length) {
                JsonArray((1..length).map { toJson(value.get(it) ?: LuaValue.NIL) })
            } else {
                JsonObject(keys.sorted().associateWith { toJson(value.get(it) ?: LuaValue.NIL) })
            }
        }
        else -> JsonPrimitive(value.tojstring())
    }
}
