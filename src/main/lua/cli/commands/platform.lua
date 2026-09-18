--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- minesrc <platform> [version]: the command that does the work, one per platform.
local decompiler = use('decompile/decompiler')
local errors = use('core/errors')
local pipeline = use('pipeline/pipeline')

-- 2g, 1536m or 2048 are all megabytes in the end.
local function megabytes(text)
  local amount, unit = text:lower():match('^%s*(%d+)%s*([gm]?)b?%s*$')
  if not amount then errors.fail("'" .. text .. "' is not a size such as 2g or 1536m") end
  local value = tonumber(amount) * (unit == 'g' and 1024 or 1)
  if value < 256 then errors.fail(text .. ' is too little memory for Fernflower, give it at least 256m') end
  return value
end

local function workers(text)
  local value = tonumber(text)
  if not value or value % 1 ~= 0 or value < 1 or value > 64 then errors.fail(text .. ' is not a number from 1 to 64') end
  return math.tointeger(value)
end

return function(platform)
  local defaults = decompiler.defaults()
  return {
    name = platform.name,
    summary = platform.description,
    arguments = { { name = 'version', optional = true, help = 'Version to get, the latest when left out' } },
    options = {
      { long = 'output', short = 'o', value = 'dir', help = 'Folder to write into (default: ./' .. platform.name .. '-<version>)' },
      { long = 'side', short = 's', value = 'name', multiple = true, choices = platform.sides,
        help = 'Only this part (repeatable): ' .. table.concat(platform.sides, ', ') },
      { long = 'workers', short = 'w', value = 'n', default = defaults.workers, parse = workers,
        help = 'Decompiler processes run at once (default: ' .. defaults.workers .. ')' },
      { long = 'memory', short = 'm', value = 'size', default = defaults.memory, parse = megabytes,
        help = 'Heap for each decompiler process, like 2g or 1536m (default: 2g)' },
      { long = 'force', short = 'f', flag = true, help = 'Replace the output folder if MineSrc wrote it before' },
      { long = 'no-remap', flag = true, help = "Keep obfuscated names instead of applying Mojang's mappings" },
      { long = 'refresh', flag = true, help = 'Build or patch again instead of reusing a previous result' },
    },
    run = function(values)
      -- A platform script reads the options it cares about, such as refresh, from here.
      local context = { refresh = values.refresh }
      pipeline.run({
        name = platform.name,
        sides = platform.sides,
        latest = platform.latest,
        prepare = function(version, sides) return platform.prepare(version, sides, context) end,
      }, {
        version = values.version,
        sides = values.side,
        output = values.output,
        force = values.force,
        remap = not values['no-remap'],
        settings = { workers = values.workers, memory = values.memory },
      })
    end,
  }
end
