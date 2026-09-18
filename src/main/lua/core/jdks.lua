--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Picks a JDK for a range of Java versions: the one running MineSrc when it
-- fits, then any installed one that starts, and a download as the last resort.
local errors = use('core/errors')
local net = use('core/net')
local paths = use('core/paths')
local system = use('core/system')
local ui = use('core/ui')

local jdks = {}

local ADOPTIUM = 'https://api.adoptium.net/v3'
local ZULU = 'https://api.azul.com/metadata/v1/zulu'

-- 1.8.0_402 is Java 8, 21.0.2 is Java 21.
function jdks.parseMajor(version)
  local first, second = version:match('^(%d+)%.?(%d*)')
  first = tonumber(first)
  if first == 1 then return tonumber(second) end
  return first
end

-- A JDK home, read through its release file, or nil when it is not one.
function jdks.at(home)
  local release = fs:join(home, 'release')
  local java = paths.join(home, 'bin', system.os() == 'windows' and 'java.exe' or 'java')
  if not fs:isFile(release) or not fs:exists(java) then return nil end
  local version = fs:read(release):match('JAVA_VERSION="([^"]+)"')
  local major = version and jdks.parseMajor(version)
  if not major then return nil end
  return { home = home, major = major, java = java }
end

-- Folders that usually hold one JDK per child, on each system.
local function parents()
  local home = system.home()
  local list = {
    paths.join(home, '.jdks'),
    paths.join(home, '.sdkman', 'candidates', 'java'),
    paths.join(home, '.gradle', 'jdks'),
    paths.jdks(),
  }
  local platform = system.os()
  local more
  if platform == 'mac' then
    more = { '/Library/Java/JavaVirtualMachines', paths.join(home, 'Library', 'Java', 'JavaVirtualMachines'),
      '/opt/homebrew/opt', '/usr/local/opt' }
  elseif platform == 'windows' then
    local programs = system.env('ProgramFiles') or 'C:\\Program Files'
    more = {}
    for _, vendor in ipairs({ 'Java', 'Eclipse Adoptium', 'Eclipse Foundation', 'Microsoft', 'Zulu', 'Amazon Corretto', 'BellSoft' }) do
      more[#more + 1] = fs:join(programs, vendor)
    end
  else
    more = { '/usr/lib/jvm', '/usr/java', '/opt/java', '/opt/jdk' }
  end
  for _, path in ipairs(more) do list[#list + 1] = path end
  return list
end

-- A child of those folders may be the JDK home itself, or hold it a level or two down
-- (Contents/Home on macOS, Homebrew's libexec, the folder inside a downloaded archive).
local function candidates(folder)
  local list = { folder, fs:join(folder, 'Contents/Home'), fs:join(folder, 'libexec/openjdk.jdk/Contents/Home') }
  for _, inner in ipairs(fs:list(folder)) do
    list[#list + 1] = fs:join(folder, inner)
    list[#list + 1] = paths.join(folder, inner, 'Contents/Home')
  end
  return list
end

local installed
function jdks.installed()
  if installed then return installed end
  installed = {}
  local seen = {}
  local function consider(home)
    local jdk = not seen[home] and jdks.at(home)
    seen[home] = true
    if jdk then installed[#installed + 1] = jdk end
  end
  if system.env('JAVA_HOME') then consider(system.env('JAVA_HOME')) end
  for _, parent in ipairs(parents()) do
    for _, child in ipairs(fs:list(parent)) do
      for _, home in ipairs(candidates(fs:join(parent, child))) do consider(home) end
    end
  end
  return installed
end

local verdicts = {}

-- Whether a JDK actually starts: an x64 JDK on Apple Silicon without Rosetta does not.
function jdks.works(jdk)
  if verdicts[jdk.java] == nil then
    local ok, exit = pcall(function()
      local job = process:spawn({
        command = { jdk.java, '-version' },
        dir = paths.work(),
        log = paths.join(paths.work(), 'jdks', 'java-' .. jdk.major .. '.log'),
      })
      if not job:await(30000) then job:kill() return -1 end
      return job:exitCode()
    end)
    verdicts[jdk.java] = ok and exit == 0
    if not verdicts[jdk.java] then ui.detail('Skipping Java ' .. jdk.major .. ' at ' .. jdk.home .. ', it does not start') end
  end
  return verdicts[jdk.java]
end

-- A JDK whose major version is within min and max (open ended when max is nil).
function jdks.find(min, max)
  local function fits(jdk) return jdk.major >= min and (max == nil or jdk.major <= max) end
  local current = system.java()
  if fits(current) then return current end

  local candidates = {}
  for _, jdk in ipairs(jdks.installed()) do
    if fits(jdk) then candidates[#candidates + 1] = jdk end
  end
  table.sort(candidates, function(a, b) return a.major > b.major end)
  for _, jdk in ipairs(candidates) do
    if jdks.works(jdk) then
      ui.detail('Using Java ' .. jdk.major .. ' at ' .. jdk.home)
      return jdk
    end
  end

  local range = max == nil and (min .. ' or later') or (max == min and tostring(min) or (min .. ' to ' .. max))
  ui.info('No working Java ' .. range .. ' installed, downloading Java ' .. min)
  return jdks.download(min)
end

-- Unpacks a downloaded JDK archive into the MineSrc home and finds its home inside.
local function install(archive, name, target)
  local staging = target .. '.part'
  fs:delete(staging)
  if name:match('%.zip$') then zip:unzip(archive, staging) else zip:untar(archive, staging) end
  fs:delete(target)
  fs:move(staging, target)
  installed = nil
  for _, file in ipairs(fs:walk(target, 6)) do
    if fs:name(file) == 'release' then
      local jdk = jdks.at(fs:parent(file))
      if jdk then return jdk end
    end
  end
  errors.fail('The JDK archive ' .. name .. ' has no JDK inside')
end

-- Eclipse Temurin from the Adoptium API, or nil when it has no build for this system.
function jdks.temurin(major, arch)
  local platform = system.os()
  local assets = net.json(ADOPTIUM .. '/assets/latest/' .. major .. '/hotspot?architecture=' .. arch
    .. '&image_type=jdk&os=' .. platform .. '&vendor=eclipse')
  local package = assets[1] and assets[1].binary and assets[1].binary.package
  if not package then return nil end
  local archive = net.download(package.link, { name = package.name, sha256 = package.checksum })
  return install(archive, package.name, fs:join(paths.jdks(), 'temurin-' .. major .. '-' .. arch))
end

-- Azul Zulu, which builds old Java versions natively for Apple Silicon where Temurin does not.
function jdks.zulu(major, arch)
  local platform = system.os() == 'mac' and 'macos' or system.os()
  local archiveType = platform == 'windows' and 'zip' or 'tar.gz'
  local packages = net.json(ZULU .. '/packages/?java_version=' .. major .. '&os=' .. platform .. '&arch=' .. arch
    .. '&archive_type=' .. archiveType .. '&java_package_type=jdk&javafx_bundled=false&latest=true'
    .. '&release_status=ga&availability_types=CA&page_size=1')
  if not packages[1] then return nil end
  local package = net.json(ZULU .. '/packages/' .. packages[1].package_uuid)
  local archive = net.download(package.download_url, { name = package.name, sha256 = package.sha256_hash })
  return install(archive, package.name, fs:join(paths.jdks(), 'zulu-' .. major .. '-' .. arch))
end

-- Native builds first, from Temurin then Zulu. On Apple Silicon an x64 build under Rosetta is the last resort.
function jdks.download(major)
  local arch = system.arch()
  local attempts = {
    function() return jdks.temurin(major, arch) end,
    function() return jdks.zulu(major, arch) end,
  }
  if system.os() == 'mac' and arch == 'aarch64' then
    attempts[#attempts + 1] = function() return jdks.temurin(major, 'x64') end
  end
  for _, attempt in ipairs(attempts) do
    local jdk = attempt()
    if jdk and jdks.works(jdk) then return jdk end
  end
  errors.fail('No Java ' .. major .. ' could be downloaded that runs on this ' .. system.os() .. ' ' .. arch
    .. ' machine. Install one and set JAVA_HOME.')
end

return jdks
