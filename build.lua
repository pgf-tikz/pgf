-- Identify the bundle and module
module = "pgf"

-- TDS-based installation
installfiles = {}
sourcefiles = {}
unpackfiles = {}
tdsdirs = {tex = "tex"}

-- For the manual
docfiledir = "./doc/generic/pgf"
docfiles =
  {
    "RELEASE_NOTES.md", "description.html", -- Part of the release script
    "color.cfg", "pgfmanual.cfg", "images", "plots", "*.tex" -- Build the manual
  }
tdsroot = "generic"
typesetfiles = {"pgfmanual.tex"}
typesetexe = "lualatex"
flatten = false

-- Set up to allow testing dvips, etc.
specialformats = specialformats or {}
specialformats["latex"] = specialformats["latex"] or
  {
    latexdvips = {binary = "latex", format = ""},
    latexdvisvgm =
      {
        binary = "lualatex",
        format = "",
        options = "--output-format=dvi",
        tokens = "\\def\\pgfsysdriver{pgfsys-dvisvgm.def}"
      }
  }
checkengines = {"pdftex", "latexdvips", "latexdvisvgm", "luatex", "xetex"}

-- Use multiple sets of tests
checkconfigs = {
  "config-regression",
  "config-gd",
  "config-examples",
  "config-examples-pdf",
}

-- common testing support files
checksuppfiles = {"pgf-regression-test.tex"}

-- Example chapters that are excluded from the generated test suite because
-- their references are prohibitively large/slow (see the "examples" target).
examplesexcludefiles =
  {
    "pgfmanual-en-dv-axes",
    "pgfmanual-en-dv-stylesheets",
    -- library-rdf needs an RDF backend that is not available; every example
    -- errors (the /tikz/rdf engine key is undefined) on all engines.
    "pgfmanual-en-library-rdf",
  }

-- For release
ctanzip = "pgf.ctan.flatdir"
packtdszip = true

-- if ctanupload is nil or false, only validation is attempted
if options["dry-run"] then
  ctanupload = false
end

-- CTAN upload
uploadconfig = {
  announcement_file = "RELEASE_NOTES.md",
  author = "Christian Feuersänger;Henri Menke;The PGF/TikZ Team;Till Tantau",
  bugs = "https://github.com/pgf-tikz/pgf/issues",
  ctanPath = "/graphics/pgf/base",
  description = [[<p>PGF is a macro package for creating graphics. It is platform- and format-independent and works together with the most important TeX backend drivers, including pdfTeX and dvips. It comes with a user-friendly syntax layer called TikZ.<br></p><p>Its usage is similar to <a data-cke-saved-href="/pkg/pstricks-base" href="/pkg/pstricks-base">pstricks</a> and the standard picture environment. PGF works with plain (pdf-)TeX, (pdf-)LaTeX, and ConTeXt. Unlike <a data-cke-saved-href="/pkg/pstricks-base" href="/pkg/pstricks-base">pstricks</a>, it can produce either PostScript or PDF output.<br></p>]],
  email = "pgf-tikz@tug.org",
  license = { "fdl", "gpl2", "lppl1.3c" },
  note_file = "CTAN_NOTES.md",
  pkg = "pgf",
  repository = "https://github.com/pgf-tikz/pgf",
  summary = "Create PostScript and PDF graphics in TeX",
  support = "https://tug.org/mailman/listinfo/pgf-tikz",
  update = true,
  uploader = "github-actions",
  -- version has to be passed on the command line
}

function tag_hook(tagname, tagdate)
  local revision = options["--revision"] or tagname
  local revisiondate = options["--revision-date"] or tagdate
  local revisionfiletext = [[
\def\pgfrevision{%s}
\def\pgfversion{%s}
\def\pgfrevisiondate{%s}
\def\pgfversiondate{%s}
]]
  local file = io.open("tex/generic/pgf/pgf.revision.tex", "w")
  file:write(string.format(revisionfiletext, revision, tagname, revisiondate, tagdate))
  file:close()
  return 0
end

-- Regenerate the example tests in testfiles-examples from the manual sources.
-- Run with "l3build examples".
target_list = target_list or { }
target_list.examples =
  {
    desc = "Generate example tests from the manual",
    func = function()
      local sourcedir = "doc/generic/pgf"
      local targetdir = "testfiles-examples"
      local pdftargetdir = "testfiles-examples-pdf"
      local gdtargetdir = "testfiles-gd"
      local gdsourcedir = "tex/generic/pgf/graphdrawing/lua/pgf/gd"
      mkdir(targetdir)
      mkdir(pdftargetdir)
      local errorlevel = run(".", string.format(
        "texlua %s/extract.lua %s %s", sourcedir, sourcedir, targetdir))
      -- The graph-drawing examples are embedded in the gd Lua sources and are
      -- collected into a single file in testfiles-gd (run by config-gd).
      errorlevel = errorlevel + run(".", string.format(
        "texlua %s/extract-gd.lua %s %s", sourcedir, gdsourcedir, gdtargetdir))
      -- extract.lua mirrors the source tree, leaving empty directories behind
      for _, dir in ipairs({"images", "plots", "licenses"}) do
        rmdir(targetdir .. "/" .. dir)
      end
      -- The PDF-based tests for the global-PDF-object chapters live in their
      -- own directory (they are run for a different set of engines).
      cp("*.pvt", targetdir, pdftargetdir)
      rm(targetdir, "*.pvt")
      -- A few chapters produce gigantic, very slow references (the data
      -- visualization axis/stylesheet galleries dump tens of thousands of
      -- boxes each).  They are excluded from the automatically generated
      -- suite.
      for _, name in ipairs(examplesexcludefiles) do
        rm(targetdir, name .. ".lvt")
        rm(targetdir, name .. ".tlg")
      end
      return errorlevel
    end
  }
