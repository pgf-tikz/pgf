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

--- Copies a table, preserving its metatable.
-- @param table The table from which values are copied.
-- @param result The table to which values are copied or nil.
-- @return A new table containing all the keys and values.
function copyTable(table, result)
   result = result or {}
   for k, v in pairs(table) do
      result[k] = v
   end
   return setmetatable(result, getmetatable(table))
end

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

--- Finds an object in a table.
-- @return The first index for a value which is equal to the object or nil.
function findTable(table, object)
   for i, v in ipairs(table) do
      if object == v then
         return i
      end
   end
   return nil
end

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
function parseBraces(str, default)
  local options = {}

  if str then
    local level = 0
    local key = nil
    local value = ''
    local in_key = false
    local in_value = false
    local skip_char = false

    for i = 1,str:len() do
      skip_char = false

      local char = string.sub(str, i, i)

      if char == '{' then
        if level == 0 then
          if not key then
            in_key = true
          else
            in_value = true
          end
          skip_char = true
        end
        level = level + 1
      elseif char == '}' then
        level = level - 1

        assert(level >= 0) -- otherwise there's a bug in the parsing algorithm

        if level == 0 then
          if in_key then
            in_key = false
          else 
            options[key] = value

            key = nil
            value = ''

            in_value = false
          end
          skip_char = true
        end
      end

      if not skip_char then
        if in_key then
          key = (key or '') .. char
        else
          value = (value or '') .. char
        end
      end

      assert(not (in_key and in_value))
    end
  end

  return options
end
