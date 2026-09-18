--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Assertions for the Lua suites. A failed one raises an error, which fails the test.
local errors = use('core/errors')

local check = {}

local function show(value)
  if type(value) ~= 'table' then return type(value) == 'string' and ("'" .. value .. "'") or tostring(value) end
  local parts = {}
  for index, item in ipairs(value) do parts[index] = show(item) end
  return '{ ' .. table.concat(parts, ', ') .. ' }'
end

local function same(expected, actual)
  if type(expected) ~= 'table' or type(actual) ~= 'table' then return expected == actual end
  for key, value in pairs(expected) do
    if not same(value, actual[key]) then return false end
  end
  for key in pairs(actual) do
    if expected[key] == nil then return false end
  end
  return true
end

function check.equals(expected, actual, message)
  if not same(expected, actual) then
    error((message and (message .. ': ') or '') .. 'expected ' .. show(expected) .. ', got ' .. show(actual), 2)
  end
end

function check.truthy(value, message)
  if not value then error(message or 'expected a true value', 2) end
end

-- fn must fail, with a message containing text.
function check.fails(text, fn, ...)
  local ok, failure = pcall(fn, ...)
  if ok then error('expected a failure mentioning ' .. show(text), 2) end
  local message = errors.message(failure)
  if not message:find(text, 1, true) then error('expected a failure mentioning ' .. show(text) .. ', got ' .. show(message), 2) end
end

-- A fresh folder for one test.
function check.folder()
  return fs:temporary('minesrc-test')
end

return check
