--
-- MineSrc
-- https://github.com/BluevaDevelopment/MineSrc
--
-- Copyright (c) 2026 Blueva Development
--
-- SPDX-License-Identifier: MIT
--

local check = use('support/check')
local versions = use('lib/versions')

local suite = {}

function suite.versionsSortNumericallyWithReleasesAboveTheirPreReleases()
  check.truthy(versions.compare('1.21.10', '1.21.9') > 0)
  check.truthy(versions.compare('26.1', '1.21.11') > 0)
  check.truthy(versions.compare('1.21', '1.21-rc-1') > 0)
  check.truthy(versions.compare('26.3-pre-1', '26.3-rc-1') < 0)
  check.equals(0, versions.compare('1.21.8', '1.21.8'))
  check.equals({ '26.2', '1.21.10', '1.21.8', '1.8.8' }, versions.newestFirst({ '1.8.8', '26.2', '1.21.8', '1.21.10' }))
end

function suite.onlyPlainNumbersAreReleases()
  check.equals({ '26.3', '1.21.8' }, versions.filter({ '26.3', '26.3-rc-1', '1.21.8', '25w14a' }, false))
end

return suite
