-- Extract the examples embedded in the graph-drawing (gd) Lua sources into a
-- single l3build test file.  Unlike the manual examples (see extract.lua), the
-- gd examples live in the Lua files and are pulled into the manual by
-- \includeluadocumentationof, which is rendered by pgf.manual.DocumentParser.
--
-- Rather than re-implementing how DocumentParser turns the Lua sources into TeX
-- (the "examples" field of a declare{} key, \begin{codeexample} blocks in "--"
-- comments, examples pulled in via "documentation_in" lazy-doc files, ...), we
-- run DocumentParser itself under texlua, capture the TeX it would emit into the
-- manual, and feed that through the same codeexample extractor used for the
-- manual sources (common.extractor).  This guarantees the test suite contains
-- exactly the examples a reader sees in the graph-drawing chapters.
--
-- DocumentParser is meant to run inside LuaTeX (via \directlua), so a little
-- environment is set up below: a "tex" table whose print() accumulates into a
-- buffer, a kpse.find_file that resolves module names against the pgf Lua trees
-- (the repo is not installed in a texmf tree), and a binding object (declare{}
-- calls binding:declareCallback, which the base Binding implements as a no-op).
--
-- Loading the graph-drawing machinery is expensive, so all examples go into a
-- single test file (graph drawing only works with LuaTeX anyway).

local lfs = require("lfs")

local scriptdir = arg[0]:match("^(.*[/\\])") or "./"

-- The pgf Lua trees, derived from this script's location (doc/generic/pgf/), so
-- the script does not depend on the current working directory:
--   * tex/generic/pgf/lua            -- pgf.manual.*
--   * tex/generic/pgf/graphdrawing/lua -- pgf and pgf.gd.*
local repo       = scriptdir .. "../../../"
local manuallua  = repo .. "tex/generic/pgf/lua/"
local gdlua      = repo .. "tex/generic/pgf/graphdrawing/lua/"

package.path = scriptdir .. "?.lua;"
            .. manuallua .. "?.lua;"
            .. gdlua .. "?.lua;"
            .. package.path

-- Capture everything DocumentParser would tex.print() into the manual.  The
-- deferred-closure outputs it emits for method summaries also call tex.print,
-- so they land in the same buffer.
local buffer = {}
tex = {
    print = function(...)
        for _, a in ipairs({...}) do
            buffer[#buffer + 1] = tostring(a)
        end
    end,
}

-- Resolve dotted module names against the pgf Lua trees, since the repo is not
-- part of a texmf tree (so the real kpse.find_file would not find these files).
-- This is also what require() of "documentation_in" files needs, but those go
-- through package.path above.
local real_find_file = kpse and kpse.find_file
kpse = kpse or {}
kpse.find_file = function(name, typ)
    for _, base in ipairs({ gdlua, manuallua }) do
        local path = base .. name .. "." .. (typ or "lua")
        local f = io.open(path, "r")
        if f then f:close(); return path end
    end
    return real_find_file and real_find_file(name, typ)
end

-- Initialize the graph-drawing system once and load DocumentParser.
require "pgf"
require "pgf.gd.interface.InterfaceCore"
require "pgf.gd.interface.InterfaceToAlgorithms"
-- declare{} calls InterfaceCore.binding:declareCallback; the base Binding
-- implements it as a no-op, which is exactly what we want here.
require "pgf.gd.interface.InterfaceToDisplay".bind(require "pgf.gd.bindings.Binding")
require "pgf.manual"
local DocumentParser = require "pgf.manual.DocumentParser"

local common = require("extract-common")
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

-- Collect, in manual-appearance order and de-duplicated, the module names the
-- manual documents via \includeluadocumentationof{...}.  This is the manual's
-- own source of truth for what is shown to the reader.  ogdf modules are
-- skipped (they need the C++ backend, just like the old skipdirs).
local function module_list(manualdir)
    local files = {}
    for file in lfs.dir(manualdir) do
        if file:match("%.tex$") then
            files[#files + 1] = file
        end
    end
    table.sort(files)

    local modules, seen = {}, {}
    for _, file in ipairs(files) do
        local f = io.open(manualdir .. pathsep .. file)
        local text = f:read("*all")
        f:close()
        for mod in text:gmatch("\\includeluadocumentationof%s*{(.-)}") do
            if not seen[mod] and not mod:match("ogdf") then
                seen[mod] = true
                modules[#modules + 1] = mod
            end
        end
    end
    return modules
end

-- Render a single module via DocumentParser and return the TeX it emits.
local function render(module)
    buffer = {}
    -- Loading the module populates its declare{} keys (pure-doc modules simply
    -- have nothing to load); best-effort, the include below is what matters.
    pcall(require, module)
    local ok, err = pcall(DocumentParser.include, module)
    if not ok then
        print("Skipping " .. module .. ": " .. tostring(err))
        return nil
    end
    return table.concat(buffer, "\n")
end

-- Main
if #arg < 2 then
    print("Usage: " .. arg[-1] .. " " .. arg[0] .. " <manual-tex-dir> <target-dir>")
    os.exit(1)
end
local manualdir = arg[1]
local targetdir = arg[2]
assert(lfs.attributes(manualdir, "mode") == "directory", manualdir .. " is not a directory")
assert(lfs.attributes(targetdir, "mode") == "directory", targetdir .. " is not a directory")

local all = {}
for _, module in ipairs(module_list(manualdir)) do
    local text = render(module)
    if text then
        local matches = common.extractor:match(text) or {}
        if #matches > 0 then
            print("Processing " .. module)
            -- A short, deterministic label derived from the module name, e.g.
            -- pgf.gd.layered.library -> gd-layered-library-1.
            local prefix = "gd-" .. module:gsub("^pgf%.gd%.", ""):gsub("%.", "-")
            for i, e in ipairs(matches) do
                e[3] = prefix .. "-" .. i
                all[#all + 1] = e
            end
        end
    end
end

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
