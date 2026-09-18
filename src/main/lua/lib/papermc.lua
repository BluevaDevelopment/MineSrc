--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- What Paper and its forks have in common: a Paperclip jar to patch, and an
-- API published with its sources.
local jdks = use('core/jdks')
local maven = use('tools/maven')
local paperclip = use('tools/paperclip')
local shaded = use('lib/shaded')
local sides = use('lib/sides')
local ui = use('core/ui')

local papermc = {}

-- The API library of a patched server, from its real sources when the repository has them.
local function api(patched, project)
  for _, artifact in ipairs(patched.artifacts) do
    local coordinate = artifact.coordinate
    if coordinate and coordinate:sub(1, #project.api) == project.api then
      local sources = maven.resolve(project.repository, coordinate .. ':sources')
      if sources then return { name = 'api', sources = sources } end
      ui.warn('No published sources for ' .. coordinate .. ', decompiling it instead')
      return { name = 'api', jar = artifact.path, libraries = patched.libraries }
    end
  end
  ui.warn('This server carries its API inside the server jar, so there is no separate api folder')
end

-- project = { api = 'group:artifact:', repository = 'https://...' }; java is the oldest Java it runs on.
function papermc.targets(jar, java, wanted, project, context)
  local patched = paperclip.patch(jar, jdks.find(java), context.refresh)
  local list = {}
  if sides.wants(wanted, 'server') then
    -- Before 1.18 Paperclip left no libraries: they were inside the jar.
    local exclude = #patched.libraries == 0 and shaded or {}
    list[#list + 1] = { name = 'server', jar = patched.jar, libraries = patched.libraries, exclude = exclude }
  end
  if sides.wants(wanted, 'api') then
    list[#list + 1] = api(patched, project)
  end
  return list
end

return papermc
