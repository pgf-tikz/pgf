-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file includes several helper utilities, which aren't found in
-- the Lua standard library.

pgf.module("pgf.graphdrawing")

function copyTable(table, result)
--- Counts keys in an dictionary, where value is nil.
-- @param table Dictionary.
-- @return Number of keys.
function countKeys(table)
   numItems = 0
   for k, v in pairs(table) do
      numItems = numItems + 1
   end
   return numItems
end

function findTable(table, object)
--- Merges two tables.
-- Every nil value in values is replaced by its default value in
-- defaults.  The metatable from defaults is likewise preserved.
-- As luatex supplies its own version of table.merge, we can't use that
-- same name.
-- @param values New values or nil.  Same as return value if non-nil.
function mergeTable(values, defaults)
   local result = values and copyTable(values) or {}
   for k, v in pairs(defaults) do
      if result[k] == nil then
	 result[k] = v
      end
   end
   if not getmetatable(result) then
      setmetatable(result, getmetatable(defaults))
   end
   return result
end

--- Returns all results from iterator for which test returns a true value.
function filter(iterator, test)
   return
   function ()
      local result = iterator()
      while result and not test(result) do
	 result = iterator()
      end
      return result
   end
end

--- Returns all values in numerical order.
-- @see ipairs
function values(table)
   local i = 0
   return
   function()
      i = i + 1
      return table[i]
   end
end

--- Returns all keys in arbitrary order.
-- @see pairs
function keys(map)
   local result = {}
   for item in pairs(map) do
      table.insert(result, item)
   end
   return values(result)
end

--- Parses a braced list of {key}{value} pairs and returns a table
-- mapping keys to values.
function parseBraces(string, default)
   local fields = {}
   string.gsub(string, "{([^}]*)}", function(x) table.insert(fields, x) end)

   local i, result = 1, {}
   while fields[i] do
      result[fields[i]] = fields[i + 1]
      i = i + 2
   end

   return result
end
