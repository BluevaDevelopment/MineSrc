--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Runs real worker JVMs over a real jar from the classpath: the whole path from
-- a jar to .java files, with nested classes written inside their outer class.
local check = use('support/check')
local decompiler = use('decompile/decompiler')
local system = use('core/system')

local suite = {}

local function annotationsJar()
  for entry in system.classpath():gmatch('[^' .. system.property('path.separator') .. ']+') do
    if fs:name(entry):match('^annotations%-.*%.jar$') then return entry end
  end
  error('org.jetbrains:annotations is not on the test classpath')
end

function suite.workersWriteEveryRootClassAsAJavaFile()
  local folder = check.folder()
  local destination = fs:join(folder, 'src')
  local result = decompiler.run(annotationsJar(), {}, {}, destination, fs:join(folder, 'work'), { workers = 2, memory = 256 })

  check.truthy(result.classes > 10, 'only ' .. result.classes .. ' classes')
  check.equals(0, result.failedMethods)
  local source = fs:read(fs:join(destination, 'org/jetbrains/annotations/ApiStatus.java'))
  check.truthy(source:find('public final class ApiStatus', 1, true), 'ApiStatus was not decompiled')
  check.truthy(source:find('Experimental', 1, true), 'the nested annotation belongs in its outer class')
  check.equals(false, fs:exists(fs:join(destination, 'org/jetbrains/annotations/ApiStatus$Experimental.java')))
end

return suite
