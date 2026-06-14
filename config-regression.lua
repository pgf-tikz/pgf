-- Regression tests for specific issues, plus a couple of core smoke tests.
--
-- These are hand-written tests (one file per issue, named after the GitHub
-- issue they cover).  Some of them generate plot data with gnuplot, so shell
-- escape is enabled for the whole suite.

testfiledir  = "testfiles-regression"
checkopts    = "-interaction=nonstopmode -shell-escape"

-- Files removed between different engine tests: the gnuplot data, and the aux
-- and out files (so hyperref's rerunfilecheck sees the same first-run state for
-- every engine in the pgfmanual macro test).
dynamicfiles = {"*.gnuplot", "*.table", "*.aux", "*.out"}

-- The pgfmanual macro test (gh-1278) inputs the manual's configuration and
-- preamble, so make the doc sources available in the test directory.
testsuppdir  = "./doc/generic/pgf"
