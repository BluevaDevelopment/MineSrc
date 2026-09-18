--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

local check = use('support/check')
local platforms = use('core/platforms')

local suite = {}

function suite.everyShippedPlatformLoadsAndDescribesItself()
  local names = {}
  for _, platform in ipairs(platforms.all()) do
    names[#names + 1] = platform.name
    check.truthy(platform.description ~= '', platform.name .. ' has no description')
    local server = false
    for _, side in ipairs(platform.sides) do server = server or side == 'server' end
    check.truthy(server, platform.name .. ' cannot produce a server')
  end
  check.equals({ 'vanilla', 'bukkit', 'spigot', 'paper', 'folia', 'purpur' }, names)
  check.equals({ 'server', 'client' }, platforms.find('vanilla').sides)
end

return suite
