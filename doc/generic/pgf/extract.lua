local lfs = require("lfs")

-- Resolve the directory this script lives in so we can load the shared module
-- regardless of the current working directory.
local scriptdir = arg[0]:match("^(.*[/\\])") or "./"
package.path = scriptdir .. "?.lua;" .. package.path
local common = require("extract-common")

local strip = common.strip
local basename = common.basename
local pathsep = common.pathsep

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

            -- extract all code examples and collect them into a test file
            local matches = common.extractor:match(text) or {}
            local t = common.collect(matches, name)

            -- write the box test file
            if t.document ~= "" then
                common.write_test(targetdir .. name .. ".lvt", {
                    preamble   = t.preamble,
                    setup_code = t.setup_code,
                    body       = t.document,
                })
            end

            -- write the PDF test file for the global-PDF-object chapters
            if pdffeatures[name] and t.pdfdocument ~= "" then
                common.write_test(targetdir .. name .. ".pvt", {
                    preamble   = t.preamble,
                    setup_code = t.setup_code,
                    body       = t.pdfdocument,
                    extra      = uncompress_pdf,
                })
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
