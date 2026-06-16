-- Extract the examples embedded in the graph-drawing (gd) Lua sources into a
-- single l3build test file.  Unlike the manual examples (see extract.lua), the
-- gd examples live in the Lua files and are pulled into the manual by
-- \includeluadocumentationof.  They come in two forms:
--
--   * the "examples" field of a declare{} key, a long string [[...]] or a
--     table { [[...]], ... } of long strings (the surrounding quotes are
--     stripped and the code is dedented, as pgf.manual.DocumentParser does);
--   * \begin{codeexample} ... \end{codeexample} blocks inside the "--" Lua
--     documentation comments.
--
-- Loading the graph-drawing machinery is expensive, so all examples go into a
-- single test file (graph drawing only works with LuaTeX anyway).

local lfs = require("lfs")

local scriptdir = arg[0]:match("^(.*[/\\])") or "./"
package.path = scriptdir .. "?.lua;" .. package.path
local common = require("extract-common")

local lpeg = require("lpeg")
local C, Ct, P, S = lpeg.C, lpeg.Ct, lpeg.P, lpeg.S

local strip = common.strip
local pathsep = common.pathsep

-- The libraries to load.  Only the TikZ libraries actually used by the gd
-- examples are loaded (arrows.meta + bending for the Stealth/bent arrow tips,
-- quotes for the "..." edge/node labels; the circle shape is part of the
-- core).  The "ogdf" and "experimental" gd libraries are omitted as they need
-- a compiled C++ backend.
local gd_preamble =
    "\\usetikzlibrary{graphs,graphs.standard,graphdrawing,arrows.meta,bending,quotes}\n" ..
    "\\usegdlibrary{trees,circular,layered,force,examples," ..
        "phylogenetics,routing,planar,pedigrees}\n"

-- Subdirectories that are skipped: ogdf needs the C++ backend, experimental is
-- not part of the stable interface.
local skipdirs = { ogdf = true, experimental = true }

-- Strip one layer of surrounding double quotes (as DocumentParser does).
local function strip_quotes(s)
    return (s:gsub('^"(.*)"$', "%1"))
end

-- Remove the common leading indentation and surrounding blank lines, so the
-- extracted code reads the same as in the rendered manual.
local function dedent(s)
    local lines = {}
    for line in (s .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
    end
    while #lines > 0 and lines[1]:match("^%s*$") do table.remove(lines, 1) end
    while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
    local min = math.huge
    for _, l in ipairs(lines) do
        if not l:match("^%s*$") then
            min = math.min(min, l:find("%S") or math.huge)
        end
    end
    if min == math.huge then min = 1 end
    for i, l in ipairs(lines) do lines[i] = l:sub(min) end
    return table.concat(lines, "\n")
end

-- Grammar for the "examples" field: a long string or a table of long strings.
local ws = S" \t\n\r"^0
local longstring = P"[[" * C((P(1) - P"]]")^0) * P"]]"
local tablevalue = P"{" * Ct((ws * longstring * ws * P","^-1)^0) * ws * P"}"
local singlevalue = longstring / function(s) return {s} end
local field = P"examples" * ws * P"=" * ws * (tablevalue + singlevalue)
local examples_scanner = Ct((field + P(1))^0)

-- Collect the examples of a single Lua file as a list of {options, content}
-- tables, the same shape the codeexample extractor produces.
local function harvest(text)
    local matches = {}

    -- Form A: the "examples" fields
    for _, list in ipairs(examples_scanner:match(text) or {}) do
        for _, code in ipairs(list) do
            code = dedent(strip(strip_quotes(code)))
            if code ~= "" then
                matches[#matches + 1] = { {}, code }
            end
        end
    end

    -- Form B: \begin{codeexample} blocks inside "--" comments.  Strip the
    -- leading "--" from every line and reuse the codeexample extractor, which
    -- ignores everything outside codeexample environments.
    local decommented = ("\n" .. text):gsub("\n%-%-", "\n"):sub(2)
    for _, m in ipairs(common.extractor:match(decommented) or {}) do
        matches[#matches + 1] = m
    end

    return matches
end

-- Walk the gd Lua tree, accumulating every example into "all".  "prefix" is
-- the dashed name built from the path so far; it is used to label the tests.
local function walk(sourcedir, prefix, all)
    for file in lfs.dir(sourcedir) do
        local path = sourcedir .. pathsep .. file
        if file == "." or file == ".." then
            -- skip
        elseif lfs.attributes(path, "mode") == "directory" then
            if not skipdirs[file] then
                walk(path, prefix .. file .. "-", all)
            end
        elseif file:match("%.lua$") then
            local f = io.open(path)
            local text = f:read("*all")
            f:close()
            local name = prefix .. file:gsub("%.lua$", "")
            local matches = harvest(text)
            if #matches > 0 then
                print("Processing " .. path)
                for i, e in ipairs(matches) do
                    e[3] = name .. "-" .. i  -- the box-test label
                    all[#all + 1] = e
                end
            end
        end
    end
end

-- Main
if #arg < 2 then
    print("Usage: " .. arg[-1] .. " " .. arg[0] .. " <gd-lua-dir> <target-dir>")
    os.exit(1)
end
local sourcedir = arg[1]
local targetdir = arg[2]
assert(lfs.attributes(sourcedir, "mode") == "directory", sourcedir .. " is not a directory")
assert(lfs.attributes(targetdir, "mode") == "directory", targetdir .. " is not a directory")

local all = {}
walk(sourcedir, "gd-", all)
-- This file is run by config-regression-luatex under LuaTeX only and loads all gd libraries
-- via gd_preamble below, so the per-example graph-drawing guarding is skipped.
local t = common.collect(all, "gd-examples", true)
if t.document ~= "" then
    common.write_test(targetdir .. pathsep .. "gd-examples.lvt", {
        preamble   = t.preamble,
        setup_code = t.setup_code,
        body       = t.document,
        extra      = gd_preamble,
    })
end
