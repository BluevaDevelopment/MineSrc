--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Paper: the patched server from PaperMC's Fill API, and the Paper API's own sources.
local fill = use('lib/fill')
local papermc = use('lib/papermc')

local paper = {
  name = 'paper',
  description = 'PaperMC server and the Paper API',
  sides = { 'server', 'api' },
}

function paper.versions(all)
  return fill.versions('paper', all)
end

function paper.latest()
  return fill.latest('paper')
end

function paper.prepare(version, wanted, context)
  local jar = fill.download('paper', version)
  return papermc.targets(jar, fill.java('paper', version), wanted, {
    api = 'io.papermc.paper:paper-api:',
    repository = 'https://repo.papermc.io/repository/maven-public/',
  }, context)
end

return paper
