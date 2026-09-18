--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

local check = use('support/check')
local shards = use('decompile/shards')

local suite = {}

function suite.everyClassLandsInExactlyOneShard()
  -- Zero padded, so no name is a prefix of another and every cut is allowed.
  local roots = {}
  for index = 1, 1000 do roots[index] = string.format('net/minecraft/C%04d', index) end
  local parts = shards.split(roots, 4)
  check.equals(4, #parts)
  local joined = {}
  for _, part in ipairs(parts) do
    for _, name in ipairs(part) do joined[#joined + 1] = name end
  end
  check.equals(roots, joined)
end

function suite.aNameNeverLandsApartFromTheNamesItPrefixes()
  -- Fernflower matches by prefix: whoever decompiles a/Foo also decompiles a/FooBar.
  local roots = { 'a/A', 'a/Foo', 'a/FooBar', 'a/FooBarBaz', 'a/Fop', 'a/Z' }
  for index = 1, 20 do roots[#roots + 1] = 'b/B' .. index end
  table.sort(roots)
  for count = 1, 10 do
    local owner = {}
    for number, part in ipairs(shards.split(roots, count)) do
      for _, name in ipairs(part) do owner[name] = number end
    end
    for _, name in ipairs(roots) do
      for _, other in ipairs(roots) do
        if other ~= name and other:sub(1, #name) == name then
          check.equals(owner[name], owner[other], name .. ' and ' .. other .. ' with ' .. count .. ' shards')
        end
      end
    end
  end
end

function suite.neverMoreShardsThanAskedFor()
  local roots = {}
  for index = 1, 50 do roots[index] = 'x/Y' .. index end
  table.sort(roots)
  for count = 1, 60 do check.truthy(#shards.split(roots, count) <= count) end
end

return suite
