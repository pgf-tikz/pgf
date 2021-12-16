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
    "color.cfg", "pgfmanual.cfg", "images/*.jpg", "*.tex" -- Build the PDF
  }
tdsroot = "generic"
typesetfiles = {"pgfmanual.tex"}
typesetexe = "lualatex"
flatten = false

-- To allow writing
function docinit_hook()
  mkdir(typesetdir .. "/plots")
  return 0
end

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

--- Keep all \special data (may one day be the l3build default)
maxprintline = 9999

-- For release
ctanzip = "pgf.ctan.flatdir"
packtdszip = true

-- if ctanupload is nil or false, only validation is attempted
if options["dry-run"] then
  ctanupload = false
end

-- CTAN upload
uploadconfig = {
  announcement_file = "doc/generic/pgf/RELEASE_NOTES.md",
  author = "Christian Feuersänger;Henri Menke;The PGF/TikZ Team;Till Tantau",
  bugs = "https://github.com/pgf-tikz/pgf/issues",
  ctanPath = "/graphics/pgf/base",
  description = [[<p>PGF is a macro package for creating graphics. It is platform- and format-independent and works together with the most important TeX backend drivers, including pdfTeX and dvips. It comes with a user-friendly syntax layer called TikZ.<br></p><p>Its usage is similar to <a data-cke-saved-href="/pkg/pstricks-base" href="/pkg/pstricks-base">pstricks</a> and the standard picture environment. PGF works with plain (pdf-)TeX, (pdf-)LaTeX, and ConTeXt. Unlike <a data-cke-saved-href="/pkg/pstricks-base" href="/pkg/pstricks-base">pstricks</a>, it can produce either PostScript or PDF output.<br></p>]],
  email = "pgf-tikz@tug.org",
  license = "fdl;gpl2;lppl1.3c",
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

target_list = target_list or { }
target_list.revisionfile =
  {
    desc = "Create revision data file",
    func = revisionfile
  }
