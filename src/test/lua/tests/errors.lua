--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

local check = use('support/check')
local errors = use('core/errors')

local suite = {}

function suite.aJvmExceptionReadsWithoutItsClassNames()
  check.equals('Could not reach x', errors.message('vm error: java.io.IOException: Could not reach x'))
  check.equals('boom', errors.message('vm error: java.util.concurrent.ExecutionException: java.lang.IllegalStateException: boom'))
end

function suite.aFailureKeepsItsMessage()
  local ok, failure = pcall(errors.fail, 'paper has no version')
  check.equals(false, ok)
  check.truthy(errors.isFailure(failure))
  check.equals('paper has no version', errors.message(failure))
end

return suite
