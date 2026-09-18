--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Mojang's launcher metadata: every version, its jars, mappings and libraries.
local errors = use('core/errors')
local net = use('core/net')

local MANIFEST = 'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json'

local mojang = {}
local manifest
local metadata = {}

function mojang.manifest()
  if not manifest then manifest = net.json(MANIFEST) end
  return manifest
end

-- Version ids, newest first. The manifest is already in that order.
function mojang.versions(all)
  local list = {}
  for _, entry in ipairs(mojang.manifest().versions) do
    if all or entry.type == 'release' then list[#list + 1] = entry.id end
  end
  return list
end

function mojang.latest()
  return mojang.manifest().latest.release
end

-- The metadata of one version: downloads, libraries, the Java it needs.
function mojang.version(id)
  if metadata[id] then return metadata[id] end
  for _, entry in ipairs(mojang.manifest().versions) do
    if entry.id == id then
      metadata[id] = json:decode(fs:read(net.download(entry.url, { name = id .. '.json', sha1 = entry.sha1 })))
      return metadata[id]
    end
  end
  errors.fail("Minecraft has no version '" .. id .. "'. See 'minesrc versions vanilla --all'.")
end

-- The Java feature version a version runs on. Versions older than the field ran on Java 8.
function mojang.javaMajor(id)
  local java = mojang.version(id).javaVersion
  return java and java.majorVersion or 8
end

-- One of the version's own files (client, server, client_mappings, server_mappings), or nil.
function mojang.file(meta, key)
  local file = meta.downloads[key]
  if not file then return nil end
  local extension = file.url:match('%.(%w+)$') or 'jar'
  return net.download(file.url, { name = meta.id .. '-' .. key .. '.' .. extension, sha1 = file.sha1 })
end

-- The client's libraries, natives left out, downloaded side by side.
function mojang.libraries(meta)
  local files = {}
  for _, library in ipairs(meta.libraries) do
    local artifact = library.downloads and library.downloads.artifact
    if artifact and not library.name:find(':natives%-') then
      files[#files + 1] = { url = artifact.url, name = artifact.path:match('[^/]+$'), sha1 = artifact.sha1 }
    end
  end
  return net.downloadAll(files, 'Downloading ' .. #files .. ' libraries')
end

return mojang
