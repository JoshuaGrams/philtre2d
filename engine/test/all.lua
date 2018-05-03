testCoverage = require 'coverage-config'
local T = require('lib.simple-test')

T.check(require 'engine.test.layout-box')
T.check(require 'engine.test.layout-homogeneous-row')
T.check(require 'engine.test.layout-heterogeneous-row')

T.plan()
