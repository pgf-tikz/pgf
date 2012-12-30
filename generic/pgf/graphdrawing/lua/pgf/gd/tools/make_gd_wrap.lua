-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



---
-- This program generates a C wrap file around graph drawing
-- algorithms. The idea is that when you have a graph drawing
-- algorithm implemented in C and wish to invoke it from Lua, you need
-- a wrapper that manages the translation between Lua and C. This
-- program is intended to make it (reasonably) easy to produce such a
-- wraper.



-- Sufficient number of arguments?

if #arg < 4 or arg[1] == "-h" or arg[1] == "-?" or arg[1] == "--help" then
  print([["
Usage: make_gd_wrap library1 library2 ... libraryn template library_name target_c_file

This program will read all of the graph drawing library files using
Lua's require. Then, it will iterate over all declared algorithm keys
(declared using declare { algorithm_written_in_c = ... }) and will 
produce the code for library for the required target C files based on
the template.
"]])
  os.exit()
end


-- Imports

local InterfaceToDisplay = require "pgf.gd.interface.InterfaceToDisplay"
local InterfaceCore      = require "pgf.gd.interface.InterfaceCore"


-- Ok, setup:

InterfaceToDisplay.bind(require "pgf.gd.bindings.Binding")


-- Now, read all libraries:

for i=1,#arg-3 do
  require(arg[i])
end


-- Now, read the template:

local file = io.open(arg[#arg-2])
local template = file:read("*a")
file:close()

-- Let us grab the declaration:

local pre, declaration, post = template:match("(.*\n)%${wrap_start}(.*)%${wrap_end}(.*)")


-- Now, handle all keys with a algorithm_written_in_c field

local keys = InterfaceCore.keys
local filename = arg[#arg]
local target = arg[#arg-1]

local includes = {}
local codes = {}
local registry = {}

for _,k in ipairs(keys) do
  
  if k.algorithm_written_in_c and k.code then

    local library, fun_name = k.algorithm_written_in_c:match("(.*)%.(.*)")
    
    if target == library then    
      -- First, gather the includes:
      if type(k.includes) == "string" then
	if not includes[k.includes] then
	  includes[#includes + 1] = k.includes
	  includes[k.includes]    = true
	end
      elseif type(k.includes) == "table" then
	for _,i in ipairs(k.includes) do
	  if not includes[i] then
	    includes[#includes + 1] = i
	    includes[i] = true
	  end
	end
      end
      
      -- Second, create a code block:
      codes[#codes+1] = declaration:gsub("%${(.-)}",
					 {
					   function_name = fun_name,
					   function_body = k.code
					 })

      -- Third, create registry entry
      registry[#registry + 1] =
	'  {"' .. fun_name .. '", ' .. fun_name .. '},'      
    end
  end
end


local file = io.open(filename, "w")

if not file then
  print ("failed to open file " .. filename)
  os.exit(-1)
end

file:write((pre:gsub("%${includes}", table.concat(includes, "\n"))))
file:write(table.concat(codes, "\n\n"))
file:write((post:gsub("%${(.-)}",
		      {
			registry       = table.concat(registry, "\n"),
			library_c_name = target:gsub("%.", "_"),
			library_name   = target
		      })))
file:close()

	   