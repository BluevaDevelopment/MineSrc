--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Single artifacts from a Maven repository, snapshots included.
local errors = use('core/errors')
local net = use('core/net')

local maven = {}

local function tag(block, name)
  return block:match('<' .. name .. '>%s*(.-)%s*</' .. name .. '>')
end

-- The timestamped version a snapshot's metadata points at for a classifier.
local function snapshot(base, classifier)
  local xml = net.textOrNil(base .. '/maven-metadata.xml')
  if not xml then return nil end
  for block in xml:gmatch('<snapshotVersion>(.-)</snapshotVersion>') do
    if tag(block, 'extension') == 'jar' and tag(block, 'classifier') == classifier then
      return tag(block, 'value')
    end
  end
end

-- Downloads group:artifact:version[:classifier] from repository, or returns nil when it has none.
function maven.resolve(repository, coordinate)
  local group, artifact, version, classifier = coordinate:match('^([^:]+):([^:]+):([^:]+):?([^:]*)$')
  if not group then errors.fail('\'' .. coordinate .. '\' is not a Maven coordinate (group:artifact:version[:classifier])') end
  if classifier == '' then classifier = nil end

  local base = repository:gsub('/+$', '') .. '/' .. group:gsub('%.', '/') .. '/' .. artifact .. '/' .. version
  local fileVersion = version
  if version:match('%-SNAPSHOT$') then
    fileVersion = snapshot(base, classifier)
    if not fileVersion then return nil end
  end
  local name = artifact .. '-' .. fileVersion .. (classifier and ('-' .. classifier) or '') .. '.jar'
  return net.download(base .. '/' .. name, { name = name, optional = true })
end

return maven
