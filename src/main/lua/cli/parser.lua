--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Reads a command line against a command's declaration:
--
--   arguments = { { name = 'version', help = '...', optional = true } }
--   options = { { long = 'output', short = 'o', value = 'dir', help = '...',
--                 flag = true, multiple = true, choices = {...}, default = ..., parse = fn } }
--
-- Values come back keyed by the option's long name and the argument's name.
local errors = use('core/errors')

local parser = {}

local function find(options, long, short)
  for _, option in ipairs(options) do
    if (long and option.long == long) or (short and option.short == short) then return option end
  end
end

local function accept(values, option, raw)
  local shown = '--' .. option.long
  local value = raw
  if option.choices then
    local allowed = false
    for _, choice in ipairs(option.choices) do allowed = allowed or choice == raw end
    if not allowed then
      errors.usage('invalid value for ' .. shown .. ': ' .. raw .. ' (choose from ' .. table.concat(option.choices, ', ') .. ')')
    end
  end
  if option.parse then
    local ok, parsed = pcall(option.parse, raw)
    if not ok then errors.usage('invalid value for ' .. shown .. ': ' .. errors.message(parsed)) end
    value = parsed
  end
  if option.multiple then
    values[option.long] = values[option.long] or {}
    table.insert(values[option.long], value)
  else
    values[option.long] = value
  end
end

-- Returns the values, or { help = true } when -h or --help was given.
function parser.parse(command, args)
  for _, arg in ipairs(args) do
    if arg == '--' then break end
    if arg == '-h' or arg == '--help' then return { help = true } end
  end
  local options = command.options or {}
  local values, positional = {}, {}
  local index, literal = 1, false
  while index <= #args do
    local arg = args[index]
    if literal or arg == '-' or arg:sub(1, 1) ~= '-' then
      positional[#positional + 1] = arg
    elseif arg == '--' then
      literal = true
    else
      local long, inline = arg:match('^%-%-([^=]+)=?(.*)$')
      local short = not long and arg:match('^%-(.)$')
      local option = find(options, long, short)
      if not option then errors.usage('no such option: ' .. arg) end
      if option.flag then
        if long and arg:find('=') then errors.usage('--' .. option.long .. ' does not take a value') end
        values[option.long] = true
      else
        local raw = (long and arg:find('=')) and inline or nil
        if not raw then
          index = index + 1
          raw = args[index]
          if raw == nil then errors.usage(arg .. ' needs a value') end
        end
        accept(values, option, raw)
      end
    end
    index = index + 1
  end

  local arguments = command.arguments or {}
  for position, argument in ipairs(arguments) do
    local value = positional[position]
    if value == nil and not argument.optional then errors.usage('missing argument <' .. argument.name .. '>') end
    values[argument.name] = value
  end
  if #positional > #arguments then errors.usage('unexpected argument: ' .. positional[#arguments + 1]) end

  for _, option in ipairs(options) do
    if values[option.long] == nil then
      if option.flag then values[option.long] = false
      elseif option.multiple then values[option.long] = {}
      else values[option.long] = option.default end
    end
  end
  return values
end

return parser
