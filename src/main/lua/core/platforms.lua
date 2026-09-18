--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- The platforms shipped in this jar: every script compiled from src/main/lua/platforms/.
local errors = use('core/errors')

local platforms = {}

-- How they are listed: vanilla first, then the forks in the order they descend.
local ORDER = { vanilla = 1, bukkit = 2, spigot = 3, paper = 4, folia = 5, purpur = 6 }

local loaded

function platforms.all()
  if loaded then return loaded end
  loaded = {}
  for _, id in ipairs(host:scripts('platforms/')) do
    local platform = use(id)
    for _, field in ipairs({ 'name', 'description', 'sides', 'versions', 'latest', 'prepare' }) do
      if platform[field] == nil then errors.fail('The platform script ' .. id .. ' has no ' .. field) end
    end
    loaded[#loaded + 1] = platform
  end
  table.sort(loaded, function(a, b)
    local left, right = ORDER[a.name] or 100, ORDER[b.name] or 100
    if left ~= right then return left < right end
    return a.name < b.name
  end)
  return loaded
end

function platforms.find(name)
  local names = {}
  for _, platform in ipairs(platforms.all()) do
    if platform.name == name then return platform end
    names[#names + 1] = platform.name
  end
  errors.usage("Unknown platform '" .. name .. "'. Available: " .. table.concat(names, ', '))
end

return platforms
