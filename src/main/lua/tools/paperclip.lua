--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Paperclip, the launcher Paper and its forks ship. In patch-only mode it
-- patches the vanilla server, writes the result and the libraries next to
-- it, and exits without starting a server.
local bundler = use('tools/bundler')
local errors = use('core/errors')
local jobs = use('core/jobs')
local paths = use('core/paths')

local paperclip = {}

function paperclip.patch(jar, jdk, refresh)
  local directory = paths.join(paths.work(), 'paperclip', fs:digest(jar, 'sha1'):sub(1, 16))
  local complete = fs:join(directory, '.complete')
  if refresh then fs:delete(directory) end

  if not fs:exists(complete) then
    fs:delete(directory)
    local log = fs:join(directory, 'paperclip.log')
    local exit = jobs.run({
      command = { jdk.java, '-Dpaperclip.patchonly=true', '-jar', jar },
      dir = directory,
      log = log,
    }, 'Patching ' .. fs:name(jar))
    if exit ~= 0 then
      errors.fail('Paperclip failed on ' .. fs:name(jar) .. ' (exit ' .. exit .. '):\n' .. jobs.tail(log) .. '\n    Full log: ' .. log)
    end
    fs:write(complete, jar)
  end

  -- Paperclip 1.18 and later write versions/<v>/<name>.jar, older ones cache/patched_<v>.jar.
  local server
  for _, path in ipairs(fs:walk(fs:join(directory, 'versions'), 4)) do
    if path:match('%.jar$') then server = path break end
  end
  if not server then
    for _, path in ipairs(fs:walk(fs:join(directory, 'cache'), 2)) do
      if fs:name(path):match('^patched.*%.jar$') then server = path break end
    end
  end
  if not server then errors.fail('Paperclip ran on ' .. fs:name(jar) .. ' but left no patched jar in ' .. directory) end
  return bundler.describe(server, fs:join(directory, 'libraries'))
end

return paperclip
