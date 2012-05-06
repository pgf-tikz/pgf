-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$




-- Declare the gd namespace

require("pgf").gd = {}



--- Helping function for creating new algorithm classes
--
-- This function creates a new algorithm class. This class will have a
-- new method, that takes a graph and, optionally, a parent algorithm
-- as inputs. They will be stored in the "graph" and "parent_algorithm"
-- fields, respectively.
--
-- @param info This table is used to configure the new class. It has
-- the following fields: First, there is the "properties" table. If
-- this table is present, it will be used as the default table. Second,
-- it can have a graph_parameters table. This table will be used in the
-- constructor to preload graph parameters from the pgf layer. For
-- this, each entry of the table should be of the form 
--
--   key = 'string'
--
-- What happens is that upon the creation of a new algorithm object,
-- for each key we lookup the graph option 'string' and
-- store its value in the key of the new algorithm object.
--
-- @return A table that is a class with a new function setup.

function pgf.gd.new_algorithm_class (info)
  local class = info.properties or {}
  class.__index = class
  class.new = 
    function (initial) 

      -- Create new object
      local obj = {}
      for k,v in pairs(initial) do
	obj[k] = v
      end
      setmetatable(obj, class)

      -- Setup graph_options
      for k,v in pairs(info.graph_parameters or {}) do
	obj[k] = initial.digraph.options[v]
      end

      return obj
    end

  return class
end


return pgf.gd