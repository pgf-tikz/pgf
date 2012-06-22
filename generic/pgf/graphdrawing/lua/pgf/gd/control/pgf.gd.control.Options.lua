-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
-- Copyright 2011 by Jannis Pohlmann
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
-- The |Options| class handles table that store options (for vertices, graphs, etc.). 
--
-- An option table can be accessed like a normal table; however, there
-- is a global fallback for this table. If an index is not defined,
-- the value of this index in the global fallback table is used. This
-- reduces the overall amount of option keys that need to be stored
-- with object.
--
-- @field defaults This table stores the global fallbacks.
-- @field accumulates Stores options that accumulate. See the |add|
-- method for details.

local Options = {
  defaults = {},
  accumulates = {}
}
Options.defaults.__index = Options.defaults


-- Namespace
require("pgf.gd.control").Options = Options




--- Turns a table into an options table
--
-- An options table stores the values of options that have been
-- attached to a graph, node, or edge. However, when an option is not
-- defined in an options table, there might still be a definition
-- available in the defaults table. For this reason, an
-- option table gets this latter table attached as its meta table,
-- causing all lookups for unknown options to go there.
--
-- @param t A table in the syntax described in the |add| method.
--
-- @return A copy of t with a new meta table

function Options.new(t)
  local new = {}
  Options.add(new,t)
  setmetatable(new, Options.defaults)
  return new  
end


---
-- Add some options to an existing options table |t|.
--
-- The to-be-added options must be provided as an array. In this
-- array, each entry must have two fields set: |key|, which must store
-- the option's name, and |value|, which must store a value. If the
-- value is |nil|, the option will be cleared (this is true even for
-- accumulating keys, so use this to clear an accumulating key).
--
-- If an option with the name stored in |key| exists in |t|, it will
-- normally be overwritten with the |value|. However, if |key| is a
-- string in the |Options.accumulates| table, then the |value| will be
-- added at the end to the table stored in |t| for the field |key|.
--
-- @param t An options table
-- @param new_options An array of additional options in the form
-- described above.

function Options.add(t,new_options)
  local accumulates = Options.accumulates
  for _,p in ipairs(new_options) do
    local k = p.key
    local v = p.value
    if v == nil then
      t[k] = nil
    else
      if accumulates[k] then
	local array = t[k] or {}
	array[#array+1] = v
	t[k] = array
      else
	t[k] = v
      end
    end
  end
end




--- Tries to find an option in different objects that have an
-- options field.
--
-- This function iterates over all objects given as parameters. In
-- each, it tries to find out whether the options field of the object
-- contains the option |name| and, if so,
-- returns the value. The important point is that checking whether the
-- option table of an object contains the name field is done using
-- |rawget| for all but the last parameter. This means that when you
-- write
--\begin{codeexample}[code only]
--Opptions.lookup("/graph drawing/foo", vertex, graph)
--\end{codeexample}
-- and if |/graph drawin/foo| has a |.parameter initial| set, if the
-- parameter is not explicitly set in a vertex, you will get the value
-- set for the graph or, if it is not set there either, the value from
-- the |.parameter initial|. In contrast, if you write
--\begin{codeexample}[code only]
-- vertex.options["/graph drawing/foo"] or graph.options["/graph drawing/foo"]
--\end{codeexample}
-- what happens is that the first access to |.options| will
-- \emph{always} return something when |.parameter| |initial| has been
-- set. So the above will return the |.parameter| |initial| value whenever
-- the option |/graph drawing/foo| is not set for |vertex|, even
-- though it is set for the |graph|.
--
-- @param name   The name of the options  
-- @param ...    Any number of objects. Each must have an options
--               field. 
--
-- @return The found option

function Options.lookup(name, ...)
  local list = {...}
  for i=1,#list-1 do
    local v = rawget(list[i].options, name)
    if v then
      return v
    end
  end
  return list[#list].options[name]
end



-- Done 

return Options