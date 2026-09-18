--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- SpigotMC's version index and BuildTools, shared by Spigot and CraftBukkit.
local bundler = use('tools/bundler')
local buildtools = use('tools/buildtools')
local errors = use('core/errors')
local jdks = use('core/jdks')
local net = use('core/net')
local shaded = use('lib/shaded')
local sides = use('lib/sides')
local ui = use('core/ui')
local versions = use('lib/versions')

local INDEX = 'https://hub.spigotmc.org/versions/'

local spigotmc = {}

-- Every version BuildTools can build, newest first. The index also lists build numbers, which are skipped.
function spigotmc.versions(all)
  local list = {}
  for name in net.text(INDEX):gmatch('href="([^"/]+)%.json"') do
    if name:find('%.') then list[#list + 1] = name end
  end
  return versions.filter(versions.newestFirst(list), all)
end

function spigotmc.latest()
  return spigotmc.versions(false)[1]
end

-- The Java range BuildTools accepts, from class file versions (52 is Java 8).
-- Versions that predate the field build on Java 8.
local function javaRange(info)
  local range = info.javaVersions
  if not range then return 8, 8 end
  return range[1] - 44, range[2] - 44
end

-- compile is 'spigot' or 'craftbukkit'; command is how the user names it.
function spigotmc.targets(compile, command, version, wanted, context)
  local info = net.jsonOrNil(INDEX .. version .. '.json')
  if not info then
    errors.fail("BuildTools has no version '" .. version .. "'. See 'minesrc versions " .. command .. "'.")
  end

  -- The Mojang-mapped jar exists from 1.17 on; before that the names stay Spigot's.
  local remapped = versions.compare(version, '1.17') >= 0
  local built = buildtools.build(version, compile, jdks.find(javaRange(info)), { remapped = remapped, refresh = context.refresh })
  local list = {}
  if sides.wants(wanted, 'server') then
    local server = bundler.unpack(built.jar)
    local exclude = #server.libraries == 0 and shaded or {}
    list[#list + 1] = { name = 'server', jar = built.remapped or server.jar, libraries = server.libraries, exclude = exclude }
  end
  if sides.wants(wanted, 'api') then
    if built.api then
      list[#list + 1] = { name = 'api', sources = built.api }
    else
      ui.warn('BuildTools left no API sources for ' .. version)
    end
  end
  return list
end

return spigotmc
