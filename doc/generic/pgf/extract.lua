-- TODO: this has to go
local preamble = [[
\usetikzlibrary{3d,arrows,arrows.spaced,arrows.meta,bending,babel,calc,
  fit,patterns,plotmarks,shapes.geometric,shapes.misc,shapes.symbols,
  shapes.arrows,shapes.callouts,shapes.multipart,shapes.gates.logic.US,
  shapes.gates.logic.IEC,circuits.logic.US,circuits.logic.IEC,
  circuits.logic.CDH,circuits.ee.IEC,datavisualization,
  datavisualization.polar,datavisualization.formats.functions,er,automata,
  backgrounds,chains,topaths,trees,petri,mindmap,matrix,calendar,folding,
  fadings,shadings,spy,through,turtle,positioning,scopes,
  decorations.fractals,decorations.shapes,decorations.text,
  decorations.pathmorphing,decorations.pathreplacing,decorations.footprints,
  decorations.markings,shadows,lindenmayersystems,intersections,
  fixedpointarithmetic,fpu,svg.path,external,graphs,graphs.standard,quotes,
  math,angles,views,animations,rdf,perspective}
\usetikzlibrary{graphdrawing}
\usegdlibrary{trees,circular,layered,examples,force,phylogenetics,routing}
]]

local lfs = require("lfs")
local lpeg = require("lpeg")
local C, Cf, Cg, Ct, P, S, V = lpeg.C, lpeg.Cf, lpeg.Cg, lpeg.Ct, lpeg.P, lpeg.S, lpeg.V

-- strip leading and trailing whitespace
local function strip(str)
    return str:match"^%s*(.-)%s*$"
end
-- strip braces
local function strip_braces(str)
    return str:match"^{?(.-)}?$"
end

-- optional whitespace
local ws = S" \t\n\r"^0

-- match string literal
local function lit(str)
    return ws * P(str) * ws
end

-- setter for options table
local invalid = string.char(0x8)
local function set(t,k,v)
    -- strip whitespace from keys
    k = strip(k)
    -- if the value is empty, set it to invalid character
    v = v and strip_braces(v) or invalid
    return rawset(t,k,v)
end

-- Grammar to extract code examples
local extractor = lpeg.P{"document",
    name =
        C((1 - S",]=")^1),

    pair =
        Cg(V"name" * (lit"=" * (V"braces" + V"name"))^0) * lit","^-1,

    list =
        Cf(Ct"" * V"pair"^0, set),

    balanced =
        "{" * ((1 - S"{}") + V"balanced")^0 * "}",

    braces =
        C(V"balanced"),

    optarg =
        lit"[" * V"list" * lit"]",

    begincodeexample =
        P"\\begin{codeexample}" * V"optarg",

    endcodeexample =
        P"\\end{codeexample}",

    content =
        C((1 - V"endcodeexample")^0),

    codeexample =
        Ct(V"begincodeexample" * V"content" * V"endcodeexample"),

    anything =
        (1 - V"codeexample")^0,

    document =
        V"anything" * Ct(V"codeexample" * (V"anything" * V"codeexample")^0) * V"anything"
}

-- get the basename and extension of a file
local basename = function(file)
    local basename, ext = string.match(file, "^(.+)%.([^.]+)$")
    return basename or "",  ext or file
end

-- Main loop
if #arg ~= 2 then
    print("Usage: " .. arg[-1] .. " " .. arg[0] .. " <source-dir> <target-dir>")
    os.exit(1)
end
local pathsep = package.config:sub(1,1)
sourcedir = arg[1] .. pathsep
targetdir = arg[2] .. pathsep
assert(lfs.attributes(sourcedir, "mode") == "directory", sourcedir .. " is not a directory")
assert(lfs.attributes(targetdir, "mode") == "directory", targetdir .. " is not a directory")

for file in lfs.dir(sourcedir) do
    if lfs.attributes(sourcedir .. file, "mode") == "file" then
        print("Processing " .. file)

        -- Read file into memory
        local f = io.open(sourcedir .. file)
        local text = f:read("*all")
        f:close()
        local name, ext = basename(file)

        -- preprocess, strip all commented lines
        text = text:gsub("\n%%[^\n]*","")

        -- extract all code examples
        local matches = extractor:match(text) or {}

        -- write code examples to separate files
        local setup_code = ""
        for n, e in ipairs(matches) do
            local options = e[1]
            local content = e[2]

            -- If the snippet is marked as setup code, we have to put it before
            -- every other snippet in the same file
            if options["setup code"] then
                setup_code = setup_code .. strip(content) .. "\n"
            end

            -- Skip those that say "code only" or "setup code"
            if not options["code only"] and not options["setup code"] then
                local newname = name .. "-" .. n .. "." .. ext
                local examplefile = io.open(targetdir .. newname, "w")

                examplefile:write"\\documentclass{standalone}\n"
                examplefile:write"\\usepackage{fp,pgf,tikz,xcolor}\n"
--                examplefile:write(preamble) -- TODO: this has to go
                examplefile:write(setup_code)
                examplefile:write(options["preamble"] and options["preamble"] .. "\n" or "")
                examplefile:write"\\begin{document}\n"
--                examplefile:write"\\makeatletter\n" -- TODO: this has to go
                local pre = options["pre"] or ""
                pre = pre:gsub("##", "#")
                examplefile:write(pre .. "\n")
                if options["render instead"] then
                    examplefile:write(options["render instead"] .. "\n")
                else
                    examplefile:write(strip(content) .. "\n")
                end
                examplefile:write(options["post"] and options["post"] .. "\n" or "")
                examplefile:write"\\end{document}\n"

                examplefile:close()
            end
        end
    end
end
