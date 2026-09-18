/*
 * MineSrc
 * https://github.com/BluevaDevelopment/MineSrc
 *
 * Copyright (c) 2026 Blueva Development
 *
 * SPDX-License-Identifier: MIT
 */
package net.blueva.minesrc

import net.blueva.minesrc.host.Host
import kotlin.system.exitProcess

fun main(args: Array<String>) {
    exitProcess(Host.run(args.toList()))
}
