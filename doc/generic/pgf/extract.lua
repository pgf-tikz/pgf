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
local function basename(file)
    local basename, ext = string.match(file, "^(.+)%.([^.]+)$")
    return basename or "",  ext or file
end

local pathsep = package.config:sub(1,1)

-- Chapters whose examples are about global PDF objects (shadings, patterns,
-- fadings, transparency, image xobjects, ...).  For these we additionally
-- emit a PDF-based test (.pvt) that ships every example out as a page so that
-- the actual generated PDF objects can be compared (see config-examples-pdf).
local pdffeatures = {
    ["pgfmanual-en-base-shadings"]    = true,
    ["pgfmanual-en-library-shadings"] = true,
    ["pgfmanual-en-base-patterns"]    = true,
    ["pgfmanual-en-library-patterns"] = true,
    ["pgfmanual-en-base-transparency"]= true,
    ["pgfmanual-en-tikz-transparency"]= true,
    ["pgfmanual-en-base-images"]      = true,
    ["pgfmanual-en-library-shadows"]  = true,
}

-- Engine-portable way to switch off PDF compression so that the produced PDF
-- is text-comparable after normalization.
local uncompress_pdf =
    "\\ifdefined\\pdfcompresslevel\\pdfcompresslevel=0 \\pdfobjcompresslevel=0 \\fi\n"
 .. "\\ifdefined\\pdfvariable\\pdfvariable compresslevel 0 \\pdfvariable objcompresslevel 0 \\fi\n"
 .. "\\ifdefined\\XeTeXversion\\special{dvipdfmx:config z 0}\\fi\n"

-- Walk the file tree
local function walk(sourcedir, targetdir)
    -- Make sure the arguments are directories
    assert(lfs.attributes(sourcedir, "mode") == "directory", sourcedir .. " is not a directory")
    assert(lfs.attributes(targetdir, "mode") == "directory", targetdir .. " is not a directory")

    -- Append the path separator if necessary
    if sourcedir:sub(-1, -1) ~= pathsep then
        sourcedir = sourcedir .. pathsep
    end
    if targetdir:sub(-1, -1) ~= pathsep then
        targetdir = targetdir .. pathsep
    end

    -- Process all items in the directory
    for file in lfs.dir(sourcedir) do
        if file == "." or file == ".." then
            -- Ignore these two special ones
        elseif lfs.attributes(sourcedir .. file, "mode") == "directory" then
            -- Recurse into subdirectories
            lfs.mkdir(targetdir .. file)
            walk(sourcedir .. file .. pathsep, targetdir .. file .. pathsep)
        elseif lfs.attributes(sourcedir .. file, "mode") == "file" then
            print("Processing " .. sourcedir .. file)

            -- Read file into memory
            local f = io.open(sourcedir .. file)
            local text = f:read("*all")
            f:close()
            local name, ext = basename(file)

            -- preprocess, strip all commented lines
            text = text:gsub("\n%%[^\n]*","")

            -- extract all code examples
            local matches = extractor:match(text) or {}

            -- collect all code examples of this file
            local setup_code = ""
            local preamble = ""
            local preamble_seen = {}  -- de-duplicate identical preamble snippets
            local document = ""     -- box test (.lvt) body
            local pdfdocument = ""  -- PDF test (.pvt) body, one page per example
            for n, e in ipairs(matches) do
                local options = e[1]
                local content = e[2]

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
                    -- Collect preamble snippets at the top of the document,
                    -- skipping snippets we have already seen.  A snippet is kept
                    -- whole (e.g. a multi-line \pgfdeclarepattern), so only exact
                    -- duplicates are dropped.
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
                    document = document .. "\\BEGINBOXTEST{" .. name .. "-" .. n .. "}\n"
                        .. body .. "\\ENDBOXTEST\n\n"

                    -- PDF test: ship the snippet out as its own page
                    pdfdocument = pdfdocument .. "% " .. name .. "-" .. n .. "\n"
                        .. body .. "\\clearpage\n\n"
                end

                ::continue::
            end

            -- Write the common preamble shared by the box and PDF test files
            local function write_preamble(f, extra)
                -- Mirror the relevant parts of the manual's preamble so that the
                -- examples have the same packages available as in the manual.
                f:write"\\documentclass{article}\n"
                f:write"\\input{pgf-regression-test}\n"
                f:write"\\RequirePackage{amsmath,amssymb,calc,pifont}\n"
                f:write"\\RequirePackage{fp,xcolor,pgf,tikz,xxcolor}\n"
                -- Colours defined in the manual's preamble (pgfmanual-en-macros)
                -- that some examples rely on.
                f:write"\\colorlet{examplefill}{yellow!80!black}\n"
                f:write"\\definecolor{graphicbackground}{rgb}{0.96,0.96,0.8}\n"
                f:write"\\definecolor{codebackground}{rgb}{0.9,0.9,1}\n"
                f:write"\\definecolor{animationgraphicbackground}{rgb}{0.96,0.96,0.8}\n"
                if extra then f:write(extra) end
                if preamble ~= "" then
                    f:write"\n"
                    f:write(preamble)
                    f:write"\n"
                end
                f:write"\\begin{document}\n\n"
                f:write"\\START\n\n"
                if setup_code ~= "" then
                    f:write(setup_code)
                    f:write"\n"
                end
            end

            -- write the box test file
            document = strip(document)
            if document ~= "" then
                local f = io.open(targetdir .. name .. ".lvt", "w")
                write_preamble(f)
                f:write(document)
                f:write"\n"
                f:write"\\END\n"
                f:close()
            end

            -- write the PDF test file for the global-PDF-object chapters
            pdfdocument = strip(pdfdocument)
            if pdffeatures[name] and pdfdocument ~= "" then
                local f = io.open(targetdir .. name .. ".pvt", "w")
                write_preamble(f, uncompress_pdf)
                f:write(pdfdocument)
                f:write"\n"
                f:write"\\END\n"
                f:close()
            end
        end
    end
end

-- Main loop
if #arg < 2 then
    print("Usage: " .. arg[-1] .. " " .. arg[0] .. " <source-dirs...> <target-dir>")
    os.exit(1)
end
for n = 1, #arg - 1 do
    walk(arg[n], arg[#arg])
end
