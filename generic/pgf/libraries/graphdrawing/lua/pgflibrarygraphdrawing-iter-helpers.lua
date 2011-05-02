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

--- This file contains a several functions that are helpful when dealing
--- with iterators. Included are functions to filter values of an iterator,
--- map iterator values to something else etc.

pgf.module("pgf.graphdrawing")



iter = {}



--- Skips all values of an iterator for which \meta{filter\_func} returns |false|.
--
-- @param iterator    Original \meta{iterator} of values.
-- @param filter_func Filter function that takes a value of the original \meta{iterator}
--                    and is expected to return |false| if the value should be skipped.
--
-- @return A modified iterator that skips values of \meta{iterator} for which
--         \meta{filter\_func} returns |false|.
--
function iter.filter(iterator, filter_func)
  return function () 
    local result = iterator()
    while result and not filter_func(result) do
      result = iterator()
    end
    return result
  end
end



--- Maps all values of an iterator to new values.
--
-- This function will cause loops to iterate over the values of 
-- the original \meta{iterator} replaced by the values returned
-- from \meta{map\_func}.
--
-- @param iterator Original iterator whose values are to be mapped to new ones.
-- @param map_func Mapping function that takes a value of the original \meta{iterator}
--                 and maps it to a new value that is then returned to the loop
--                 instead.
--
-- @return A modified iterator.
--
function iter.map(iterator, map_func)
  return function ()
    local result = iterator()
    if result then
      result = map_func(result)
    end
    return result
  end
end



--- Causes a loop to run multiple times.
--
-- Use this iterator like this to perform 100 loops:
-- |for n in iter.times(100) do ... end|.
--
-- To iterate over the values $0, 10, 20, 30, ..., 100$ do:
-- |for n in iter.filter(iter.times(100), function (n) return n % 10 == 0 end)|
--
-- @param n Number of loops.
--
function iter.times(n)
  local last_value = 0

  return function ()
    if last_value >= n then
      return nil
    else
      last_value = last_value + 1
      return last_value
    end
  end
end
