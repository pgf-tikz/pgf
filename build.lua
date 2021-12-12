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
