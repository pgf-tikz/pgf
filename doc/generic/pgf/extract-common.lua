-- Shared helpers for the example-extraction scripts (extract.lua for the
-- manual .tex sources, extract-gd.lua for the graph-drawing Lua sources).
--
-- The two scripts harvest examples from very different inputs but emit the
-- same kind of l3build test file, so the parsing of codeexample environments
-- and the writing of the .lvt/.pvt files lives here.

local lpeg = require("lpeg")
local C, Cf, Cg, Ct, P, S, V = lpeg.C, lpeg.Cf, lpeg.Cg, lpeg.Ct, lpeg.P, lpeg.S, lpeg.V

local common = {}

-- strip leading and trailing whitespace
local function strip(str)
    return str:match"^%s*(.-)%s*$"
end
common.strip = strip

-- strip braces
local function strip_braces(str)
    return str:match"^{?(.-)}?$"
end
common.strip_braces = strip_braces

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
common.extractor = lpeg.P{"document",
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
function common.basename(file)
    local basename, ext = string.match(file, "^(.+)%.([^.]+)$")
    return basename or "",  ext or file
end

common.pathsep = package.config:sub(1,1)

-- Turn a list of code examples (each a table with [1]=options, [2]=content,
-- as produced by the extractor) into the pieces of a test file.  Returns the
-- collected (de-duplicated) preamble, the setup code, the box-test body and
-- the PDF-test body (one page per example).
function common.collect(matches, name)
    local setup_code = ""
    local preamble = ""
    local preamble_seen = {}  -- de-duplicate identical preamble snippets
    local document = ""       -- box test (.lvt) body
    local pdfdocument = ""    -- PDF test (.pvt) body, one page per example
    for n, e in ipairs(matches) do
        local options = e[1]
        local content = e[2]
        local label = e[3] or (name .. "-" .. n)

        if content:match("remember picture") then
            goto continue
        end

        -- If the snippet is marked as setup code, we have to put it before
        -- every other snippet in the same file
        if options["setup code"] then
            setup_code = setup_code .. strip(content) .. "\n"
            goto continue
        end

        -- Skip those that say "code only" or "setup code"
        if not options["code only"] and not options["setup code"] then
            -- Collect preamble snippets at the top of the document, skipping
            -- snippets we have already seen.  A snippet is kept whole (e.g. a
            -- multi-line \pgfdeclarepattern), so only exact duplicates are
            -- dropped.
            if options["preamble"] then
                local snippet = strip(options["preamble"])
                if snippet ~= "" and not preamble_seen[snippet] then
                    preamble_seen[snippet] = true
                    preamble = preamble .. snippet .. "\n"
                end
            end

            -- The snippet body, shared between the box and PDF tests
            local body = ""
            local pre = options["pre"]
            if pre then
                pre = pre:gsub("##", "#")
                body = body .. pre .. "\n"
            end
            if options["render instead"] then
                body = body .. options["render instead"] .. "\n"
            else
                body = body .. strip(content) .. "\n"
            end
            body = body .. (options["post"] and (options["post"] .. "\n") or "")

            -- Box test: typeset the snippet into a box and dump it
            document = document .. "\\BEGINBOXTEST{" .. label .. "}\n"
                .. body .. "\\ENDBOXTEST\n\n"

            -- PDF test: ship the snippet out as its own page
            pdfdocument = pdfdocument .. "% " .. label .. "\n"
                .. body .. "\\clearpage\n\n"
        end

        ::continue::
    end
    return {
        preamble    = preamble,
        setup_code  = setup_code,
        document    = strip(document),
        pdfdocument = strip(pdfdocument),
    }
end

-- Write a single test file.  opts has fields: preamble, setup_code, body and
-- an optional extra block inserted into the preamble (the gd libraries for a
-- graph-drawing test, or the PDF-compression switch for a PDF test).
function common.write_test(filename, opts)
    local f = io.open(filename, "w")
    -- Mirror the relevant parts of the manual's preamble so that the examples
    -- have the same packages available as in the manual.
    f:write"\\documentclass{article}\n"
    f:write"\\input{pgf-regression-test}\n"
    f:write"\\RequirePackage{amsmath,amssymb,calc,pifont}\n"
    f:write"\\RequirePackage{fp,xcolor,pgf,tikz,xxcolor}\n"
    -- Colours defined in the manual's preamble (pgfmanual-en-macros) that some
    -- examples rely on.
    f:write"\\colorlet{examplefill}{yellow!80!black}\n"
    f:write"\\definecolor{graphicbackground}{rgb}{0.96,0.96,0.8}\n"
    f:write"\\definecolor{codebackground}{rgb}{0.9,0.9,1}\n"
    f:write"\\definecolor{animationgraphicbackground}{rgb}{0.96,0.96,0.8}\n"
    if opts.extra then f:write(opts.extra) end
    -- Chapters that the manual itself restricts to LuaTeX (\ifluatex ... \endinput)
    -- are only run under LuaTeX: on other engines the gd-dependent preamble and
    -- body are skipped so the test is a clean no-op instead of erroring.
    if opts.luatexonly then f:write"\\ifdefined\\directlua\n" end
    if opts.preamble ~= "" then
        f:write"\n"
        f:write(opts.preamble)
        f:write"\n"
    end
    if opts.luatexonly then f:write"\\fi\n" end
    f:write"\\begin{document}\n\n"
    f:write"\\START\n\n"
    if opts.luatexonly then f:write"\\ifdefined\\directlua\n" end
    if opts.setup_code ~= "" then
        f:write(opts.setup_code)
        f:write"\n"
    end
    f:write(opts.body)
    f:write"\n"
    if opts.luatexonly then f:write"\\fi\n" end
    f:write"\\END\n"
    f:close()
end

return common
