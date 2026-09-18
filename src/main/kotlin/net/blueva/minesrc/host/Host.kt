/*
 * MineSrc
 * https://github.com/BluevaDevelopment/MineSrc
 *
 * Copyright (c) 2026 Blueva Development
 *
 * SPDX-License-Identifier: MIT
 */
package net.blueva.minesrc.host

import net.blueva.luak.LuaValue
import net.blueva.mawu.bridge.MawuFunction
import net.blueva.mawu.bridge.MawuLane

/**
 * Boots MineSrc: one lane with the host primitives as globals, then the
 * `main` script. Everything MineSrc does is decided in Lua; the Kotlin side
 * only offers what Lua cannot do alone.
 */
object Host {

    /** Runs `main` with the command line and returns its exit code. */
    fun run(args: List<String>): Int {
        val lane = lane()
        val main = lane.run("main")
        return try {
            lane.callFunction(main, LuaTables.list(args)) as? Int ?: 0
        } catch (failure: Throwable) {
            System.err.println("error: ${failure.message}")
            failure.printStackTrace()
            1
        }
    }

    /** A lane with every primitive installed, as scripts and tests expect it. */
    fun lane(classLoader: ClassLoader = Host::class.java.classLoader): MawuLane {
        val lane = MawuLane(classLoader = classLoader)
        val modules = HashMap<String, LuaValue>()
        lane.exposeFunction("use", MawuFunction { args ->
            val id = args.single() as String
            modules[id] ?: lane.run(id).also { modules[id] = it }
        })
        lane.expose("host", HostInfo(classLoader))
        lane.expose("term", Terminal())
        lane.expose("http", Http())
        lane.expose("fs", FileSystem())
        lane.expose("zip", Archives())
        lane.expose("process", Processes())
        lane.expose("json", JsonCodec())
        lane.expose("remap", Remapper())
        return lane
    }
}
