-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$




--- The AlgorithmLoader class is a singleton object.
--
-- Use this object to load algorithms.

local AlgorithmLoader = {}



-- Namespace
local control = require "pgf.gd.control"
control.AlgorithmLoader = AlgorithmLoader



-- Local stuff

local function class_loader(name, kind)

  local filename = name:gsub(' ', '')
  
  -- if not defined, try to load the corresponding file
  if not pgf.graphdrawing[filename] then
   -- Load the file (if necessary)
   pgf.load("pgfgd-" .. kind .. "-" .. filename .. ".lua", "tex", false)
  end
  local algorithm_class = pgf.graphdrawing[filename]
  
  assert(algorithm_class, "No algorithm named '" .. filename .. "' was found. " ..
	 "Either the file does not exist or the class declaration is wrong.")

  return algorithm_class
end


--- Get the class of an algorithm from a name
--
-- @param name A string
--
-- @return Returns the class object corresponding to the name.

function AlgorithmLoader:algorithmClass(name)
  return class_loader(name, "algorithm")
end
  

--- Get the class of a subalgorithm from a name
--
-- @param name A string
--
-- @return Returns the class object corresponding to the name.

function AlgorithmLoader:subalgorithmClass(name)
  return class_loader(name, "subalgorithm")
end
  


-- Done

return AlgorithmLoader