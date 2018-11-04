local base = (...):gsub('[^%.]+.[^%.]+$', '')
testCoverage = require 'coverage-config'
local T = require(base .. 'lib.simple-test')

T.check(require(base .. 'test.layout-box'))
T.check(require(base .. 'test.layout-homogeneous-row'))
T.check(require(base .. 'test.layout-heterogeneous-row'))
T.check(require(base .. 'test.layout-homogeneous-column'))
T.check(require(base .. 'test.layout-heterogeneous-column'))
T.check(require(base .. 'test.layout-fit'))
T.check(require(base .. 'test.layer'))
T.check(require(base .. 'test.depth-list'))

T.plan()
