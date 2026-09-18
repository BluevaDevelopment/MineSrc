--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Where MineSrc keeps what it downloads and builds between runs.
local system = use('core/system')

local paths = {}

-- Joins any number of path parts with the system's separator.
function paths.join(first, ...)
  local path = first
  for _, part in ipairs({ ... }) do path = fs:join(path, part) end
  return path
end

-- MINESRC_HOME, or .minesrc in the user's home.
function paths.home()
  return system.env('MINESRC_HOME') or paths.join(system.home(), '.minesrc')
end

function paths.downloads() return paths.join(paths.home(), 'cache', 'downloads') end

function paths.work() return paths.join(paths.home(), 'work') end

function paths.jdks() return paths.join(paths.home(), 'jdks') end

return paths
