local lfs = require("lfs")
local lpeg = require"lpeg"
local C, Cf, Cg, Ct, P, S, V = lpeg.C, lpeg.Cf, lpeg.Cg, lpeg.Ct, lpeg.P, lpeg.S, lpeg.V

-- strip leading and trailing whitespace
local function strip(str)
    return str:match"^%s*(.-)%s*$"
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
    v = v or invalid
    return rawset(t,k,v)
end

-- Grammar to extract code examples
local extractor = lpeg.P{"document",
    name =
        C((1 - S"]=")^1),

    pair =
        Cg(V"name" * (lit"=" * V"braces")^0) * lit","^-1,

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
    local stripper = P{"stripext",
        dot = P".",
        other = C((1 - V"dot")^0),
        stripext = Ct( C(V"dot"^-1) * V"other" * (V"dot" * V"other")^0 )
    }
    local matches = lpeg.match(stripper, file)
    local ext = table.remove(matches)
    local basename = table.concat(matches)
    return basename, ext
end

-- Main loop
sourcedir = "text-en/"
targetdir = "/tmp/"

for file in lfs.dir(sourcedir) do
    if lfs.attributes(sourcedir .. file, "mode") == "file" then
        -- Read file into memory
        local f = io.open(sourcedir .. file)
        local text = f:read("*all")
        f:close()
        local name, ext = basename(file)

        -- extract all code examples
        local matches = extractor:match(text) or {}

        -- write code examples to separate files
        for n, e in ipairs(matches) do
            local options = e[1]
            local content = e[2]

            -- Skip those that say "code only"
            if not options["code only"] then
                local newname = name .. "-" .. n .. "." .. ext

                local examplefile = io.open(targetdir .. newname, "w")

                -- TODO: Use options to convert to MWE
                examplefile:write("===Options===\n")
                for key, value in pairs(options) do
                    examplefile:write(key)
                    if value ~= invalid then
                        examplefile:write("=" .. value)
                    end
                    examplefile:write("\n")
                end
                examplefile:write("===Content===\n")
                examplefile:write(strip(content))

                examplefile:close()
            end
        end
    end
end
