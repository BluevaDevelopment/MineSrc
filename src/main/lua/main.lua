--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- The entry point: reads the command line, runs a command, and turns any
-- failure into a message and an exit code. Returns the function the host calls.
local errors = use('core/errors')
local help = use('cli/help')
local parser = use('cli/parser')
local platforms = use('core/platforms')
local ui = use('core/ui')

local OK, FAILED, USAGE = 0, 1, 2

local function commands()
  local list = {}
  local platformCommand = use('cli/commands/platform')
  for _, platform in ipairs(platforms.all()) do list[#list + 1] = platformCommand(platform) end
  for _, id in ipairs({ 'cli/commands/platforms', 'cli/commands/versions', 'cli/commands/cache' }) do
    list[#list + 1] = use(id)
  end
  return list
end

local function run(args)
  local rest = {}
  for _, arg in ipairs(args) do rest[#rest + 1] = arg end

  -- Options before the command belong to minesrc itself; --verbose is also accepted after it.
  while rest[1] and rest[1]:sub(1, 1) == '-' do
    local option = table.remove(rest, 1)
    if option == '-V' or option == '--version' then
      ui.say('minesrc version ' .. host:version())
      return OK
    elseif option == '-h' or option == '--help' then
      ui.say(help.root(commands()))
      return OK
    elseif option == '-v' or option == '--verbose' then
      ui.verbose = true
    else
      errors.usage('no such option: ' .. option)
    end
  end
  for index = #rest, 1, -1 do
    if rest[index] == '-v' or rest[index] == '--verbose' then
      ui.verbose = true
      table.remove(rest, index)
    end
  end

  local name = table.remove(rest, 1)
  if not name then
    ui.say(help.root(commands()))
    return USAGE
  end
  for _, command in ipairs(commands()) do
    if command.name == name then
      local ok, values = pcall(parser.parse, command, rest)
      if not ok then
        if errors.isFailure(values) and values.usage then
          ui.say(help.usage(command) .. '\n')
          ui.error(values.message)
          return USAGE
        end
        error(values, 0)
      end
      if values.help then
        ui.say(help.command(command))
        return OK
      end
      command.run(values)
      return OK
    end
  end
  errors.usage("no such command '" .. name .. "'. See 'minesrc --help'.")
end

return function(args)
  local ok, result = pcall(run, args)
  if ok then return result end
  ui.error(errors.message(result))
  return (errors.isFailure(result) and result.usage) and USAGE or FAILED
end
