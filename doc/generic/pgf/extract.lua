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

            -- write code examples to separate files
            local setup_code = ""
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
                    local newname = name .. "-" .. n .. ".tex"
                    local examplefile = io.open(targetdir .. newname, "w")

                    examplefile:write"\\documentclass{standalone}\n"
                    examplefile:write"\\usepackage{fp,pgf,tikz,xcolor}\n"
                    examplefile:write(options["preamble"] and options["preamble"] .. "\n" or "")
                    examplefile:write"\\begin{document}\n"

                    examplefile:write(setup_code)
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

                ::continue::
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
