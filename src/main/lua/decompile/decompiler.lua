--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Runs Fernflower over a jar in several worker JVMs at once. Each worker
-- loads the whole jar as context and writes only its own share of the classes.
local classes = use('decompile/classes')
local errors = use('core/errors')
local fernflower = use('decompile/fernflower')
local jobs = use('core/jobs')
local shards = use('decompile/shards')
local system = use('core/system')
local ui = use('core/ui')

local decompiler = {}

local WORKER = 'net.blueva.minesrc.decompile.DecompileWorker'
-- A worker spends a while just loading the jar, so small jars get fewer of them.
local MIN_SHARD = 400
-- Loading also warns about odd class metadata; only a lost method counts.
local FAILED_METHOD = "couldn't be decompiled\\.$"

-- Half the cores, at most four workers, each with 2 GB.
function decompiler.defaults()
  return { workers = math.max(1, math.min(4, system.cpus() // 2)), memory = 2048 }
end

local function spec(destination, jar, libraries, names)
  local lines = { 'destination\t' .. destination, 'source\t' .. jar }
  for _, library in ipairs(libraries) do lines[#lines + 1] = 'library\t' .. library end
  local options = {}
  for key in pairs(fernflower) do options[#options + 1] = key end
  table.sort(options)
  for _, key in ipairs(options) do lines[#lines + 1] = 'option\t' .. key .. '=' .. fernflower[key] end
  for _, name in ipairs(names) do lines[#lines + 1] = 'class\t' .. name end
  return table.concat(lines, '\n') .. '\n'
end

-- Decompiles jar into destination. settings: { workers, memory } (megabytes per worker).
-- Returns { classes, failedMethods, logs }.
function decompiler.run(jar, libraries, exclude, destination, work, settings)
  local context = {}
  for _, library in ipairs(libraries) do
    if library ~= jar then context[#context + 1] = library end
  end
  local roots = classes.roots(jar, exclude, context)
  if #roots == 0 then errors.fail(fs:name(jar) .. ' has no classes left to decompile') end

  local workers = math.max(1, math.min(settings.workers, math.ceil(#roots / MIN_SHARD)))
  local parts = shards.split(roots, workers)
  fs:mkdirs(destination)
  fs:mkdirs(work)
  ui.info(#roots .. ' classes, ' .. #parts .. (#parts == 1 and ' worker' or ' workers') .. ' with ' .. settings.memory .. ' MB each')

  local java = system.java().java
  local running = {}
  for index, names in ipairs(parts) do
    local file = fs:join(work, 'worker-' .. index .. '.spec')
    fs:write(file, spec(destination, jar, context, names))
    local log = fs:join(work, 'worker-' .. index .. '.log')
    running[index] = {
      log = log,
      job = process:spawn({
        command = {
          java, '-Xmx' .. settings.memory .. 'm', '-XX:+UseParallelGC',
          '-Dfile.encoding=UTF-8', '-Dstdout.encoding=UTF-8',
          '-cp', system.classpath(), WORKER, file,
        },
        dir = work,
        log = log,
        count = { done = '^@done ', failed = FAILED_METHOD },
      }),
    }
  end

  local bar = ui.progress('Decompiling ' .. fs:name(jar), #roots)
  local finished = false
  while not finished do
    finished = true
    local done = 0
    for _, worker in ipairs(running) do
      if not worker.job:await(finished and 100 or 0) then finished = false end
      done = done + worker.job:count('done')
    end
    bar.set(done)
  end
  bar.close()

  local failedMethods = 0
  for _, worker in ipairs(running) do
    failedMethods = failedMethods + worker.job:count('failed')
    if worker.job:exitCode() ~= 0 then
      local tail = jobs.tail(worker.log)
      local hint = tail:find('OutOfMemoryError') and '\n    Give each worker more memory with --memory, or use fewer with --workers.' or ''
      errors.fail('A decompiler worker failed (exit ' .. worker.job:exitCode() .. '):\n' .. tail .. '\n    Full log: ' .. worker.log .. hint)
    end
  end
  return { classes = #roots, failedMethods = failedMethods, logs = work }
end

return decompiler
