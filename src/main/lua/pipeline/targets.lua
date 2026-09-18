--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- A target is one folder of the output, as a platform's prepare() describes it:
--
--   name       output folder
--   jar        jar to decompile
--   mappings   ProGuard mappings; the jar is remapped first when present
--   libraries  context for the remapper and Fernflower
--   exclude    class prefixes left out
--   sources    a sources jar or folder, copied as it is instead of decompiling
local errors = use('core/errors')

local targets = {}

local function existing(path, what)
  if type(path) ~= 'string' or not fs:exists(path) then errors.fail(what .. ' that does not exist: ' .. tostring(path)) end
  return path
end

-- Checks what a platform returned, so a mistake in a script names the script and the field.
function targets.validate(list, platform)
  if type(list) ~= 'table' or #list == 0 then errors.fail(platform .. ' produced nothing to decompile') end
  for _, target in ipairs(list) do
    local where = 'A target of \'' .. platform .. '\''
    if type(target.name) ~= 'string' or not target.name:match('^[a-z0-9][a-z0-9._-]*$') then
      errors.fail(where .. ' has no valid name')
    end
    where = where .. ' (' .. target.name .. ')'
    if not target.jar and not target.sources then errors.fail(where .. ' has neither a jar nor sources') end
    if target.jar then existing(target.jar, where .. ' names a jar') end
    if target.sources then existing(target.sources, where .. ' names sources') end
    if target.mappings then existing(target.mappings, where .. ' names mappings') end
    target.libraries = target.libraries or {}
    target.exclude = target.exclude or {}
    for _, library in ipairs(target.libraries) do existing(library, where .. ' names a library') end
  end
  return list
end

return targets
