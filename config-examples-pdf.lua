-- PDF-based tests generated from the manual's global-PDF-object examples
-- (shadings, patterns, fadings, transparency, image xobjects, ...).
--
-- These are generated alongside the box tests by "l3build examples" (see the
-- config-examples.lua header).  Each .pvt ships every example of the chapter
-- out as its own page; l3build builds the PDF, normalizes it and compares it
-- against a per-engine .tpf reference, so the actual generated PDF objects are
-- verified -- something the box tests in config-examples cannot do.
--
-- dvisvgm produces SVG (by way of DVI) rather than PDF, so it is not used
-- here; the box tests in config-examples already exercise that backend.

stdengine    = "luatex"
checkengines = {"luatex", "pdftex", "xetex"}
testfiledir  = "testfiles-examples-pdf"

-- Some examples call out to gnuplot; enable shell escape (see config-examples).
checkopts    = "-interaction=nonstopmode -shell-escape"
dynamicfiles = {"*.gnuplot", "*.table"}

maxprintline = 9999

-- Make the prebuilt plot data and the images used by the examples available
-- inside the test directory.
function checkinit_hook()
  mkdir(testdir .. "/plots")
  cp("*.table", "doc/generic/pgf/plots", testdir .. "/plots")
  cp("*.gnuplot", "doc/generic/pgf/plots", testdir .. "/plots")
  cp("*", "doc/generic/pgf/images", testdir)
  return 0
end
