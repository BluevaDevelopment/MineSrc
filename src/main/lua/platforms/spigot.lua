--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Spigot, built locally with BuildTools: there is no other way to get it.
local spigotmc = use('lib/spigotmc')

local spigot = {
  name = 'spigot',
  description = 'SpigotMC server and the Spigot API, built with BuildTools',
  sides = { 'server', 'api' },
}

function spigot.versions(all)
  return spigotmc.versions(all)
end

function spigot.latest()
  return spigotmc.latest()
end

function spigot.prepare(version, wanted, context)
  return spigotmc.targets('spigot', 'spigot', version, wanted, context)
end

return spigot
