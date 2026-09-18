--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Asks the real services, so it only runs with -Pnetwork: an API that
-- changes shape shows up here first.
local check = use('support/check')
local platforms = use('core/platforms')

local suite = {}

function suite.everyPlatformListsItsVersionsAndPicksALatestAmongThem()
  for _, platform in ipairs(platforms.all()) do
    check.truthy(#platform.versions(false) > 0, platform.name .. ' lists no versions')
    local latest = platform.latest()
    local listed = false
    for _, version in ipairs(platform.versions(true)) do listed = listed or version == latest end
    check.truthy(listed, platform.name .. ' picked ' .. latest .. ', which it does not list')
  end
end

return suite
