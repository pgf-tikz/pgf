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
-- or
--   key = 'string [type]'
--
-- What happens is that upon the creation of a new algorithm object,
-- for each key we lookup the graph option '/graph drawing/string' and
-- store its value in the key of the new algorithm object. If the
-- optional type is given, a conversion is performed prior to storing
-- the value. In detail, if type is 'number', then tonumber is applied
-- to the option string prior to storing it; if the type is 'boolean',
-- the option is converted into a boolean (by testing whether it is
-- equal to 'true'); and if the type is 'algorithm' or 'require' or
-- 'load', a require is applied to the option string (which will
-- typically cause an algorithm object to be loaded).
--
-- @return A table that is a class with a new function setup.

function pgf.gd.new_algorithm_class (info)
  local class = info.properties or {}
  class.__index = class
  class.new = 
    function (self, g, algo) 

      -- Create new object
      local obj = { graph = g, parent_algorithm = algo }
      setmetatable(obj, class)

      -- Setup graph_options
      for k,v in pairs(info.graph_parameters or {}) do
	local option, type = string.match(v, '(.-)%s*%[(.*)%]')
	if not option then
	  option = v
	  type = 'string'
	end
	if type == "number" then
	  obj[k] = tonumber(g:getOption('/graph drawing/' .. option))
	elseif type == "boolean" then
	  obj[k] = g:getOption('/graph drawing/' .. option) == 'true'
	elseif type == "algorithm" or type == "require" or type == "load" then
	  obj[k] = require(g:getOption('/graph drawing/' .. option))
	else
	  obj[k] = g:getOption('/graph drawing/' .. option)
	end
      end

      return obj
    end

  return class
end


return pgf.gd