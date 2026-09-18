--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- minesrc cache [clean]: where MineSrc keeps things, how much room they take, and removing them.
local buildtools = use('tools/buildtools')
local paths = use('core/paths')
local ui = use('core/ui')

local function areas(everything)
  local list = { { 'downloads', paths.downloads() }, { 'work', paths.work() } }
  if everything then
    list[#list + 1] = { 'jdks', paths.jdks() }
    local ok, directory = pcall(buildtools.directory)
    list[#list + 1] = { 'buildtools', ok and directory or paths.join(paths.home(), 'buildtools') }
  end
  return list
end

local function size(path)
  if not fs:exists(path) then return 'empty' end
  local bytes = 0
  for _, file in ipairs(fs:walk(path, 64)) do bytes = bytes + fs:size(file) end
  return string.format('%.1f MB', bytes / 1048576)
end

return {
  name = 'cache',
  summary = 'Show the cache folders and their size, or clean them',
  arguments = { { name = 'action', optional = true, help = "'clean' to delete downloads and intermediate jars" } },
  options = {
    { long = 'all', flag = true, help = 'With clean, also remove downloaded JDKs and the BuildTools checkout' },
  },
  run = function(values)
    if values.action == 'clean' then
      for _, area in ipairs(areas(values.all)) do
        fs:delete(area[2])
        ui.say('Removed ' .. area[1] .. ' (' .. area[2] .. ')')
      end
    elseif values.action then
      use('core/errors').usage("unknown cache action '" .. values.action .. "', only 'clean' exists")
    else
      for _, area in ipairs(areas(true)) do
        local shown = size(area[2])
        ui.say(area[1] .. string.rep(' ', 12 - #area[1]) .. string.rep(' ', 10 - #shown) .. shown .. '  ' .. area[2])
      end
    end
  end,
}
