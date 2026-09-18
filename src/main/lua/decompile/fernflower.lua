--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- How Fernflower is asked to write: its defaults, plus what makes the output read like source.
return {
  -- Generic signatures, not raw types.
  dgs = '1',
  -- Hide synthetic members the compiler added.
  rsy = '1',
  -- Records and switches on patterns, as they were written.
  crp = '1',
  cps = '1',
  -- Keep going past bytecode Fernflower does not understand.
  iib = '1',
  -- Resources are copied by the pipeline, not by each worker.
  sef = '1',
  -- Unix line endings and four spaces.
  nls = '1',
  ind = '    ',
  -- Seconds per method before giving up on it, so one method cannot stall a run.
  mpm = '120',
  log = 'WARN',
}
