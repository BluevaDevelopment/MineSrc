--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- The machine MineSrc runs on, read straight from the JVM through Mawu's java global.
local System = java.lang.System
local Runtime = java.lang.Runtime

local system = {}

function system.property(name)
  return System:getProperty(name)
end

-- An environment variable, or nil when it is unset or blank.
function system.env(name)
  local value = System:getenv(name)
  if value == nil or value == '' then return nil end
  return value
end

-- 'mac', 'windows' or 'linux'.
function system.os()
  local name = system.property('os.name'):lower()
  if name:find('mac') then return 'mac' end
  if name:find('win') then return 'windows' end
  return 'linux'
end

-- 'aarch64', 'x64', or whatever the JVM reports.
function system.arch()
  local arch = system.property('os.arch'):lower()
  if arch == 'arm64' then return 'aarch64' end
  if arch == 'amd64' or arch == 'x86_64' then return 'x64' end
  return arch
end

function system.cpus()
  return Runtime:getRuntime():availableProcessors()
end

-- Milliseconds, for timing and for throttling what is drawn. A Java long
-- arrives as a float, so it is turned back into an integer.
function system.now()
  return math.floor(System:currentTimeMillis())
end

-- The JVM running MineSrc, which also runs the decompiler workers.
function system.java()
  local home = system.property('java.home')
  return {
    home = home,
    major = Runtime:version():feature(),
    java = fs:join(fs:join(home, 'bin'), system.os() == 'windows' and 'java.exe' or 'java'),
  }
end

-- The classpath with every entry made absolute: `java -jar minesrc.jar` reports
-- a relative path, and the decompiler workers start in another folder.
function system.classpath()
  local separator = system.property('path.separator')
  local entries = {}
  for entry in system.property('java.class.path'):gmatch('[^' .. separator .. ']+') do
    entries[#entries + 1] = fs:absolute(entry)
  end
  return table.concat(entries, separator)
end

function system.home()
  return system.property('user.home')
end

function system.cwd()
  return system.property('user.dir')
end

function system.tmp()
  return system.property('java.io.tmpdir')
end

return system
