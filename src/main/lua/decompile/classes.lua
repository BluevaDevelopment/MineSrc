--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Which classes of a jar become source files.
local classes = {}

-- The class names of a jar, as internal names (net/minecraft/Foo).
function classes.of(jar)
  local names = {}
  for _, entry in ipairs(zip:entries(jar)) do
    if entry:match('%.class$') and entry:sub(1, 9) ~= 'META-INF/' then
      names[#names + 1] = entry:sub(1, -7)
    end
  end
  return names
end

local function excluded(name, exclude)
  for _, prefix in ipairs(exclude) do
    if name:sub(1, #prefix) == prefix then return true end
  end
  return false
end

-- The top level classes of jar, sorted. Nested classes are written inside
-- their outer class, so a name with a $ only counts when its outer class is
-- missing. Classes under an exclude prefix, or that a library also provides
-- (a dependency shaded into an old server jar), are left out.
function classes.roots(jar, exclude, libraries)
  local provided = {}
  for _, library in ipairs(libraries or {}) do
    if library ~= jar then
      for _, name in ipairs(classes.of(library)) do provided[name] = true end
    end
  end

  local kept = {}
  for _, name in ipairs(classes.of(jar)) do
    if not provided[name] and not excluded(name, exclude or {}) then kept[name] = true end
  end

  local roots = {}
  for name in pairs(kept) do
    local package, simple = name:match('^(.-)([^/]*)$')
    local dollar = simple:find('%$')
    if not dollar or dollar == 1 or not kept[package .. simple:sub(1, dollar - 1)] then
      roots[#roots + 1] = name
    end
  end
  table.sort(roots)
  return roots
end

return classes
