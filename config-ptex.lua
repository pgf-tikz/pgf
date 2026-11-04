-- Tests for the vertical (tate) direction of pTeX and upTeX.
--
-- These run pLaTeX and upLaTeX and record the driver specials that are
-- produced in the tate direction for the dvipdfmx and dvips drivers.

checkengines = {"ptex", "uptex"}
stdengine    = "ptex"
testfiledir  = "testfiles-ptex"
checkopts    = "-interaction=nonstopmode"
