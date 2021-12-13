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

-- CTAN upload
uploadconfig = {
  announcement_file = "doc/generic/pgf/RELEASE_NOTES.md",
  author = "Christian Feuersänger;Henri Menke;The PGF/TikZ Team;Till Tantau",
  bugs = "https://github.com/pgf-tikz/pgf/issues",
  ctanPath = "/graphics/pgf/base",
  description = [[<p>PGF is a macro package for creating graphics. It is platform- and format-independent and works together with the most important TeX backend drivers, including pdfTeX and dvips. It comes with a user-friendly syntax layer called TikZ.<br></p><p>Its usage is similar to <a data-cke-saved-href="/pkg/pstricks-base" href="/pkg/pstricks-base">pstricks</a> and the standard picture environment. PGF works with plain (pdf-)TeX, (pdf-)LaTeX, and ConTeXt. Unlike <a data-cke-saved-href="/pkg/pstricks-base" href="/pkg/pstricks-base">pstricks</a>, it can produce either PostScript or PDF output.<br></p>]],
  email = "pgf-tikz@tug.org",
  license = "fdl;gpl2;lppl1.3c",
  note = [[
The release files are signed using a detached signature.  You can obtain the
signature from the GitHub release page

    https =//github.com/pgf-tikz/pgf/releases/download/${{ env.GIT_TAG }}/pgf_${{ env.GIT_TAG }}.ctan.flatdir.zip.sig]],
  pkg = "pgf",
  repository = "https://github.com/pgf-tikz/pgf",
  summary = "Create PostScript and PDF graphics in TeX",
  support = "https://tug.org/mailman/listinfo/pgf-tikz",
  update = true,
  uploader = "github-actions",
  -- version has to be passed on the command line
}

-- For the way pgf does releases
local function trim(str)
    return str:gsub("^%s*(.-)%s$", "%1")
end

local function runcmd(cmd)
    local pid = assert(io.popen(cmd))
    local out = trim(pid:read("*all"))
    pid:close()
    return out
end

local git = {
  tag = runcmd("git describe --abbrev=0 --tags"),
  HEAD = runcmd("git rev-parse --abbrev-ref HEAD"),
}

local function revisionfile()
    -- Generate the revision file
    local revision = runcmd("git describe --tags HEAD")
    local versiondatetime = runcmd("git log -n 1 '" .. git.tag .. "' --pretty=format:'%ci'")
    local revisiondatetime = runcmd("git log -n 1 '" .. revision .. "' --pretty=format:'%ci'")

    local revisionfiletext = [[
\begingroup
\catcode`\-=12
\catcode`\/=12
\catcode`\.=12
\catcode`\:=12
\catcode`\+=12
\catcode`\-=12
\gdef\pgfrevision{%s}
\gdef\pgfversion{%s}
\gdef\pgfversiondatetime{%s}
\gdef\pgfrevisiondatetime{%s}
\gdef\pgf@glob@TMPa#1-#2-#3 #4\relax{#1/#2/#3}
\xdef\pgfversiondate{\expandafter\pgf@glob@TMPa\pgfversiondatetime\relax}
\xdef\pgfrevisiondate{\expandafter\pgf@glob@TMPa\pgfrevisiondatetime\relax}
\endgroup
]]

    local revisionfile = io.open(maindir .. "/tex/generic/pgf/pgf.revision.tex", "w")
    revisionfile:write(string.format(revisionfiletext, git.tag, revision, versiondatetime, revisiondatetime))
    revisionfile:close()
    return 0
end

target_list = target_list or { }
target_list.revisionfile =
  {
    desc = "Create revision data file",
    func = revisionfile
  }
