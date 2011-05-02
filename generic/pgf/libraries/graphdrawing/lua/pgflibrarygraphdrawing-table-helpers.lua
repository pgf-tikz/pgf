-- Copyright 2010 by Renée Ahrens, Jens Kluttig, Olof Frahm
-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

--- This file contains a number of helper functions for tables, including
--- functions to create key and value iterators, copy tables, map table
--- keys, values or pairs to new keys, values or pairs, filter values in
--- a table etc.

pgf.module("pgf.graphdrawing")



--- Copies a table while preserving its metatable.
--
-- @param source The table to copy.
-- @param target The table to which values are to be copied or nil if a new 
--               table is to be allocated.
-- 
-- @return The target table or a newly allocated table containing all
--         keys and values of the original table.
--
function table.copy(source, target)
  target = target or {}
  for key, val in pairs(source) do
    target[key] = val
  end
  return setmetatable(target, getmetatable(source))
end



--- Copies a table and filters out all keys using a function.
--
-- @param table       The table whose values are to be filtered.
-- @param filter_func The test function to be called for each key of the
--                    input table. If it returns false or nil for a key,
--                    the key will not be part of the result table.
--
-- @return Copy of the input table with keys filtered using filter_func.
--
function table.filter_keys(table, filter_func)
  local copy = {}
  for key, val in pairs(table) do
    if filter_func(key) then
      copy[key] = val
    end
  end
  return copy
end



--- Copies a table and filters out all key/value pairs using a function.
--
-- @param table       The table whose values are to be filtered.
-- @param filter_func The test function to be called for each pair of the
--                    input table. If it returns false or nil for a pair,
--                    the pair will not be part of the result table.
--
-- @return Copy of the input table with pairs filtered using filter_func.
--
function table.filter_pairs(table, filter_func)
  local copy = {}
  for key, val in pairs(table) do
    if filter_func(key, value) then
      copy[key] = val
    end
  end
  return copy
end



--- Copies a table and filters out all values using a function.
--
-- @param table       The table whose values are to be filtered.
-- @param filter_func The test function to be called for each value of the
--                    input table. If it returns false or nil for a value,
--                    the value will not be part of the result table.
--
-- @return Copy of the input table with values filtered using filter_func.
--
function table.filter_values(table, filter_func)
  local copy = {}
  for key, val in pairs(table) do
    if filter_func(val) then
      copy[key] = val
    end
  end
  return copy
end



--- Maps keys of a table to new keys.
--
-- @param table    The table whose keys are to be replaced.
-- @param map_func A function to be called for each key in order to generate
--                 a new key to replace the old one.
-- 
-- @return A new table with all keys of the input table having been 
--         replaced with the keys returned from map_func. The original values
--         are preserved.
--
function table.map_keys(table, map_func)
  local copy = {}
  for key, val in pairs(table) do
    local new_key = map_func(key)
    copy[new_key] = val
  end
  return copy
end



--- Maps keys and values of a table to new pairs of keys and values.
--
-- @param table    The table whose key and value pairs are to be replaced.
-- @param map_func A function to be called for each key and value pair in order
--                 to generate a new pair to replace the old one.
--
-- @return A new table with all key and value pairs of the input table having
--         been replaced with the pairs returned from map_func.
--
function table.map_pairs(table, map_func)
  local copy = {}
  for key, val in pairs(table) do
    local new_key, new_val = map_func(key, val)
    copy[new_key] = new_val
  end
  return copy
end



--- Maps values of a table to new values.
--
-- @param table    The table whose values are to be replaced.
-- @param map_func A function to be called for each value in order to generate
--                 a new value to replace the old one.
--
-- @return A new table with all values of the input table having been replaced
--         with the values returned from map_func. The original keys are 
--         preserved.
--
function table.map_values(table, map_func)
  local copy = {}
  for key, val in pairs(table) do
    copy[key] = map_func(val)
  end
  return copy
end



--- Iterate over all keys of a table.
--
-- @param table The table whose keys to iterate over.
--
-- @return An iterator for the keys of the table.
--
function table.key_iter(table)
  local pair_iter, state, key = pairs(table)
  return function ()
    key = pair_iter(state, key)
    return key
  end
end



--- Iterate over all values of a table.
--
-- @param table The table whose values to iterate over.
--
-- @return An iterator for the values of the table.
--
function table.value_iter(table)
  local pair_iter, state, key, value = pairs(table)
  return function ()
    key, value = pair_iter(state, key)
    return value
  end
end
