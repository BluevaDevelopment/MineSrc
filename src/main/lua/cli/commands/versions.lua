--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- minesrc versions <platform>: what can be asked for, newest first.
local platforms = use('core/platforms')
local ui = use('core/ui')

return {
  name = 'versions',
  summary = 'List the versions of a platform, newest first',
  arguments = { { name = 'platform', help = 'Platform to list' } },
  options = {
    { long = 'all', short = 'a', flag = true, help = 'Include snapshots and pre-releases' },
    { long = 'limit', short = 'n', value = 'n', default = 0, parse = function(text) return math.tointeger(tonumber(text)) or error(text .. ' is not a number') end,
      help = 'Show only the newest N' },
  },
  run = function(values)
    local list = platforms.find(values.platform).versions(values.all)
    for index, version in ipairs(list) do
      if values.limit > 0 and index > values.limit then break end
      ui.say(version)
    end
  end,
}
