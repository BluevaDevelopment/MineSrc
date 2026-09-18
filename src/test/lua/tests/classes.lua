--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

local check = use('support/check')
local classes = use('decompile/classes')

local suite = {}

function suite.nestedClassesAreWrittenWithTheirOuterClass()
  local jar = fs:join(check.folder(), 'server.jar')
  zip:write(jar, {
    ['a/Outer.class'] = '', ['a/Outer$Inner.class'] = '', ['a/Outer$1.class'] = '',
    ['a/Orphan$Nested.class'] = '', ['b/Plain.class'] = '',
    ['META-INF/versions/9/module-info.class'] = '', ['data/pack.mcmeta'] = '',
  })
  -- The orphan's outer class is not in the jar, so it is written on its own.
  check.equals({ 'a/Orphan$Nested', 'a/Outer', 'b/Plain' }, classes.roots(jar, {}, {}))
end

function suite.excludedPrefixesAndLibraryClassesAreLeftOut()
  local folder = check.folder()
  local jar = fs:join(folder, 'old-server.jar')
  zip:write(jar, {
    ['net/minecraft/Server.class'] = '', ['com/google/common/Lists.class'] = '',
    ['io/netty/Channel.class'] = '', ['joptsimple/Parser.class'] = '',
  })
  local guava = fs:join(folder, 'guava.jar')
  zip:write(guava, { ['com/google/common/Lists.class'] = '' })
  check.equals({ 'net/minecraft/Server' }, classes.roots(jar, { 'io/netty/', 'joptsimple/' }, { guava }))
end

return suite
