--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Requests and downloads. Downloads land in a cache keyed by their checksum,
-- or by their URL when the source publishes none.
local errors = use('core/errors')
local paths = use('core/paths')
local system = use('core/system')
local ui = use('core/ui')

local net = {}

local ALGORITHMS = { 'sha512', 'sha256', 'sha1', 'md5' }
local PARALLEL = 8
local BAR_THRESHOLD = 1048576

-- PaperMC refuses generic agents: name the tool, its version and where to reach it.
http:userAgent('minesrc/' .. host:version() .. ' (https://github.com/BluevaDevelopment/MineSrc)')

function net.textOrNil(url)
  return errors.context('Could not fetch ' .. url, function() return http:get(url) end)
end

function net.text(url)
  return net.textOrNil(url) or errors.fail(url .. ' was not found (404)')
end

function net.json(url)
  return json:decode(net.text(url))
end

-- The parsed JSON, or nil when the URL answers 404.
function net.jsonOrNil(url)
  local body = net.textOrNil(url)
  return body and json:decode(body)
end

local function fileName(url, options)
  return options.name or url:match('([^/?]+)[^/]*$') or 'download'
end

local function checksum(options)
  for _, algorithm in ipairs(ALGORITHMS) do
    if options[algorithm] then return algorithm, options[algorithm]:lower() end
  end
end

-- Where a download lives in the cache, and whether it is already there.
local function cached(url, options)
  local algorithm, hex = checksum(options)
  local key = algorithm and (algorithm .. '-' .. hex) or ('url-' .. fs:hash(url))
  local target = paths.join(paths.downloads(), key, fileName(url, options))
  local fresh = fs:isFile(target)
  if fresh and options.maxAge then
    fresh = system.now() - fs:modified(target) < options.maxAge * 1000
  end
  return target, fresh, algorithm, hex
end

local function finish(transfer, url, target, options)
  local failure = transfer:failure()
  if failure then errors.fail('Could not download ' .. url .. ': ' .. failure) end
  if not transfer:found() then
    if options.optional then return nil end
    errors.fail(url .. ' was not found (404)')
  end
  ui.detail('Downloaded ' .. url)
  return target
end

-- Downloads url into the cache and returns the file. options: name, one of
-- sha1/sha256/sha512/md5, maxAge in seconds, optional (nil instead of failing on 404).
function net.download(url, options)
  options = options or {}
  local target, fresh, algorithm, hex = cached(url, options)
  if fresh then
    ui.detail('Cached ' .. fs:name(target))
    return target
  end

  local transfer = http:start(url, target, algorithm, hex)
  local bar
  while not transfer:await(100) do
    if not bar and transfer:total() > BAR_THRESHOLD then
      bar = ui.progress('Downloading ' .. fs:name(target), transfer:total(), true)
    end
    if bar then bar.set(transfer:received()) end
  end
  if bar then bar.close() end
  return finish(transfer, url, target, options)
end

-- Downloads several files at once, each { url = ..., name = ..., sha1 = ... },
-- and returns their paths in the same order.
function net.downloadAll(files, label)
  local results, pending, seen = {}, {}, {}
  for index, file in ipairs(files) do
    local target, fresh, algorithm, hex = cached(file.url, file)
    if fresh then
      results[index] = target
    elseif seen[target] then
      -- Old version manifests list some libraries twice.
      results[index] = target
    else
      seen[target] = true
      pending[#pending + 1] = { index = index, file = file, target = target, algorithm = algorithm, hex = hex }
    end
  end
  if #pending == 0 then return results end

  local bar = ui.progress(label, #pending)
  local running, upcoming, done = {}, 1, 0
  while done < #pending do
    while #running < PARALLEL and upcoming <= #pending do
      local job = pending[upcoming]
      job.transfer = http:start(job.file.url, job.target, job.algorithm, job.hex)
      running[#running + 1] = job
      upcoming = upcoming + 1
    end
    running[1].transfer:await(50)
    for position = #running, 1, -1 do
      local job = running[position]
      if job.transfer:await(0) then
        results[job.index] = finish(job.transfer, job.file.url, job.target, job.file)
        table.remove(running, position)
        done = done + 1
        bar.set(done)
      end
    end
  end
  bar.close()
  return results
end

return net
