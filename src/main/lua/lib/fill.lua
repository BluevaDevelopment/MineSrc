--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- PaperMC's Fill API, which serves Paper, Folia and the rest of their projects.
local errors = use('core/errors')
local net = use('core/net')
local ui = use('core/ui')
local versions = use('lib/versions')

local API = 'https://fill.papermc.io/v3/projects/'

local fill = {}

-- Every version of a project, newest first.
function fill.versions(project, all)
  local list = {}
  -- Grouped by major version in a JSON object, whose order does not survive; sorted again below.
  for _, group in pairs(net.json(API .. project).versions) do
    for _, version in ipairs(group) do list[#list + 1] = version end
  end
  return versions.filter(versions.newestFirst(list), all)
end

-- The builds of a version, newest first, or nil when the version does not exist.
function fill.builds(project, version)
  return net.jsonOrNil(API .. project .. '/versions/' .. version .. '/builds')
end

local function stable(builds)
  for _, build in ipairs(builds or {}) do
    if build.channel == 'STABLE' then return build end
  end
end

-- The newest version that has a stable build, as PaperMC recommends.
function fill.latest(project)
  local list = fill.versions(project, false)
  for _, version in ipairs(list) do
    if stable(fill.builds(project, version)) then return version end
  end
  return list[1]
end

-- The newest stable build of a version, or its newest build of any kind.
function fill.build(project, version)
  local builds = fill.builds(project, version)
  if not builds or #builds == 0 then
    errors.fail(project .. " has no version '" .. version .. "'. See 'minesrc versions " .. project .. " --all'.")
  end
  local build = stable(builds)
  if build then return build end
  build = builds[1]
  ui.warn(project .. ' ' .. version .. ' has no stable build yet, using ' .. build.channel:lower() .. ' build ' .. build.id)
  return build
end

-- Downloads the server jar of the chosen build, verified against its sha256.
function fill.download(project, version)
  local build = fill.build(project, version)
  local file = build.downloads['server:default']
  ui.info(project .. ' ' .. version .. ', build ' .. build.id)
  return net.download(file.url, { name = file.name, sha256 = file.checksums.sha256 })
end

-- The oldest Java the version runs on.
function fill.java(project, version)
  local info = net.json(API .. project .. '/versions/' .. version)
  local java = info.version and info.version.java
  return java and java.version and java.version.minimum or 8
end

return fill
