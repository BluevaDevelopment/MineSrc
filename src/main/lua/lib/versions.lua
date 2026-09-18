--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Ordering and filtering of version names such as 1.21.8, 26.2 or 26.3-rc-1.
local versions = {}

-- The numbers a version starts with, and whatever follows them.
local function parse(version)
  local numbers = {}
  local prefix = version:match('^[%d%.]*')
  for part in prefix:gmatch('%d+') do
    numbers[#numbers + 1] = tonumber(part)
  end
  return numbers, version:sub(#prefix + 1)
end

-- Negative when a is older than b, positive when newer, zero when equal.
-- A release is newer than its own pre-releases: 1.21 > 1.21-rc-1.
function versions.compare(a, b)
  local left, leftRest = parse(a)
  local right, rightRest = parse(b)
  for index = 1, math.max(#left, #right) do
    local difference = (left[index] or 0) - (right[index] or 0)
    if difference ~= 0 then return difference end
  end
  if leftRest == rightRest then return 0 end
  if leftRest == '' then return 1 end
  if rightRest == '' then return -1 end
  return leftRest < rightRest and -1 or 1
end

-- Sorts a list in place, newest first, and returns it.
function versions.newestFirst(list)
  table.sort(list, function(a, b) return versions.compare(a, b) > 0 end)
  return list
end

-- A plain release: numbers and dots only.
function versions.isRelease(version)
  return version:match('^%d+%.%d+[%.%d]*$') ~= nil
end

-- The releases of a list, or all of it when all is set.
function versions.filter(list, all)
  if all then return list end
  local releases = {}
  for _, version in ipairs(list) do
    if versions.isRelease(version) then releases[#releases + 1] = version end
  end
  return releases
end

function versions.contains(list, wanted)
  for _, version in ipairs(list) do
    if version == wanted then return true end
  end
  return false
end

return versions
