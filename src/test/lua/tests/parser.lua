--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

local check = use('support/check')
local parser = use('cli/parser')

local suite = {}

local command = {
  name = 'paper',
  arguments = { { name = 'version', optional = true } },
  options = {
    { long = 'output', short = 'o', value = 'dir' },
    { long = 'side', short = 's', multiple = true, choices = { 'server', 'api' } },
    { long = 'workers', short = 'w', default = 4, parse = tonumber },
    { long = 'force', short = 'f', flag = true },
  },
}

function suite.optionsArgumentsAndDefaults()
  local values = parser.parse(command, { '1.21.8', '-s', 'api', '--side=server', '--output', 'out', '-f' })
  check.equals('1.21.8', values.version)
  check.equals({ 'api', 'server' }, values.side)
  check.equals('out', values.output)
  check.equals(true, values.force)
  check.equals(4, values.workers)
end

function suite.mistakesAreUsageErrors()
  check.fails('no such option: --nope', parser.parse, command, { '--nope' })
  check.fails('choose from server, api', parser.parse, command, { '--side', 'client' })
  check.fails('--output needs a value', parser.parse, command, { '--output' })
  check.fails('unexpected argument: extra', parser.parse, command, { '1.21.8', 'extra' })
end

function suite.helpWinsOverEverythingElse()
  check.equals({ help = true }, parser.parse(command, { '--nope', '-h' }))
end

return suite
