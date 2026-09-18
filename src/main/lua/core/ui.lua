--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Everything MineSrc prints. Bars and status lines are redrawn in place on a
-- terminal; elsewhere they collapse to one line each, so logs stay readable.
local system = use('core/system')

local ui = { verbose = false }

local function style(text, code)
  if term:color() then return '\27[' .. code .. 'm' .. text .. '\27[0m' end
  return text
end

function ui.say(text) term:out(text) end

-- A stage of the run.
function ui.step(text) term:out(style('==> ', '34') .. style(text, '1')) end

function ui.info(text) term:out('    ' .. text) end

-- Only with --verbose.
function ui.detail(text)
  if ui.verbose then term:out(style('    ' .. text, '2')) end
end

function ui.warn(text) term:out(style('    warning: ', '33') .. text) end

function ui.success(text) term:out(style('==> ', '32') .. style(text, '1')) end

function ui.error(text) term:err(style('error: ', '31') .. text) end

local function megabytes(bytes)
  return string.format('%.1f', bytes / 1048576)
end

-- A bar that fills as set(done) is called.
function ui.progress(label, total, bytes)
  local bar = { drawn = 0 }
  if not term:interactive() then ui.info(label .. '...') end

  function bar.set(done)
    local now = system.now()
    if now - bar.drawn < 100 and done < total then return end
    bar.drawn = now
    local fraction = total > 0 and math.min(done / total, 1) or 0
    local filled = math.floor(fraction * 30)
    local amount = bytes and (megabytes(done) .. '/' .. megabytes(total) .. ' MB') or (done .. '/' .. total)
    term:live('    ' .. label .. ' [' .. string.rep('#', filled) .. string.rep('-', 30 - filled) .. '] '
      .. math.floor(fraction * 100) .. '% ' .. amount)
  end

  function bar.close() term:clear() end

  bar.set(0)
  return bar
end

-- The last line a running tool printed, redrawn in place.
function ui.status(label)
  if not term:interactive() then ui.info(label .. '...') end
  return {
    update = function(line)
      line = line:match('^%s*(.-)%s*$')
      if line ~= '' then term:live('    ' .. label .. ': ' .. line) end
    end,
    close = function() term:clear() end,
  }
end

return ui
