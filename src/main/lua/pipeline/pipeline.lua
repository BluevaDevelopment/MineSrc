--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- From a platform and a version to a folder of sources: prepare, remap, decompile, copy.
local decompiler = use('decompile/decompiler')
local output = use('pipeline/output')
local paths = use('core/paths')
local system = use('core/system')
local targets = use('pipeline/targets')
local ui = use('core/ui')

local pipeline = {}

local JAVA = 'src/main/java'
local RESOURCES = 'src/main/resources'

-- Where a non-class entry of a jar goes, or nil for classes and signatures.
local SIGNATURES = { '.SF', '.RSA', '.DSA', '.EC' }

local function resourcePath(name)
  if name:match('%.class$') or name == 'META-INF/MANIFEST.MF' then return nil end
  if name:match('^META-INF/[^/]+$') then
    for _, suffix in ipairs(SIGNATURES) do
      if name:sub(-#suffix) == suffix then return nil end
    end
  end
  return name
end

local function copyResources(jar, directory)
  local mapping, count = {}, 0
  for _, name in ipairs(zip:entries(jar)) do
    local path = resourcePath(name)
    if path then
      mapping[name] = path
      count = count + 1
    end
  end
  zip:extract(jar, fs:join(directory, RESOURCES), mapping)
  return count
end

-- Mojang's mappings, applied once per jar and mappings pair.
local function remapped(target)
  local key = fs:digest(target.jar, 'sha1'):sub(1, 16) .. '-' .. fs:digest(target.mappings, 'sha1'):sub(1, 16)
  local result = paths.join(paths.work(), 'remapped', key, fs:name(target.jar))
  if fs:isFile(result) then
    ui.detail('Reusing remapped ' .. fs:name(target.jar))
  else
    ui.info('Remapping ' .. fs:name(target.jar) .. ' to Mojang\'s names')
    remap:proguard(target.jar, target.mappings, target.libraries, result)
  end
  return result
end

local function decompile(target, directory, request)
  local jar = (target.mappings and request.remap) and remapped(target) or target.jar
  local work = paths.join(paths.work(), 'decompile', system.now() .. '-' .. target.name)
  fs:delete(work)
  local result = decompiler.run(jar, target.libraries, target.exclude, fs:join(directory, JAVA), work, request.settings)
  local resources = copyResources(jar, directory)
  ui.info(result.classes .. ' classes and ' .. resources .. ' resources written to ' .. directory)
  if result.failedMethods > 0 then
    ui.warn(result.failedMethods .. ' methods could not be decompiled and are left as comments, see ' .. result.logs)
  else
    fs:delete(work)
  end
end

-- A sources jar or folder: .java files under src/main/java, anything else under resources.
local function copySources(sources, directory)
  local java = fs:join(directory, JAVA)
  local count = 0
  if fs:isDirectory(sources) then
    for _, file in ipairs(fs:walk(sources, 64)) do
      local relative = fs:relative(sources, file)
      local isJava = relative:match('%.java$') ~= nil
      if isJava then count = count + 1 end
      fs:copy(file, fs:join(isJava and java or fs:join(directory, RESOURCES), relative))
    end
  else
    local code, other = {}, {}
    for _, name in ipairs(zip:entries(sources)) do
      if name:match('%.java$') then
        code[name] = name
        count = count + 1
      elseif resourcePath(name) then
        other[name] = name
      end
    end
    zip:extract(sources, java, code)
    zip:extract(sources, fs:join(directory, RESOURCES), other)
  end
  ui.info(count .. ' source files written to ' .. directory)
end

-- request: { version, sides, output, force, remap, settings = { workers, memory } }.
function pipeline.run(platform, request)
  local started = system.now()
  local version = request.version
  if not version then
    version = platform.latest()
    ui.info('Latest ' .. platform.name .. ' version is ' .. version)
  end
  local root = fs:absolute(request.output or fs:join(system.cwd(), platform.name .. '-' .. version))
  output.check(root, request.force)

  ui.step('Preparing ' .. platform.name .. ' ' .. version)
  local sides = (request.sides and #request.sides > 0) and request.sides or platform.sides
  local list = targets.validate(platform.prepare(version, sides), platform.name)

  local record = { platform = platform.name, version = version, minesrc = host:version(), targets = {}, complete = false }
  output.prepare(root, request.force, record)
  for _, target in ipairs(list) do
    local directory = fs:join(root, target.name)
    if target.sources then
      ui.step('Copying ' .. target.name .. ' sources')
      copySources(target.sources, directory)
    else
      ui.step('Decompiling ' .. target.name)
      decompile(target, directory, request)
    end
    record.targets[#record.targets + 1] = target.name
  end

  record.complete = true
  output.manifest(root, record)
  local seconds = math.floor((system.now() - started) / 1000)
  ui.success(string.format('%s %s is ready in %s (%dm %ds)', platform.name, version, root, seconds // 60, seconds % 60))
  return root
end

return pipeline
