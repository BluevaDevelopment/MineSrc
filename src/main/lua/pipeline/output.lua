--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- The folder a run writes into. minesrc.json marks it as MineSrc's own, and
-- only a marked folder is ever deleted, even with --force.
local errors = use('core/errors')

local output = {}

local MANIFEST = 'minesrc.json'

-- Fails before any work is done when the folder cannot be written.
function output.check(root, force)
  if not fs:exists(root) then return end
  if not fs:isDirectory(root) then errors.fail(root .. ' exists and is not a folder') end
  if fs:isEmpty(root) then return end
  if not fs:exists(fs:join(root, MANIFEST)) then
    errors.fail(root .. ' is not empty and was not written by MineSrc. Choose another folder with --output.')
  end
  if not force then errors.fail(root .. ' already exists. Pass --force to replace it.') end
end

function output.manifest(root, record)
  fs:write(fs:join(root, MANIFEST), json:encode(record) .. '\n')
end

-- Empties the folder and marks it as MineSrc's right away, so a run that fails halfway can be replaced.
function output.prepare(root, force, record)
  output.check(root, force)
  fs:delete(root)
  fs:mkdirs(root)
  output.manifest(root, record)
end

return output
