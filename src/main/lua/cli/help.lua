--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Help text for the root command and for each command.
local help = {}

local function pad(text, width)
  return text .. string.rep(' ', width - #text)
end

local function table2(rows)
  local width = 0
  for _, row in ipairs(rows) do width = math.max(width, #row[1]) end
  local lines = {}
  for _, row in ipairs(rows) do lines[#lines + 1] = '  ' .. pad(row[1], width) .. '  ' .. row[2] end
  return table.concat(lines, '\n')
end

local function usage(command)
  local text = 'Usage: minesrc ' .. command.name
  if command.options and #command.options > 0 then text = text .. ' [<options>]' end
  for _, argument in ipairs(command.arguments or {}) do
    text = text .. (argument.optional and (' [<' .. argument.name .. '>]') or (' <' .. argument.name .. '>'))
  end
  return text
end

help.usage = usage

function help.command(command)
  local rows = {}
  for _, option in ipairs(command.options or {}) do
    local names = (option.short and ('-' .. option.short .. ', ') or '') .. '--' .. option.long
    if not option.flag then names = names .. '=<' .. (option.value or 'value') .. '>' end
    rows[#rows + 1] = { names, option.help or '' }
  end
  rows[#rows + 1] = { '-h, --help', 'Show this message and exit' }

  local text = usage(command) .. '\n\n  ' .. command.summary .. '\n\nOptions:\n' .. table2(rows)
  local arguments = {}
  for _, argument in ipairs(command.arguments or {}) do
    arguments[#arguments + 1] = { '<' .. argument.name .. '>', argument.help or '' }
  end
  if #arguments > 0 then text = text .. '\n\nArguments:\n' .. table2(arguments) end
  return text
end

function help.root(commands)
  local rows = {}
  for _, command in ipairs(commands) do rows[#rows + 1] = { command.name, command.summary } end
  return 'Usage: minesrc [<options>] <command> [<args>]...\n\n'
    .. '  Get the source code of a Minecraft server or client: downloaded or built, remapped and decompiled.\n\n'
    .. 'Options:\n' .. table2({
      { '-v, --verbose', 'Print every step, download and cache hit' },
      { '-V, --version', 'Show the version and exit' },
      { '-h, --help', 'Show this message and exit' },
    }) .. '\n\nCommands:\n' .. table2(rows)
end

return help
