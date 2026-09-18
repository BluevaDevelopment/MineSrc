--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

local bundler = use('tools/bundler')
local check = use('support/check')

local suite = {}

function suite.aMojangBundleGivesItsServerAndLibraries()
  local jar = fs:join(check.folder(), 'server.jar')
  zip:write(jar, {
    ['META-INF/versions.list'] = 'abc\t1.21.8\t1.21.8/server-1.21.8.jar\n',
    ['META-INF/versions/1.21.8/server-1.21.8.jar'] = string.rep('x', 64),
    ['META-INF/libraries/com/google/guava/guava/33.0/guava-33.0.jar'] = 'x',
    ['net/minecraft/bundler/Main.class'] = '',
  })
  local server = bundler.unpack(jar)
  check.equals('server-1.21.8.jar', fs:name(server.jar))
  check.equals(1, #server.libraries)
  check.equals('com.google.guava:guava:33.0', server.artifacts[1].coordinate)
end

function suite.aSpigotBootstrapJarWithAFlatLibraryFolderUnpacksTheSameWay()
  local jar = fs:join(check.folder(), 'spigot.jar')
  zip:write(jar, {
    ['META-INF/versions.list'] = 'abc *spigot-1.21.8-R0.1-SNAPSHOT.jar\n',
    ['META-INF/versions/spigot-1.21.8-R0.1-SNAPSHOT.jar'] = string.rep('x', 64),
    ['META-INF/libraries/asm-9.8.jar'] = 'x',
  })
  local server = bundler.unpack(jar)
  check.equals('spigot-1.21.8-R0.1-SNAPSHOT.jar', fs:name(server.jar))
  check.equals(1, #server.libraries)
  check.equals(nil, server.artifacts[1].coordinate, 'a flat folder has no Maven layout to read')
end

function suite.aPlainJarComesBackAsItIs()
  local jar = fs:join(check.folder(), 'plain.jar')
  zip:write(jar, { ['a/B.class'] = '' })
  local server = bundler.unpack(jar)
  check.equals(jar, server.jar)
  check.equals(0, #server.libraries)
end

return suite
