--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- SpigotMC's BuildTools, which builds Spigot and CraftBukkit from source.
-- There is no other way to get either, so it is downloaded and run as is.
local errors = use('core/errors')
local jobs = use('core/jobs')
local net = use('core/net')
local paths = use('core/paths')
local system = use('core/system')
local ui = use('core/ui')

local buildtools = {}

local URL = 'https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar'

-- Where each compile target keeps its Mojang-mapped jar and its API sources in the checkout.
local LAYOUT = {
  spigot = { server = 'Spigot/Spigot-Server/target', api = 'Spigot/Spigot-API/src/main/java' },
  craftbukkit = { server = 'CraftBukkit/target', api = 'Bukkit/src/main/java' },
}

local function usable(path)
  return not path:find('[ !]')
end

-- BuildTools breaks on a path with spaces or '!'. MINESRC_BUILDTOOLS_DIR wins,
-- then the MineSrc home, then the system's temporary folder.
function buildtools.directory()
  local configured = system.env('MINESRC_BUILDTOOLS_DIR')
  if configured then
    local path = fs:absolute(configured)
    if not usable(path) then errors.fail('MINESRC_BUILDTOOLS_DIR (' .. path .. ') must not contain spaces or \'!\'') end
    return path
  end
  for _, candidate in ipairs({ paths.join(paths.home(), 'buildtools'), paths.join(system.tmp(), 'minesrc-buildtools') }) do
    local path = fs:absolute(candidate)
    if usable(path) then return path end
  end
  errors.fail('BuildTools cannot run from a path with spaces or \'!\'. Set MINESRC_BUILDTOOLS_DIR to a folder without them.')
end

-- Copies the Mojang-mapped jar and the API sources out of the shared checkout,
-- so the next build of another version cannot change them.
local function keep(directory, compile, output)
  local layout = LAYOUT[compile]
  for _, path in ipairs(fs:walk(fs:join(directory, layout.server), 1)) do
    if path:match('%-remapped%-mojang%.jar$') then fs:copy(path, fs:join(output, 'remapped-mojang.jar')) end
  end
  local api = fs:join(directory, layout.api)
  if fs:isDirectory(api) then fs:copyTree(api, fs:join(output, 'api')) end
end

-- Builds compile ('spigot' or 'craftbukkit') at rev with jdk, reusing an earlier build of the same pair.
-- options: remapped (also build the Mojang-mapped jar, 1.17 and later), refresh.
-- Returns { jar, remapped, api }, the last two only when BuildTools produced them.
function buildtools.build(rev, compile, jdk, options)
  options = options or {}
  if not LAYOUT[compile] then errors.fail('BuildTools cannot compile \'' .. compile .. '\'') end
  local directory = buildtools.directory()
  local output = paths.join(directory, 'out', compile .. '-' .. rev)
  local jar = fs:join(output, compile .. '-' .. rev .. '.jar')
  if options.refresh then fs:delete(output) end

  if not fs:isFile(jar) then
    -- On Windows BuildTools brings its own portable Git.
    if system.os() ~= 'windows' and not process:available('git') then
      errors.fail('BuildTools needs Git. Install it and make sure \'git\' is on the PATH.')
    end
    fs:delete(output)
    fs:mkdirs(output)
    fs:copy(net.download(URL, { name = 'BuildTools.jar', maxAge = 86400 }), fs:join(directory, 'BuildTools.jar'))

    local log = paths.join(directory, 'logs', compile .. '-' .. rev .. '.log')
    ui.info('Running BuildTools for ' .. compile .. ' ' .. rev .. ' with Java ' .. jdk.major .. ', this takes a few minutes')
    local command = {
      jdk.java, '-Xmx2G', '-jar', 'BuildTools.jar',
      '--rev', rev, '--compile', compile,
      '--output-dir', output, '--final-name', fs:name(jar),
    }
    if options.remapped then command[#command + 1] = '--remapped' end
    local exit = jobs.run({
      command = command,
      dir = directory,
      log = log,
      -- A Maven repository of its own keeps the user's ~/.m2 untouched.
      env = { JAVA_HOME = jdk.home, MAVEN_OPTS = '-Xmx2G -Dmaven.repo.local=' .. fs:join(directory, 'm2') },
    }, 'BuildTools')
    if exit ~= 0 or not fs:isFile(jar) then
      fs:delete(output)
      errors.fail('BuildTools failed for ' .. compile .. ' ' .. rev .. ' (exit ' .. exit .. '):\n' .. jobs.tail(log) .. '\n    Full log: ' .. log)
    end
    keep(directory, compile, output)
  end

  local remapped = fs:join(output, 'remapped-mojang.jar')
  local api = fs:join(output, 'api')
  return {
    jar = jar,
    remapped = fs:isFile(remapped) and remapped or nil,
    api = fs:isDirectory(api) and api or nil,
  }
end

return buildtools
