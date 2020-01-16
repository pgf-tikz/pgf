#!/usr/bin/env texlua

local lfs = require("lfs")

-- [[ Some helper function ]]

-- Trim leading and trailing whitespace
local function trim(str)
    return str:gsub("^%s*(.-)%s$", "%1")
end

-- Capture the output of a command
local function run(cmd)
    local pid = assert(io.popen(cmd))
    local out = trim(pid:read("*all"))
    pid:close()
    return out
end

-- Create a temporary directory
local function tmpdir()
    -- create a temporary file using os.tmpname
    local tmpname = os.tmpname()

    -- remove the file and create a directory with that name instead
    pcall(os.remove, tmpname)
    lfs.mkdir(tmpname)

    -- Append the directory separator and return
    return tmpname .. "/"
end

-- file utilities

function lfs.exists(path)
    return lfs.attributes(path, "mode") ~= nil
end

function lfs.isfile(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "file"
end

function lfs.rmkdir(path)
    if lfs.exists(path) then
        return true
    end
    local dirname = lfs.basename(path)
    local r, err = lfs.rmkdir(dirname)
    if not r then
        return nil, err .. " (creating " .. path .. ")"
    end
    return lfs.mkdir(path)
end

function lfs.copy(src, dest, verbose)
    local attr = lfs.attributes(src)
    local bttr = lfs.attributes(dest)

    if attr.mode == "file" and bttr and bttr.mode == "directory" then
        error("Target is a directory")
    end

    if verbose then
        print(src .. " -> " .. dest)
    end

    if attr.mode == "file" then
        local f, content
        f = io.open(src, "rb")
        content = f:read("*all")
        f:close()

        local dirname = lfs.basename(dest)
        if not lfs.exists(dirname) then
            lfs.rmkdir(dirname)
        end
        f = io.open(dest, "wb")
        f:write(content)
        f:close()
    end
end

-- get the basename and extension of a file
function lfs.basename(path)
    return string.match(path, "^(.+)/([^/]*)$")
end

-- [[ Code to build PGF ]]

local git = {
    tag = run("git describe --abbrev=0 --tags"),
    HEAD = run("git rev-parse --abbrev-ref HEAD"),
}

local function revisionfile()
    -- Generate the revision file
    local revision = run("git describe --tags HEAD")
    local versiondatetime = run("git log -n 1 '" .. git.tag .. "' --pretty=format:'%ci'")
    local revisiondatetime = run("git log -n 1 '" .. revision .. "' --pretty=format:'%ci'")

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

    local revisionfile = io.open("tex/generic/pgf/pgf.revision.tex", "w")
    revisionfile:write(string.format(revisionfiletext, git.tag, revision, versiondatetime, revisiondatetime))
    revisionfile:close()
end

local function manual()
    local enginesettings = {
        dvipdfm = {
            latex = "latex --interaction=nonstopmode --halt-on-error pgfmanual.tex",
            postaction = "dvipdfm -p a4 pgfmanual.dvi"
        },
        dvipdfmx = {
            latex = "latex --interaction=nonstopmode --halt-on-error pgfmanual.tex",
            postaction = "dvipdfmx -p a4 pgfmanual.dvi"
        },
        dvips = {
            latex = "latex --interaction=nonstopmode --halt-on-error pgfmanual.tex",
            postaction = {
                "dvips -o pgfmanual.ps pgfmanual.dvi",
                "gs -dNOPAUSE -sDEVICE=pdfwrite -dBATCH -dCompatibilityLevel=1.4 -sOutputFile=pgfmanual.pdf pgfmanual.ps"
            }
        },
        dvisvgm = {
            latex = "lualatex --output-format=dvi --interaction=nonstopmode --halt-on-error pgfmanual.tex",
            postaction = "dvisvgm --font-format=woff --no-merge --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none pgfmanual.dvi"
        },
        luatex = {
            latex = "lualatex --interaction=nonstopmode --halt-on-error pgfmanual.tex"
        },
        pdftex = {
            latex = "pdflatex --interaction=nonstopmode --halt-on-error pgfmanual.tex"
        },
        tex4ht = {
            latex = [[make4ht pgfmanual.tex "svg" "" "" " -interaction=nonstopmode --halt-on-error"]],
        },
        xetex = {
            latex = "xelatex --no-pdf --interaction=nonstopmode --halt-on-error pgfmanual.tex",
            postaction = "xdvipdfmx -p a4 pgfmanual.xdv"
        }
    }

    -- Always generate this
    revisionfile()

    local engine = assert(arg[2], "Specify engine")

    local cwd = lfs.currentdir()
    lfs.chdir("doc/generic/pgf/version-for-" .. engine .. "/en")

    local TEXINPUTS = os.getenv("TEXINPUTS") or ""
    os.setenv("TEXINPUTS", "../../text-en:../../images:" .. TEXINPUTS)

    -- Automatic rerun to get cross-references right
    local run = 0
    local maxruns = 5
    local rerun = false
    repeat
        rerun = false
        local log = {}
        local latex = assert(io.popen(enginesettings[engine].latex))
        for line in latex:lines() do
            print(line)
            log[#log + 1] = line
        end
        local success, exit, signal = latex:close()
        if not success then
            error("There were errors during run " .. tostring(run + 1))
        end

        for _, line in ipairs(log) do
            if string.match(line, "There were undefined references") or
                string.match(line, "Rerun to get cross%-references right") or
                string.match(line, "Rerun to get the bars right") then
                rerun = true
                break
            end
        end
        run = run + 1
        print("Rerun required: " .. tostring(rerun))
        print("This was run number: " .. tostring(run))
    until(run == maxruns or not rerun)

    if run == maxruns and rerun then
        error("Document did not converge after 5 runs!")
    end

    -- Run the postaction
    if type(enginesettings[engine].postaction) == "string" then
        local action = enginesettings[engine].postaction
        local success, exit, signal = os.execute(action)
        if not success then
            error("There were errors during \"" .. tostring(action) .. "\"")
        end
    elseif type(enginesettings[engine].postaction) == "table" then
        for _, action in ipairs(enginesettings[engine].postaction) do
            local success, exit, signal = os.execute(action)
            if not success then
                error("There were errors during \"" .. tostring(action) .. "\"")
            end
        end
    end

    lfs.chdir(cwd)
end

local function generate_FILES()
    -- patterns for files to be excluded
    local excludes = {
        "^%.github/",
        "^ci/",
        "^experiments/",
        "^%.gitignore$",
        "^%.travis%.yml$",
        "^build%.lua$",
        "^README.*$",
    }

    -- list of untracked files to be added
    local untracked = {
        "doc/generic/pgf/FILES",
        "doc/generic/pgf/pgfmanual.pdf",
        "tex/generic/pgf/pgf.revision.tex",
    }

    -- add all the tracked files
    local files = {}
    local git = assert(io.popen("git ls-tree -r --name-only " .. git.HEAD))
    for line in git:lines() do
        local skip = false
        for _, exclude in pairs(excludes) do
            if string.match(line, exclude) then
                skip = true
            end
        end
        if not skip then
            files[#files + 1] = line
        end
    end
    git:close()

    -- add all the untracked files
    for _, file in ipairs(untracked) do
        files[#files + 1] = file
    end

    -- sort them (not really necessary but gives nicer FILES)
    table.sort(files)

    return files
end

local function generate_TDSzip(filename)
    local files = generate_FILES()

    -- write FILES
    local FILES = io.open("doc/generic/pgf/FILES", "w")
    for _, line in ipairs(files) do
        FILES:write(line .. "\n")
    end
    FILES:close()

    -- Check that the manual has been built
    if lfs.isfile("doc/generic/pgf/version-for-luatex/en/pgfmanual.pdf") then
        lfs.copy("doc/generic/pgf/version-for-luatex/en/pgfmanual.pdf", "doc/generic/pgf/pgfmanual.pdf")
    else
        error("doc/generic/pgf/version-for-luatex/en/pgfmanual.pdf is missing")
    end

    -- Check that all files actually exist
    for _, f in ipairs(files) do
        if not lfs.exists(f) then
            error("The file \"" .. f .. "\" does not exist but is tracked by git")
        end
    end

    -- zip it all up
    local zipfile = filename or ("pgf_" .. git.tag .. ".tds.zip")
    local filelist = table.concat(files, " ")
    os.execute(table.concat({"zip", zipfile, filelist}, " "))

    return zipfile
end

local function generate_CTANzip(filename)
    local files = generate_FILES()
    local tds = generate_TDSzip("pgf.tds.zip")

    local tmproot = tmpdir()
    local tmppgf = tmproot .. "pgf/"
    lfs.mkdir(tmppgf)

    for _, f in pairs(files) do
        local dirname, basename = lfs.basename(f)

        -- TeX files
        if string.match(f, "^tex/.*[^lua]$") then

            lfs.copy(f, tmppgf .. "tex/" .. basename)

        -- Source files
        elseif string.match(f, "^source/.*$") and basename ~= "Makefile" then

            lfs.copy(f, tmppgf .. "source/" .. basename)

        -- Documentation files
        elseif string.match(f, "^doc/generic/pgf/.*$") then

            local relpath = string.match(f, "^doc/generic/pgf/(.*)$")
            lfs.copy(f, tmppgf .. "doc/" .. relpath)

        -- Lua graphdrawing files
        elseif string.match(f, "^tex/generic/pgf/graphdrawing/lua/.*lua$") then

            local relpath = string.match(f, "^tex/generic/pgf/graphdrawing/lua/(.*lua)$")
            lfs.copy(f, tmppgf .. "lua/graphdrawing/" .. relpath)

        -- Lua luamath files
        elseif string.match(f, "^tex/generic/pgf/libraries/luamath/.*lua$") then

            local relpath = string.match(f, "^tex/generic/pgf/libraries/luamath/(.*lua)$")
            lfs.copy(f, tmppgf .. "lua/luamath/" .. relpath)

        -- Lua graphdrawing files
        elseif string.match(f, "^tex/generic/pgf/graphdrawing/lua/.*lua$") then

            local relpath = string.match(f, "^tex/generic/pgf/lua/(.*lua)$")
            lfs.copy(f, tmppgf .. "lua/generic/" .. relpath)

        end
    end

    -- Write install notes
    local f = io.open(tmppgf .. "INSTALL_NOTES", "w")
    f:write("Please search for pgf.tds.zip and install that one into a local " ..
        "texmf branch (which is typically simpler). This release is intended " ..
        "to satisfy CTAN package browsing policies.\n")
    f:close()

    -- Copy over README
    lfs.copy("README.md", tmppgf .. "README")

    -- Move over the TDS zip
    lfs.copy(tds, tmproot .. tds)

    -- Pack zipfile
    local ctanzip = filename or ("pgf_" .. git.tag .. ".ctan.flatdir.zip")
    local cwd = lfs.currentdir()
    lfs.chdir(tmproot)
    os.execute(table.concat({"zip -r", cwd .. "/" .. ctanzip, "."}, " "))
    lfs.chdir(cwd)

    return ctanzip
end

-- [[ Run selected tasks ]]

local tasks = {
    manual = manual,
    revisionfile = revisionfile,
    tds = generate_TDSzip,
    ctan = generate_CTANzip,
}
tasks.help = function()
    print("Available commands:")
    for task in pairs(tasks) do
        print("  " .. task)
    end
end
local task = tasks[arg[1] or "help"]
task()
