--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- The game as Mojang ships it: the client and the dedicated server.
local bundler = use('tools/bundler')
local errors = use('core/errors')
local mojang = use('lib/mojang')
local sides = use('lib/sides')
local ui = use('core/ui')

local vanilla = {
  name = 'vanilla',
  description = "Mojang's own client and server",
  sides = { 'server', 'client' },
}

function vanilla.versions(all)
  return mojang.versions(all)
end

function vanilla.latest()
  return mojang.latest()
end

function vanilla.prepare(version, wanted)
  local meta = mojang.version(version)
  local clientLibraries
  local function libraries()
    clientLibraries = clientLibraries or mojang.libraries(meta)
    return clientLibraries
  end

  local list = {}
  for _, side in ipairs({ 'server', 'client' }) do
    if sides.wants(wanted, side) then
      local jar = mojang.file(meta, side) or errors.fail('Minecraft ' .. version .. ' has no ' .. side .. ' jar to download')
      local context
      if side == 'server' then
        -- Since 1.18 the server is a bundle with its libraries inside. Older
        -- servers carry them as classes, which the client's libraries filter out.
        local server = bundler.unpack(jar)
        jar = server.jar
        context = #server.libraries > 0 and server.libraries or libraries()
      else
        context = libraries()
      end

      -- Official mappings exist from 1.14.4 to 1.21.x: older jars stay obfuscated,
      -- and from 26.1 on the jars are not obfuscated at all.
      local mappings = mojang.file(meta, side .. '_mappings')
      if not mappings then
        ui.detail('Minecraft ' .. version .. ' ships no ' .. side .. ' mappings, its names are kept as they are')
      end
      list[#list + 1] = { name = side, jar = jar, mappings = mappings, libraries = context }
    end
  end
  return list
end

return vanilla
