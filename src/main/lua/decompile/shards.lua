--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Splits root classes between decompiler workers.
--
-- Fernflower selects the classes to decompile by prefix, so a worker told to
-- decompile a/Foo also decompiles a/FooBar. Sorted, every name that starts
-- with another follows it directly, so a shard is only ever cut where the
-- next name does not start with one already open in the shard.
local shards = {}

local function startsWith(text, prefix)
  return text:sub(1, #prefix) == prefix
end

-- roots must be sorted. Returns at most count lists that together hold every root once.
function shards.split(roots, count)
  if count <= 1 or #roots <= 1 then return { roots } end

  local size = math.ceil(#roots / count)
  local result, current, open = {}, {}, {}
  for _, name in ipairs(roots) do
    while #open > 0 and not startsWith(name, open[#open]) do open[#open] = nil end
    if #current >= size and #open == 0 and #result < count - 1 then
      result[#result + 1] = current
      current = {}
    end
    current[#current + 1] = name
    open[#open + 1] = name
  end
  if #current > 0 then result[#result + 1] = current end
  return result
end

return shards
