-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$




local lib = {}

-- Declare namespace

require("pgf.gd").lib = lib


-- General lib functions:


--- Finds the first value in the \meta{array} for which a test is true.
--
-- @param array  An array to search in.
-- @param f      A function that is applied to each element of the
--               array together with the index of the element and the
--               whole table.
--
-- @return The value of the first value where the test is true.
-- @return The index of the first value where the test is true.
-- @return The function value of the first value where the test is
--         true (only returned if test is a function).

function lib.find(table, test)
  for i=1,#table do
    local t = table[i]
    local result = test(t,i,table)
    if result then
      return t,i,result
    end
  end
end


--- Finds the first value in the \meta{array} for which a function
-- returns a minimal value
--
-- @param array  An array to search in.
-- @param f      A function that is applied to each element of the
--               array together with the index of the element and the
--               whole table. It should return an integer and, possibly, a value.
--
-- Among all elements for which a non-nil integer is returned, let i
-- by the index of the element where this integer is minimal.
--
-- @return array[i]
-- @return i
-- @return The return value(s) of the function at array[i].

function lib.find_min(table, f)
  local best = math.huge
  local best_result
  local best_index 
  for i=1,#table do
    local t = table[i]
    local result, p = f(t,i,table)
    if result and p < best then
      best = p
      best_result = result
      best_index = i
    end
  end
  if best_index then
    return table[best_index],best_index,best_result,best
  end
end






-- Done

return lib