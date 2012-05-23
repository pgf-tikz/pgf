-------------------------------------------------------------------------------
-- Doclet that generates TeX output.
-------------------------------------------------------------------------------

local assert, getfenv, ipairs, loadstring, pairs, setfenv, tostring, tonumber, type = assert, getfenv, ipairs, loadstring, pairs, setfenv, tostring, tonumber, type
local io = require"io"
local lfs = require "lfs"
local lp = require "luadoc.lp"
local luadoc = require"luadoc"
local package = package
local string = require"string"
local table = require"table"
local kpse=kpse
local tex=tex
local texio=texio

module "luadoc.doclet.tex"

-------------------------------------------------------------------------------
-- Looks for a file `name' in given path. Removed from compat-5.1
-- @param path String with the path.
-- @param name String with the name to look for.
-- @return String with the complete path of the file found
--	or nil in case the file is not found.

local function search (path, name)
  for c in string.gfind(path, "[^;]+") do
    c = string.gsub(c, "%?", name)
    local f = io.open(c)
    if f then   -- file exist?
      f:close()
      return c
    end
  end
  return nil    -- file not found
end

-------------------------------------------------------------------------------
-- Include the result of a lp template into the current stream.

function include (template, env)
  -- template_dir is relative to package.path
  local templatepath = kpse.find_file(options.template_dir .. template)
  assert(templatepath, string.format("template `%s' not found", template))
	
  env = env or {}
  env.table = table
  env.io = io
  env.lp = lp
  env.tex = tex
  env.string = string
  env.pairs = pairs
  env.texio = texio
  env.ipairs = ipairs
  env.tonumber = tonumber
  env.tostring = tostring
  env.type = type
  env.luadoc = luadoc
  env.options = options
  
  return lp.include(templatepath, env)
end

-------------------------------------------------------------------------------
-- Returns a link to a tex file, appending "../" to the link to make it right.
-- @param tex Name of the tex file to link to
-- @return link to the tex file

function link (tex, from)
	local h = tex
	from = from or ""
	string.gsub(from, "/", function () h = "../" .. h end)
	return h
end

-------------------------------------------------------------------------------
-- Returns the name of the tex file to be generated from a module.
-- Files with "lua" or "luadoc" extensions are replaced by "tex" extension.
-- @param modulename Name of the module to be processed, may be a .lua file or
-- a .luadoc file.
-- @return name of the generated tex file for the module

function module_link (modulename, doc, from)
	-- TODO: replace "." by "/" to create directories?
	-- TODO: how to deal with module names with "/"?
	assert(modulename)
	assert(doc)
	from = from or ""
	
	if doc.modules[modulename] == nil then
--		logger:error(string.format("unresolved reference to module `%s'", modulename))
		return
	end
	
	local href = "modules/" .. modulename .. ".tex"
	string.gsub(from, "/", function () href = "../" .. href end)
	return href
end

-------------------------------------------------------------------------------
-- Returns the name of the tex file to be generated from a lua(doc) file.
-- Files with "lua" or "luadoc" extensions are replaced by "tex" extension.
-- @param to Name of the file to be processed, may be a .lua file or
-- a .luadoc file.
-- @param from path of where am I, based on this we append ..'s to the
-- beginning of path
-- @return name of the generated tex file

function file_link (to, from)
	assert(to)
	from = from or ""
	
	local href = to
	href = string.gsub(href, "lua$", "tex")
	href = string.gsub(href, "luadoc$", "tex")
	string.gsub(from, "/", function () href = "../" .. href end)
	return href
end

-------------------------------------------------------------------------------
-- Returns a link to a function or to a table
-- @param fname name of the function or table to link to.
-- @param doc documentation table
-- @param kind String specying the kinf of element to link ("functions" or "tables").

function link_to (fname, doc, module_doc, file_doc, from, kind)
	assert(fname)
	assert(doc)
	from = from or ""
	kind = kind or "functions"
	
	if file_doc then
		for _, func_name in pairs(file_doc[kind]) do
			if func_name == fname then
				return file_link(file_doc.name, from) .. "#" .. fname
			end
		end
	end
	
	local _, _, modulename, fname = string.find(fname, "^(.-)[%.%:]?([^%.%:]*)$")
	assert(fname)

	-- if fname does not specify a module, use the module_doc
	if string.len(modulename) == 0 and module_doc then
		modulename = module_doc.name
	end

	local module_doc = doc.modules[modulename]
	if not module_doc then
--		logger:error(string.format("unresolved reference to function `%s': module `%s' not found", fname, modulename))
		return
	end
	
	for _, func_name in pairs(module_doc[kind]) do
		if func_name == fname then
			return module_link(modulename, doc, from) .. "#" .. fname
		end
	end
	
--	logger:error(string.format("unresolved reference to function `%s' of module `%s'", fname, modulename))
end

-------------------------------------------------------------------------------
-- Make a link to a file, module or function

function symbol_link (symbol, doc, module_doc, file_doc, from)
	assert(symbol)
	assert(doc)
	
	local href = 
--		file_link(symbol, from) or
		module_link(symbol, doc, from) or 
		link_to(symbol, doc, module_doc, file_doc, from, "functions") or
		link_to(symbol, doc, module_doc, file_doc, from, "tables")
	
	if not href then
		logger:error(string.format("unresolved reference to symbol `%s'", symbol))
	end
	
	return href or ""
end

-------------------------------------------------------------------------------
-- Assembly the output filename for an input file.
-- TODO: change the name of this function
function out_file (filename)
	local h = filename
	h = string.gsub(h, "lua$", "tex")
	h = string.gsub(h, "luadoc$", "tex")
	h = options.output_dir .. string.gsub (h, "^.-([%w_-]+%.tex)$", "%1")
	
	return h
end

-------------------------------------------------------------------------------
-- Assembly the output filename for a module.
-- TODO: change the name of this function
function out_module (modulename)
	local h = modulename .. ".tex"
	h = "modules/" .. h
	h = options.output_dir .. h
	return h
end

-----------------------------------------------------------------
-- Generate the output.
-- @param doc Table with the structured documentation.
function start (doc)
	local prefix = "pgfmanual-en-generated-"

	-- Process files
	if not options.nofiles then
		for _, filepath in ipairs(doc.files) do
			local file_doc = doc.files[filepath]
			-- assembly the filename
			local filename = out_file(prefix .. file_doc.name)

			-- assembly short file name
			local pos=0
			local current=0
			repeat
			   current = string.find(filepath, "/", pos)
			   if current ~= nil then pos = current + 1 end
			   until(current == nil)
			file_doc.shortname = string.sub(filepath, pos)

			-- print(string.format("generating file `%s'", filename))
			
			include("file.lp", { doc = doc, file_doc = file_doc} )
		end
	end
end
