<h1 align="center">MineSrc</h1>

<p align="center">
  <strong>The source code of any Minecraft server, one command away. Written in Lua, running on the JVM.</strong>
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-26.2-blue">
  <img alt="Lua" src="https://img.shields.io/badge/Lua-5.5.1-000080?logo=lua&logoColor=white">
  <img alt="Mawu" src="https://img.shields.io/badge/Mawu-26.3-000080">
  <img alt="Kotlin" src="https://img.shields.io/badge/Kotlin-2.4.20-7F52FF?logo=kotlin&logoColor=white">
  <img alt="Java" src="https://img.shields.io/badge/Java-25+-ED8B00?logo=openjdk&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green">
</p>

## Overview

MineSrc is a command line tool that gives you readable source code for a
Minecraft server or client, for a platform and a version you name:

```text
minesrc vanilla 1.21.8
minesrc paper 26.2
minesrc spigot 1.21.8
```

It fetches the jars (or builds them, when that is the only way), renames
obfuscated code to Mojang's official names, decompiles everything with
JetBrains' [Fernflower](https://github.com/JetBrains/fernflower) and writes a
plain `src/main/java` tree you can open in any IDE.

MineSrc is also a showcase for [Mawu](https://github.com/BluevaDevelopment/Mawu):
the tool itself is written in Lua, with Kotlin only as a thin host (see
[Written in Lua](#written-in-lua)).

## Platforms

| Platform | Where the jars come from | Output folders |
|---|---|---|
| `vanilla` | Mojang's launcher metadata | `server`, `client` |
| `paper` | PaperMC's Fill API, patched with Paperclip | `server`, `api` |
| `folia` | PaperMC's Fill API, patched with Paperclip | `server`, `api` |
| `purpur` | Purpur's API, patched with Paperclip | `server`, `api` |
| `spigot` | Built locally with SpigotMC's BuildTools | `server`, `api` |
| `bukkit` | Built locally with BuildTools (CraftBukkit) | `server`, `api` |

`api` folders hold the **real sources** of the API (Paper API, Spigot API,
Bukkit), with their Javadoc, rather than decompiled code: Paper, Folia and
Purpur publish them to their Maven repositories, and BuildTools leaves them in
its checkout.

```text
minesrc platforms               # the table above
minesrc versions paper          # every release, newest first
minesrc versions vanilla --all  # snapshots and pre-releases too
```

## Usage

```text
minesrc <platform> [<version>] [options]
```

Leave the version out to get the latest one (for Paper and its forks, the
latest with a stable build).

| Option | Meaning |
|---|---|
| `-o`, `--output DIR` | Folder to write into. Defaults to `./<platform>-<version>` |
| `-s`, `--side NAME` | Only one part, such as `--side server`. Repeatable |
| `-w`, `--workers N` | Decompiler processes run at once. Defaults to half the cores, at most 4 |
| `-m`, `--memory SIZE` | Heap for each decompiler process, like `2g` or `1536m`. Defaults to `2g` |
| `-f`, `--force` | Replace an output folder MineSrc wrote before |
| `--no-remap` | Keep obfuscated names instead of applying Mojang's mappings |
| `--refresh` | Patch or build again instead of reusing a previous result |
| `-v`, `--verbose` | Print every step, download and cache hit |

```text
minesrc vanilla 1.21.8 --side client
minesrc paper --output ~/src/paper-latest
minesrc spigot 1.20.4 --workers 2 --memory 3g
```

## What You Get

```text
paper-1.21.8/
  minesrc.json          what was built, from which version, and when
  server/
    src/main/java/      decompiled classes, one .java file per top level class
    src/main/resources/ everything else the jar carries (data packs, assets, configs)
  api/
    src/main/java/      the API's own sources
```

## How It Works

1. **Resolve.** The platform finds the version in its API and downloads what
   it needs, verified against the published checksum.
2. **Prepare.** Some jars need work before they can be read:
   - the vanilla server (since 1.18) and Spigot's jar are *bundles* with the
     real server and its libraries inside, which are unpacked;
   - Paper, Folia and Purpur ship Paperclip, which is run in patch-only mode
     to produce the patched server without starting it;
   - Spigot and CraftBukkit have no downloadable jar at all, so
     [BuildTools](https://www.spigotmc.org/wiki/buildtools/) builds them.
3. **Remap.** Versions from 1.14.4 to 1.21.x are obfuscated and ship Mojang's
   official mappings, which are applied so the code reads
   `ServerPlayer.connection` instead of one- and two-letter names. Minecraft
   26.1 and later is not obfuscated, so there is nothing to undo. Spigot is taken from its
   Mojang-mapped build, and Paper has used Mojang's names since 1.20.5.
4. **Decompile.** Fernflower runs in several worker processes at once, each
   with the whole jar and its libraries as context and its own share of the
   classes. Classes a library already provides (dependencies older jars carry
   inside them) are skipped.

## Requirements

| Component | Requirement |
|---|---|
| Java | 25 or later to run MineSrc (Fernflower needs it) |
| Git | For `spigot` and `bukkit`, which BuildTools builds from Git repositories |
| Disk | Around 1 GB per server version, more for BuildTools |

Other Java versions are found or fetched on their own. BuildTools needs the
Java range SpigotMC lists for each version (Java 8 for 1.8.8, 8 to 16 for
1.16.5, 25 or 26 for 26.2). MineSrc looks for an installed JDK in that range
that actually starts, and otherwise downloads one into its cache:
[Eclipse Temurin](https://adoptium.net), or [Azul Zulu](https://www.azul.com/downloads/)
where Temurin has no native build (Java 8 on Apple Silicon).

## Installation

Every commit to `main` is built and published as a
[GitHub release](https://github.com/BluevaDevelopment/MineSrc/releases/latest)
with a single runnable jar. Download it and run it with Java 25:

```text
curl -LO https://github.com/BluevaDevelopment/MineSrc/releases/download/v26.2/minesrc-26.2.jar
java -jar minesrc-26.2.jar vanilla 1.21.8
```

To type `minesrc` on its own, point an alias at the jar:

```text
alias minesrc='java -jar /path/to/minesrc-26.2.jar'           # macOS and Linux
doskey minesrc=java -jar C:\path\to\minesrc-26.2.jar $*      # Windows
```

### Building From Source

```text
git clone https://github.com/BluevaDevelopment/MineSrc.git
cd MineSrc
./gradlew build
```

The jar is written to `build/libs/minesrc-<version>.jar`. `./gradlew installDist`
also puts a launcher at `build/install/minesrc/bin/minesrc`.

## Cache

Downloads, patched and remapped jars, BuildTools builds and downloaded JDKs are
kept between runs, so the second time a version is asked for starts straight at
decompiling.

| Variable | Default | Holds |
|---|---|---|
| `MINESRC_HOME` | `~/.minesrc` | Downloads, intermediate jars, JDKs |
| `MINESRC_BUILDTOOLS_DIR` | `~/.minesrc/buildtools` | BuildTools' checkout and builds |

BuildTools cannot run from a path containing spaces or `!`. When the MineSrc
home has either, BuildTools runs from the system's temporary folder instead;
set `MINESRC_BUILDTOOLS_DIR` to keep it somewhere permanent.

```text
minesrc cache              # where everything is, and its size
minesrc cache clean        # remove downloads and intermediate jars
minesrc cache clean --all  # also remove JDKs and the BuildTools checkout
```

## Written in Lua

MineSrc is a Lua program that runs on the JVM, built with
[Mawu](https://github.com/BluevaDevelopment/Mawu). Every script under
[`src/main/lua`](src/main/lua) is compiled to Luak bytecode at build time and
travels inside the jar, so nothing is parsed when the command starts, and the
build fails on a syntax error, an undefined global or a Java class that does
not exist.

Lua decides everything: the command line, where each platform's jars come
from, the download cache, finding and fetching JDKs, running Paperclip and
BuildTools, reading bundles, splitting classes between decompiler workers and
laying out the output. Kotlin is a thin host that hands Lua what it cannot do
alone, as a handful of globals:

| Global | Offers |
|---|---|
| `http` | Requests, and downloads that run in the background with checksums |
| `fs` | Files and folders by path |
| `zip` | Reading jars, extracting entries, unpacking `.zip` and `.tar.gz` |
| `process` | Starting programs and following their output from Lua |
| `json` | JSON text to Lua tables and back |
| `remap` | Applying Mojang's ProGuard mappings to a jar |
| `term` | The console, and a line redrawn in place |
| `host` | The build's version and the scripts compiled into it |
| `use` | Loading another script once, like `require` |

Scripts also reach the JDK directly through Mawu's `java` global, as in
`java.lang.System:getProperty('os.name')`. The only other Kotlin is the
decompiler worker, because it has to extend one of Fernflower's classes.

```text
src/main/lua/
  main.lua        the entry point
  cli/            the command line: parser, help, commands
  core/           errors, console, cache, downloads, JDKs, processes
  tools/          bundles, Paperclip, BuildTools, Maven
  decompile/      root classes, sharding, the worker pool
  pipeline/       from a platform's targets to the output folder
  lib/            what platforms share: Mojang, Fill, SpigotMC, versions
  platforms/      one script per platform
```

The tests are Lua too (`src/test/lua/tests`), run as JUnit tests by a small
runner.

### Adding a Platform

A platform is a script in `platforms/` that returns a table with a name, the
folders it can produce, and three functions:

```lua
local bundler = use('tools/bundler')
local mojang = use('lib/mojang')

local vanilla = {
  name = 'vanilla',
  description = "Mojang's own client and server",
  sides = { 'server', 'client' },
}

function vanilla.versions(all) return mojang.versions(all) end

function vanilla.latest() return mojang.latest() end

-- One entry per output folder.
function vanilla.prepare(version, sides, context)
  local meta = mojang.version(version)
  local server = bundler.unpack(mojang.file(meta, 'server'))
  return {
    {
      name = 'server',
      jar = server.jar,
      mappings = mojang.file(meta, 'server_mappings'),
      libraries = server.libraries,
    },
  }
end

return vanilla
```

A target is decompiled from `jar` (remapped first when `mappings` is set, with
`exclude` listing class prefixes to skip), or copied from `sources`, a sources
jar or folder. The script is picked up by the build, and becomes
`minesrc <name>` with no other change.

## Legal

Minecraft is a trademark of Mojang Studios, and its code belongs to Mojang and
Microsoft. MineSrc does not distribute any of it: everything is downloaded from
the official sources on your machine, and what it produces is for your own
reference, debugging and development. Do not publish decompiled code. MineSrc
is not affiliated with Mojang, Microsoft, PaperMC, SpigotMC or PurpurMC.

## Authors

- Blueva
- Whiron

Website: [blueva.net](https://blueva.net)

## License

MineSrc is distributed under the [MIT License](LICENSE).
