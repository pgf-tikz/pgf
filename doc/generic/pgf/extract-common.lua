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

-- Is this preamble line a package or library load?  Such loads are idempotent
-- and are hoisted to the test preamble.  (The manual NEVER executes a
-- codeexample's "preamble=" -- it only typesets it as a hint to the reader, see
-- \code@preamble in pgfmanual-en-macros.tex, which is merely \detokenize'd --
-- because the manual loads everything globally.  Our test document is minimal,
-- so we do execute the loads; see has_clashing_declaration for how the
-- (non-load) declarations in a preamble are handled.)
local function is_load_line(line)
    return line:match("^\\usepackage")     ~= nil
        or line:match("^\\RequirePackage") ~= nil
        or line:match("^\\use%a*library")  ~= nil  -- usetikzlibrary, usepgflibrary, usegdlibrary, usepgfkeyslibrary
        or line:match("^\\usepgfmodule")   ~= nil
end

-- Loading the graphdrawing library or any gd library only works under LuaTeX.
local function is_gd_line(line)
    return line:match("^\\usegdlibrary") ~= nil
        or (line:match("^\\usetikzlibrary") ~= nil and line:match("graphdrawing") ~= nil)
end

local function lines_of(s)
    local t = {}
    for line in (s .. "\n"):gmatch("(.-)\n") do t[#t + 1] = line end
    return t
end

-- Does the snippet declare something that errors (or warns) when declared a
-- second time, i.e. \newcommand and friends or a \pgfdeclare...?  Such a
-- declaration in a codeexample's "preamble=" is only shown to the reader; the
-- object is actually declared by an example body (or is loaded globally in the
-- manual).  Executing the preamble copy as well makes it clash ("Pattern
-- `stars' already defined", "Fading `fading' already defined", ...), so for
-- these snippets we keep only the load lines and drop the declarations.  Plain
-- \def/\tikzset/\colorlet definitions overwrite silently and may genuinely be
-- needed (e.g. \def\pgfname), so a snippet containing only those is kept whole.
local function has_clashing_declaration(snippet)
    return snippet:find("\\new", 1, true) ~= nil
        or snippet:find("\\pgfdeclare", 1, true) ~= nil
end

-- Turn a list of code examples (each a table with [1]=options, [2]=content,
-- as produced by the extractor) into the pieces of a test file.  Returns the
-- collected (de-duplicated) preamble, the LuaTeX-only graph-drawing preamble,
-- the box-test body and the PDF-test body (one page per example).
--
-- luatexonly is true for files the manual itself restricts to LuaTeX; for them
-- the whole test is already guarded, so graph-drawing loads/examples are not
-- singled out.
function common.collect(matches, name, luatexonly)
    local preamble = ""
    local gd_preamble = ""    -- graph-drawing loads, emitted LuaTeX-only
    local seen = {}           -- de-duplicate preamble snippets/lines
    local gd_seen = {}
    local document = ""       -- box test (.lvt) body
    local pdfdocument = ""    -- PDF test (.pvt) body, one page per example

    local function add(text, gd)
        if gd then
            if not gd_seen[text] then gd_seen[text] = true; gd_preamble = gd_preamble .. text .. "\n" end
        else
            if not seen[text] then seen[text] = true; preamble = preamble .. text .. "\n" end
        end
    end

    for n, e in ipairs(matches) do
        local options = e[1]
        local content = e[2]
        local label = e[3] or (name .. "-" .. n)

        if content:match("remember picture") then
            goto continue
        end

        -- Setup code: its library loads are hoisted to the preamble (the manual
        -- loads those libraries globally, so every example -- even one appearing
        -- before this block -- must see them), while the definitions are emitted
        -- inline at this position so that they only affect the examples that
        -- follow (as in the manual), instead of being hoisted to the top where
        -- they could clash with an earlier example that defines the same thing.
        if options["setup code"] then
            local rest = {}
            for _, raw in ipairs(lines_of(strip(content))) do
                local line = strip(raw)
                if line ~= "" and is_load_line(line) then
                    add(line, (not luatexonly) and is_gd_line(line))
                else
                    rest[#rest + 1] = raw
                end
            end
            local s = strip(table.concat(rest, "\n"))
            if s ~= "" then
                document = document .. s .. "\n\n"
                pdfdocument = pdfdocument .. s .. "\n\n"
            end
            goto continue
        end

        -- Skip those that say "code only"
        if not options["code only"] then
            -- Collect the preamble.  Pure load-only snippets are kept whole
            -- (snippet-level de-duplication); a snippet that also contains
            -- definitions contributes only its load lines.  Graph-drawing
            -- loads go into a separate LuaTeX-only block and mark the example.
            local example_gd = false
            if options["preamble"] then
                local snippet = strip(options["preamble"])
                if snippet ~= "" then
                    if not has_clashing_declaration(snippet) then
                        -- no clashing declaration: keep the snippet whole (this
                        -- handles multi-line loads and needed \def/\tikzset
                        -- definitions) and de-duplicate at snippet level
                        local gd = (not luatexonly)
                            and (snippet:match("graphdrawing") or snippet:match("usegdlibrary")) ~= nil
                        example_gd = gd
                        add(snippet, gd)
                    else
                        -- keep only the load lines, drop the declarations that the
                        -- manual only shows (a body declares them, see above)
                        for _, raw in ipairs(lines_of(snippet)) do
                            local line = strip(raw)
                            if line ~= "" and is_load_line(line) then
                                local gd = (not luatexonly) and is_gd_line(line)
                                if gd then example_gd = true end
                                add(line, gd)
                            end
                        end
                    end
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
            local box = "\\BEGINBOXTEST{" .. label .. "}\n" .. body .. "\\ENDBOXTEST\n"
            -- PDF test: ship the snippet out as its own page
            local page = "% " .. label .. "\n" .. body .. "\\clearpage\n"
            -- Graph-drawing examples are LuaTeX only; off LuaTeX they are a no-op
            if example_gd then
                box  = "\\ifdefined\\directlua\n" .. box  .. "\\fi\n"
                page = "\\ifdefined\\directlua\n" .. page .. "\\fi\n"
            end
            document    = document    .. box  .. "\n"
            pdfdocument = pdfdocument  .. page .. "\n"
        end

        ::continue::
    end
    return {
        preamble    = preamble,
        gd_preamble = gd_preamble,
        setup_code  = "",
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
    -- The graphdrawing library and the gd libraries are only available under
    -- LuaTeX; guard their loading so the test is a clean no-op elsewhere.
    if opts.gd_preamble and opts.gd_preamble ~= "" then
        f:write"\n\\ifdefined\\directlua\n"
        f:write(opts.gd_preamble)
        f:write"\\fi\n"
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
