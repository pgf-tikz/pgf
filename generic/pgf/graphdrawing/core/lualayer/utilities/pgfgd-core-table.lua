-- Copyright 2010 by Renée Ahrens, Jens Kluttig, Olof Frahm
-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file contains a number of helper functions for tables, including
--- functions to create key and value iterators, copy tables, map table
--- keys, values or pairs to new keys, values or pairs, filter values in
--- a table etc.
---
--- TODO:
--- * the order in which keys, pairs and values are iterated over is a
---   bit mixed up right now. need to make this consistent.

pgf.module("pgf.graphdrawing")



--- Merges the key/value pairs of two tables.
--
-- This function merges the key/value pairs of the two input tables.
--
-- All |nil| values of the first table are overwritten by the corresponding
-- values of the second table.
--
-- By default the metatable of the second input table is applied to the 
-- resulting table. If \meta{first\_metatable} is set to |true| however, 
-- the metatable of the first input table will be used.
--
-- @param table1          First table with key/value pairs.
-- @param table2          Second table with key/value pairs.
-- @param first_metatable Whether to inherit the metatable of \meta{table1} 
--                        or not.
--
-- @return A new table with the key/value pairs of the two input tables
--         merged together.
--
function table.custom_merge(table1, table2, first_metatable)
  local result = table1 and table.custom_copy(table1) or {}
  local first_metatable = first_metatable == true or false

  for key, value in pairs(table2) do
    if not result[key] then
      result[key] = value
    end
  end

  if not first_metatable or not getmetatable(result) then
    setmetatable(result, getmetatable(table2))
  end

  return result
end



--- Concatenates the values of two flat tables.
--
function table.merge_values(table1, table2, first_metatable)
  local result = table1 and table.custom_copy(table1) or {}
  local first_metatable = first_metatable == true or false

  for value in table.value_iter(table2) do
    table.insert(result, value)
  end
  
  if not first_metatable or not getmetatable(result) then
    setmetatable(result, getmetatable(table2))
  end

  return result
end



--- Returns the first value in \meta{table} for which \meta{find\_func} returns |true|.
--
-- @param table     The table to search in.
-- @param find_func A function to test values with. It receives a single parameter
--                  (a value of \meta{table}) and is supposed to return either |true|
--                  or |false|.
--
-- @return The first value of \meta{table} for which \meta{find\_func} returns true.
--         Returns |nil| if the function was |false| for al of the values in 
--         \meta{table}.
--
function table.find(table, find_func)
  for _, value in ipairs(table) do
    if find_func(value) then
      return value
    end
  end
  return nil
end



--- Returns the index of the first value in \meta{table} for which \meta{find\_func}
--- returns |true|.
--
-- @param table     The table to search in.
-- @param find_func A function to test values with. It receives a single parameter
--                  (a value of \meta{table}) and is supposed to return either |true|
--                  or |false|.
--
-- @return Index of the first value of \meta{table} for which \meta{find\_func}
--         returns |true|. Returns |nil| if the function was |false| for all of the
--         values in \meta{table}.
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
-- @param target The table to which values are to be copied or |nil| if a new 
--               table is to be allocated.
-- 
-- @return The \meta{target} table or a newly allocated table containing all
--         keys and values of the \meta{source} table.
--
function table.custom_copy(source, target)
  target = target or {}
  for key, val in pairs(source) do
    target[key] = val
  end
  return setmetatable(target, getmetatable(source))
end



-- Reverses the values of a table. The metatable is not preserved.
--
-- @param source Input table whose values are to be reversed.
--
-- @return A new table with the values of \meta{source} reversed.
--
function table.reverse_values(source)
  local copy = {}
  for i = 1,#source do
    copy[i] = source[#source-i+1]
  end
  return copy
end



--- Copies a table and filters out all keys using a function.
--
-- @param table       The table whose values are to be filtered.
-- @param filter_func The test function to be called for each key of \meta{table}. 
--                    If it returns |false| or |nil| for a key, that key will not 
--                    be part of the result table.
--
-- @return Copy of \meta{table} with its keys filtered using \meta{filter\_func}.
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
-- @param filter_func The test function to be called for each pair of \meta{table}.
--                    If it returns |false| or |nil| for a pair, that pair will not 
--                    be part of the result table.
--
-- @return Copy of \meta{table} with its pairs filtered using \meta{filter\_func}.
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
--                    input table. If it returns |false| or |nil| for a value,
--                    that value will not be part of the result table.
--
-- @return Copy of \meta{input} with its values filtered using \meta{filter\_func}.
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



--- Maps key/value pairs of an \meta{input} table to a flat table of new values.
--
-- @param input    Table whose key/value pairs are to be mapped to new values.
-- @param map_func The mapping function to be called for each key/value pair 
--                 of \meta{input}. The value it returns for a pair will be 
--                 inserted into the result table.
--
-- @return A new table containing all values returned by \meta{map\_func}
--         for the key/value pairs of the \meta{input} table.
--
function table.map(input, map_func)
  local copy = {}
  for key, val in pairs(input) do
    table.insert(copy, map_func(key, val))
  end
  return copy
end



--- Maps keys of a table to new keys in a copy of the table.
--
-- @param table    The table whose keys are to be mapped to new keys.
-- @param map_func A function to be called for each key of \meta{table} 
--                 in order to generate a new key to replace the old one
--                 in the result table.
-- 
-- @return A new table with all keys of \meta{table} having been replaced with 
--         the keys returned from \meta{map\_func}. The original values are 
--         preserved.
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
-- @param map_func A function to be called for each key and value pair of 
--                 \meta{table} in order to generate a new pair to replace 
--                 the old one.
--
-- @return A new table with all key and value pairs of \meta{table} having
--         been replaced with the pairs returned from \meta{map\_func}.
--
function table.map_pairs(table, map_func)
  local copy = {}
  for key, val in pairs(table) do
    local new_key, new_val = map_func(key, val)
    copy[new_key] = new_val
  end
  return copy
end



--- Maps values of a table to new values in a new table.
--
-- @param input    The table whose values are to be mapped to new values.
-- @param map_func A function to be called for each value in order to generate
--                 a new value to replace the old one in the result table.
--
-- @return A new table with all values of the \meta{input} table having been 
--         replaced with the values returned from \meta{map\_func}.
--
function table.map_values(input, map_func)
  local copy = {}
  for val in table.value_iter(input) do
    table.insert(copy, map_func(val))
  end
  return copy
end



--- Update values of \meta{table} in-place using an update function.
--
-- @param table       The table whose values are to be updated.
-- @param update_func A function that takes two parameters, the key/value
--                    pairs of \meta{table} and returns a new value to
--                    replace the old one.
--
-- @return The input \meta{table}.
--
function table.update_values(table, update_func)
  for key, val in pairs(table) do
    table[key] = update_func(key, val)
  end
  return table
end



--- Combine all key/value pairs of \meta{table} to a single value
--- using a combine function.
--
-- This is a very powerful function. It can be used for combining the
-- key/value pairs of a table into a single string but can also be used 
-- to compute mathematical operations on tables, such as finding the 
-- maximum value in a table etc.
--
-- The main difference to |table.combine_values| is that keys and values
-- are used to determine the combination value and that the key/value pairs
-- are are passed to \meta{combine\_func} in a random order.
--
-- @param table         Table to iterate over.
-- @param combine_func  Function to be called for each key/value pair. It takes
--                      three parameters, the current combination value and the
--                      key/value pair. It is supposed to return a new 
--                      combination value.
-- @param initial_value Initial combination value.
--
-- @return The final combination value after all key/value pairs have been
--         passed over to \meta{combine\_func}.
--
function table.combine_pairs(table, combine_func, initial_value)
  local combination = initial_value or nil
  for key, val in pairs(table) do
    combination = combine_func(combination, key, val)
  end
  return combination
end



--- Combine all values of \meta{input} to a single value using a combine function.
--
-- This is a very powerful function. It can be used for combining the values 
-- of a table into a single string but can also be used to compute 
-- mathematical operations on tables, such as finding the maximum value in a 
-- table etc.
--
-- The main difference to |table.combine_pairs| is that the keys are ignored
-- and that the values are passed to \meta{combine\_func} in the order they 
-- appear in the table.
--
-- @param input         Table to iterate over.
-- @param combine_func  Function to be called for each value. It takes two parameters, 
--                      the current combination value and the current value. It is 
--                      supposed to return a new combination value.
-- @param initial_value Initial combination value.
--
-- @return The final combination value after all values of \meta{input} have been
--         passed over to \meta{combine\_func}.
--
function table.combine_values(input, combine_func, initial_value)
  local combination = initial_value or nil
  for val in table.value_iter(input) do
    combination = combine_func(combination, val)
  end
  return combination
end



--- Iterate over all keys of a table in deterministic order
--
-- Taken from "Programming in Lua", second edition, page 173.
--
-- @param t The table
-- @param f Sorting function
--
-- @return An iterator

function table.pairs_by_sorted_keys (t, f)
   local a = {}
   for n in pairs(t) do a[#a + 1] = n end
   table.sort (a, f)
   local i = 0
   return function ()
	     i = i + 1
	     return a[i], t[a[i]]
	  end
end


--- Iterate over all keys of a table in nondeterminisitc order.
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
-- FIXME: The iterators stops if a key's value is nil. But we actually want 
-- to continue iterating until the end of the table.
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



--- Iterates over all values of a flat table or array in reverse order.
function table.reverse_value_iter(input)
  local index = #input
  return function ()
    if index <= 0 then
      return nil
    else
      local value = input[index]
      index = index - 1
      return value
    end
  end
end



--- Iterate over the values of \meta{table} in a truely random order.
--
-- @param table The table whose values to iterate over.
--
-- @return A randomized iterator for the values of the table.
--
function table.randomized_value_iter(table)
  local served = {}
  local served_indices = 0

  return function ()
    if served_indices < #table then
      local index = math.random(1, #table)
      while served[index] do
        index = math.random(1, #table)
      end
      served[index] = true
      served_indices = served_indices + 1
      return table[index]
    else
      return nil
    end
  end
end



--- Iterate over the key/value pairs of \meta{table} in a truely random order.
--
-- @param table The table whose key/value pairs to iterate over.
--
-- @return A randomized iterator for the values of \meta{table}.
--
function table.randomized_pair_iter(table)
  local served = {}
  local served_indices = 0

  return function ()
    if served_indices < #table then
      local index = math.random(1, #table)
      while served[index] do
        index = math.random(1, #table)
      end
      served[index] = true
      served_indices = served_indices + 1
      return index, table[index]
    else
      return nil, nil
    end
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



-- TODO: Jannis: Document this method.
function table.remove_pairs(input, remove_func)
  local removals = {}

  for key, value in pairs(input) do
    if remove_func(key, value) then
      table.insert(removals, key)
    end
  end

  for key in table.value_iter(removals) do
    input[key] = nil
  end
  
  return input
end



--- Removes all values from \meta{input} for which \meta{remove\_func} returns |true|.
--
-- Important note: this method does not work with dictionaries. 
-- Make sure only to process number-indexed arrays with it.
--
-- @param input       The table to remove values from.
-- @param remove_func Function to be called for each value of \meta{input}. If
--                    it returns |true|, the value will be removed from the
--                    table in-place.
--
-- @return \meta{input} which was edited in-place.
--
function table.remove_values(input, remove_func)
  local removals = {}
  
  for index, value in ipairs(input) do
    if remove_func(value) then
      table.insert(removals, index)
    end
  end

  for removal_number, index in ipairs(removals) do
    table.remove(input, index - removal_number + 1)
  end

  return input
end
