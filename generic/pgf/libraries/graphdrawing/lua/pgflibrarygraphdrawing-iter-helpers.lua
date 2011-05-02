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

--- This file contains a several functions that are helpful when dealing
--- with iterators. Included are functions to filter values of an iterator,
--- map iterator values to something else etc.

pgf.module("pgf.graphdrawing")

iter = {}



--- Filter out all values of an iterator for which the filter function returns false.
--
-- @param iterator
-- @param filter_func
--
-- @return
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



--- Map all values of an iterator to new values.
--
-- @param iterator
-- @param map_func
--
-- @return
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
