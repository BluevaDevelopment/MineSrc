--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- minesrc platforms: what can be decompiled.
local platforms = use('core/platforms')
local ui = use('core/ui')

return {
  name = 'platforms',
  summary = 'List the supported platforms',
  run = function()
    local width = 0
    for _, platform in ipairs(platforms.all()) do width = math.max(width, #platform.name) end
    for _, platform in ipairs(platforms.all()) do
      ui.say(platform.name .. string.rep(' ', width - #platform.name) .. '  ' .. platform.description
        .. ' [' .. table.concat(platform.sides, ', ') .. ']')
    end
  end,
}
