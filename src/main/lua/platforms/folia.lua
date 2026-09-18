--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

-- Folia: Paper with regionised multithreading, from the same Fill API.
local fill = use('lib/fill')
local papermc = use('lib/papermc')

local folia = {
  name = 'folia',
  description = 'PaperMC Folia server and the Folia API',
  sides = { 'server', 'api' },
}

function folia.versions(all)
  return fill.versions('folia', all)
end

function folia.latest()
  return fill.latest('folia')
end

function folia.prepare(version, wanted, context)
  local jar = fill.download('folia', version)
  return papermc.targets(jar, fill.java('folia', version), wanted, {
    api = 'dev.folia:folia-api:',
    repository = 'https://repo.papermc.io/repository/maven-public/',
  }, context)
end

return folia
