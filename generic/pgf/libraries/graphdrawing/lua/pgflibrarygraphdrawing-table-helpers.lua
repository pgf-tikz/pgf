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
---
--- TODO:
--- * the order in which keys, pairs and values are iterated over is a
---   bit mixed up right now. need to make this consistent.

pgf.module("pgf.graphdrawing")



-- Merge the key/value pairs of two tables.
--
-- This function merges the key/value pairs of the two input tables.
--
-- All nil values of the first table are overwritten by the corresponding
-- values of the second table.
--
-- By default the metatable of the second input table is used for the result. 
-- If the third parameter (first_metatable) is set to true however, the 
-- metatable of the first input table will be used.
--
-- @param table1          First table with key/value pairs.
-- @param table2          Second table with key/value pairs.
-- @param first_metatable Whether to inherit the metatable of table1 or not.
--
-- @return A new table with the key/value pairs of the two input tables
--         merged together.
--
function table.merge(table1, table2, first_metatable)
  local result = table1 and table.copy(table1) or {}
  local first_metatable = first_metatable == true or false

  for key, value in pairs(table2) do
    if not result[key] then
      result[key] = value
    end
  end

  if not first_metatable then
    setmetatable(result, getmetatable(table2))
  end

  return result
end



--- Returns the first value for which the function returns true.
--
-- @param table     The table to search in.
-- @param find_func A function to test values with.
--
-- @return The first value of the table for which find_func returns true.
--
function table.find(table, find_func)
  for _, value in ipairs(table) do
    if find_func(value) then
      return value
    end
  end
  return nil
end



-- Returns the index of the first value for which the function returns true.
--
-- @param table 
-- @param find_func
--
-- @return Index of the first value of the table for which find_func 
--         returns true. Returns nil if the function was true for none of
--         the values in the table.
--
function table.find_index(table, find_func)
  for index, value in ipairs(table) do
    if find_func(value) then
      return index
    end
  end
  return nil
end
    


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
-- @param input       The table whose values are to be filtered.
-- @param filter_func The test function to be called for each value of the
--                    input table. If it returns false or nil for a value,
--                    the value will not be part of the result table.
--
-- @return Copy of the input table with values filtered using filter_func.
--
function table.filter_values(input, filter_func)
  local copy = {}
  for val in table.value_iter(input) do
    if filter_func(val) then
      table.insert(copy, val)
    end
  end
  return copy
end



--- Maps key/value pairs to a flat table of new values.
--
-- @param input
-- @param map_func
--
-- @return
--
function table.map(input, map_func)
  local copy = {}
  for key, val in pairs(input) do
    table.insert(copy, map_func(key, val))
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
-- @param input    The table whose values are to be replaced.
-- @param map_func A function to be called for each value in order to generate
--                 a new value to replace the old one.
--
-- @return A new table with all values of the input table having been replaced
--         with the values returned from map_func.
--
function table.map_values(input, map_func)
  local copy = {}
  for val in table.value_iter(input) do
    table.insert(copy, map_func(val))
  end
  return copy
end



--- Update values of the table using an update function.
--
-- @param table
-- @param update_func
--
-- @return
function table.update_values(table, update_func)
  for key, val in pairs(table) do
    table[key] = update_func(key, val)
  end
  return table
end



--- Combine all key/value pairs of the table to a single value
--- using a combine function.
--
-- @param table
-- @param combine_func
-- @param initial_value
--
-- @return
--
function table.combine_pairs(table, combine_func, initial_value)
  local combination = initial_value or nil
  for key, val in pairs(table) do
    combination = combine_func(combination, key, val)
  end
  return combination
end



--- Combine all values of the table to a single value using a combine function.
--
-- @param input
-- @param combine_func
-- @param initial_value
--
-- @return
--
function table.combine_values(input, combine_func, initial_value)
  local combination = initial_value or nil
  for val in table.value_iter(input) do
    combination = combine_func(combination, val)
  end
  return combination
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
  local pair_iter, state, key, value = ipairs(table)
  return function ()
    key, value = pair_iter(state, key)
    return value
  end
end



--- Count the key/value pairs in the table.
--
-- @param input The table whose key/value pairs to count.
--
-- @return Number of key/value pairs in the table.
--
function table.count_pairs(input)
  return table.combine_pairs(input, function (count, k, v) 
    return count + 1 
  end, 0)
end



--- Removes all key/value pairs from the table for whom the 
--- remove function returns true.
--
-- @param input
-- @param remove_func
--
-- @return
--
function table.remove_values(input, remove_func)
  local remove_keys = {}
  
  for key, value in pairs(input) do
    if remove_func(value) then
      table.insert(remove_keys, key)
    end
  end

  for key in table.value_iter(remove_keys) do
    input[key] = nil
  end

  return input
end
