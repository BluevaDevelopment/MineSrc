--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Failures meant for the user, told apart from bugs.
local errors = {}

local Failure = {}
Failure.__index = Failure
Failure.__tostring = function(failure) return failure.message end

-- Stops the run with a message the user can act on.
function errors.fail(message)
  error(setmetatable({ message = message }, Failure), 0)
end

-- Stops the run because of how the command line was written.
function errors.usage(message)
  error(setmetatable({ message = message, usage = true }, Failure), 0)
end

function errors.isFailure(value)
  return getmetatable(value) == Failure
end

-- The text of any error: a failure's message, or a JVM exception without the
-- class names Luak puts in front of it when it crosses into Lua.
function errors.message(value)
  if errors.isFailure(value) then return value.message end
  -- Where in the scripts it surfaced says nothing to the user.
  local text = tostring(value):gsub('^[%w_/]+%.lua:%d+: (vm error: )', '%1')
  local previous
  repeat
    previous = text
    text = text:gsub('^vm error: ', ''):gsub('^[%w_%.%$]+Exception: ', ''):gsub('^[%w_%.%$]+Error: ', '')
  until text == previous
  return text
end

-- Runs fn and turns any error into a failure with context in front, such as the tool that failed.
function errors.context(prefix, fn, ...)
  local results = table.pack(pcall(fn, ...))
  if not results[1] then errors.fail(prefix .. ': ' .. errors.message(results[2])) end
  return table.unpack(results, 2, results.n)
end

return errors
