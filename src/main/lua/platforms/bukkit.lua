--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- CraftBukkit and the Bukkit API, built locally with BuildTools.
local spigotmc = use('lib/spigotmc')

local bukkit = {
  name = 'bukkit',
  description = 'CraftBukkit server and the Bukkit API, built with BuildTools',
  sides = { 'server', 'api' },
}

function bukkit.versions(all)
  return spigotmc.versions(all)
end

function bukkit.latest()
  return spigotmc.latest()
end

function bukkit.prepare(version, wanted, context)
  return spigotmc.targets('craftbukkit', 'bukkit', version, wanted, context)
end

return bukkit
