--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Helpers for the list of sides a run asked for.
local sides = {}

function sides.wants(list, side)
  for _, name in ipairs(list) do
    if name == side then return true end
  end
  return false
end

return sides
