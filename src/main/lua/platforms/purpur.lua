--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Purpur: a Paper fork with its own download API.
local errors = use('core/errors')
local mojang = use('lib/mojang')
local net = use('core/net')
local papermc = use('lib/papermc')
local ui = use('core/ui')
local versions = use('lib/versions')

local API = 'https://api.purpurmc.org/v2/purpur'

local purpur = {
  name = 'purpur',
  description = 'Purpur server and the Purpur API',
  sides = { 'server', 'api' },
}

function purpur.versions(all)
  return versions.filter(versions.newestFirst(net.json(API).versions), all)
end

function purpur.latest()
  return purpur.versions(false)[1]
end

function purpur.prepare(version, wanted, context)
  local build = net.jsonOrNil(API .. '/' .. version .. '/latest')
    or errors.fail("Purpur has no version '" .. version .. "'. See 'minesrc versions purpur'.")
  ui.info('purpur ' .. version .. ', build ' .. build.build)
  local jar = net.download(API .. '/' .. version .. '/' .. build.build .. '/download', {
    name = 'purpur-' .. version .. '-' .. build.build .. '.jar',
    md5 = build.md5,
  })
  return papermc.targets(jar, mojang.javaMajor(version), wanted, {
    api = 'org.purpurmc.purpur:purpur-api:',
    repository = 'https://repo.purpurmc.org/snapshots/',
  }, context)
end

return purpur
