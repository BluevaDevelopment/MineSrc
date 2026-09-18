/*
 * MineSrc
 * https://github.com/BluevaDevelopment/MineSrc
 *
 * Copyright (c) 2026 Blueva Development
 *
 * SPDX-License-Identifier: MIT
 */
package net.blueva.minesrc.host

/** `term`: the console, and the one line that can be redrawn in place. */
class Terminal {

    private val interactive = System.console() != null
    private val width = System.getenv("COLUMNS")?.toIntOrNull()?.takeIf { it > 40 } ?: 100
    private var live = false

    fun interactive(): Boolean = interactive

    fun color(): Boolean = interactive && System.getenv("NO_COLOR") == null

    fun width(): Int = width

    fun out(text: String) {
        clear()
        println(text)
    }

    fun err(text: String) {
        clear()
        System.err.println(text)
    }

    /** Draws [text] over the current line; nothing when the output is not a terminal. */
    fun live(text: String) {
        if (!interactive) return
        val fitted = if (text.length >= width) text.take(width - 1) else text
        print("\r" + fitted.padEnd(width - 1))
        System.out.flush()
        live = true
    }

    fun clear() {
        if (!live) return
        print("\r" + " ".repeat(width - 1) + "\r")
        System.out.flush()
        live = false
    }
}
