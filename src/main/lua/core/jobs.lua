--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- External programs: one followed on a status line, or several behind a bar.
local ui = use('core/ui')

local jobs = {}

-- Runs spec (see process:spawn) while showing its last line, and returns the exit code.
function jobs.run(spec, label)
  local job = process:spawn(spec)
  local status = ui.status(label)
  while not job:await(100) do status.update(job:line()) end
  status.close()
  return job:exitCode()
end

-- The last lines of a log, indented, to show under a failure.
function jobs.tail(log, count)
  if not fs:isFile(log) then return '' end
  local lines = {}
  for line in fs:read(log):gmatch('[^\n]*') do
    if line ~= '' then lines[#lines + 1] = '      ' .. line end
  end
  return table.concat(lines, '\n', math.max(1, #lines - (count or 15) + 1))
end

return jobs
