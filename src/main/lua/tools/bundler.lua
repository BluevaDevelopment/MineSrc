--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Mojang's bundler format, used by the vanilla server since 1.18 and by
-- Spigot's bootstrap jar: the real server under META-INF/versions/, its
-- libraries under META-INF/libraries/. The list files differ between the
-- two, so the folders are read instead.
local errors = use('core/errors')
local paths = use('core/paths')

local bundler = {}

local VERSIONS = 'META-INF/versions/'
local LIBRARIES = 'META-INF/libraries/'

function bundler.isBundle(jar)
  return zip:has(jar, 'META-INF/versions.list')
end

-- The Maven coordinate of a library under a folder laid out as a Maven repository.
function bundler.coordinate(root, library)
  local parts = {}
  for part in fs:relative(root, library):gmatch('[^/]+') do parts[#parts + 1] = part end
  if #parts < 4 then return nil end
  local group = table.concat(parts, '.', 1, #parts - 3)
  return group .. ':' .. parts[#parts - 2] .. ':' .. parts[#parts - 1]
end

-- A server jar and its libraries: { jar, libraries = {...}, artifacts = { { path, coordinate } } }.
function bundler.describe(jar, librariesRoot)
  local libraries, artifacts = {}, {}
  if librariesRoot then
    for _, path in ipairs(fs:walk(librariesRoot, 16)) do
      if path:match('%.jar$') then
        libraries[#libraries + 1] = path
        artifacts[#artifacts + 1] = { path = path, coordinate = bundler.coordinate(librariesRoot, path) }
      end
    end
  end
  return { jar = jar, libraries = libraries, artifacts = artifacts }
end

-- Unpacks a bundle into the work folder. A jar that is not a bundle comes back as it is.
function bundler.unpack(jar)
  if not bundler.isBundle(jar) then return bundler.describe(jar, nil) end

  local target = paths.join(paths.work(), 'bundles', fs:digest(jar, 'sha1'):sub(1, 16))
  local complete = fs:join(target, '.complete')
  if not fs:exists(complete) then
    fs:delete(target)
    local mapping = {}
    for _, name in ipairs(zip:entries(jar)) do
      if name:match('%.jar$') then
        if name:sub(1, #VERSIONS) == VERSIONS then
          mapping[name] = 'versions/' .. name:sub(#VERSIONS + 1)
        elseif name:sub(1, #LIBRARIES) == LIBRARIES then
          mapping[name] = 'libraries/' .. name:sub(#LIBRARIES + 1)
        end
      end
    end
    zip:extract(jar, target, mapping)
    fs:write(complete, jar)
  end

  -- Mojang's bundle holds one server; if there were more, the biggest is the server.
  local server, size = nil, -1
  for _, path in ipairs(fs:walk(fs:join(target, 'versions'), 8)) do
    if path:match('%.jar$') and fs:size(path) > size then server, size = path, fs:size(path) end
  end
  if not server then errors.fail(jar .. ' is a bundle with no server jar inside META-INF/versions') end
  return bundler.describe(server, fs:join(target, 'libraries'))
end

return bundler
