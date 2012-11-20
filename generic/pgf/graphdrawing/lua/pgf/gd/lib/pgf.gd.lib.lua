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


---
-- Finds the first value in the |array| for which |test| is true.
--
-- @param array  An array to search in.
-- @param test   A function that is applied to each element of the
--               array together with the index of the element and the
--               whole table.
--
-- @return The value of the first value where the test is true.
-- @return The index of the first value where the test is true.
-- @return The function value of the first value where the test is
--         true (only returned if test is a function).
--
function lib.find(array, test)
  for i=1,#array do
    local t = array[i]
    local result = test(t,i,array)
    if result then
      return t,i,result
    end
  end
end


---
-- Finds the first value in the |array| for which a function
-- returns a minimal value
--
-- @param array  An array to search in.
-- @param f      A function that is applied to each element of the
--               array together with the index of the element and the
--               whole table. It should return an integer and, possibly, a value.
--
-- Among all elements for which a non-nil integer is returned, let |i|
-- by the index of the element where this integer is minimal.
--
-- @return |array[i]|
-- @return |i|
-- @return The return value(s) of the function at |array[i]|.
--
function lib.find_min(array, f)
  local best = math.huge
  local best_result
  local best_index 
  for i=1,#array do
    local t = array[i]
    local result, p = f(t,i,array)
    if result and p < best then
      best = p
      best_result = result
      best_index = i
    end
  end
  if best_index then
    return array[best_index],best_index,best_result,best
  end
end




---
-- Copies a table while preserving its metatable.
--
-- @param source The table to copy.
-- @param target The table to which values are to be copied or |nil| if a new 
--               table is to be allocated.
-- 
-- @return The |target| table or a newly allocated table containing all
--         keys and values of the |source| table.
--
function lib.copy(source, target)
  if not target then
    target = {}
  end
  for key, val in pairs(source) do
    target[key] = val
  end
  return setmetatable(target, getmetatable(source))
end




---
-- Apply a function to all pairs of a table, resulting in a new table. 
--
-- @param source The table.
-- @param fun A function taking two arguments (|val| and |key|, in
-- that order). Should return two values (a |new_val| and a
-- |new_key|). This pair will be inserted into the new table. If,
-- however, |new_key| is |nil|, the |new_value| will be inserted at
-- the position |key|. This means, in particular, that if the |fun|
-- takes only a single argument and returns only a single argument,
-- you have a ``classical'' value mapper. Also note that if
-- |new_value| is |nil|, the value is removed from the table.
-- 
-- @return The new table.
--
function lib.map(source, fun)
  local target = {}
  for key, val in pairs(source) do
    local new_val, new_key = fun(val, key)
    if new_key == nil then
      new_key = key
    end
    target[new_key] = new_val
  end
  return target
end



---
-- Apply a function to all elements of an array, resulting in a new
-- array. 
--
-- @param source The array.
-- @param fun A function taking two arguments (|val| and |i|, the
-- current index). This function is applied to all elements of the
-- array. The result of this function is placed at the end of a new
-- array, expect when the function returns |nil|, in which case the
-- element is skipped.
-- @param new The target array (if |nil|, a new array is create).
--
--\begin{codeexample}[code only]
--  local a = lib.imap(array, function(v) if some_test(v) then return v end end)
--\end{codeexample}
--
-- The above code is a filter that will remove all elements from the
-- array that do not pass |some_test|.
--
--\begin{codeexample}[code only]
--  lib.imap(a, lib.id, b)
--\end{codeexample}
--
-- The above code appends the array |a| at the end of the array |b|.
--
-- @return The new array
--
function lib.imap(source, fun, new)
  if not new then
    new = {}
  end
  for i, v in ipairs(source) do
    new[#new+1] = fun(v, i)
  end
  return new
end


---
-- Generate a random permutation of the numbers $1$ to $n$ in time
-- $O(n)$. Knuth's shuffle is used for this.
--
-- @param n The desired size of the table
-- @return A random permutation

function lib.random_permutation(n)
  local p = {}
  for i=1,n do
    p[i] = i
  end
  for i=1,n-1 do
    local j = math.random(i,n)
    p[i], p[j] = p[i], p[j]
  end
  return p
end


---
-- The identity function, so you can write |lib.id| instead of
-- |function (x) return x end|.
--

function lib.id(...)
  return ...
end



---
-- Tries to find an option in different objects that have an
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
--lib.lookup_option("foo", vertex, graph)
--\end{codeexample}
-- and if |/graph drawin/foo| has an inital value set, if the
-- parameter is not explicitly set in a vertex, you will get the value
-- set for the graph or, if it is not set there either, the initial
-- value. In contrast, if you write 
--\begin{codeexample}[code only]
-- vertex.options["foo"] or graph.options["foo"]
--\end{codeexample}
-- what happens is that the first access to |.options| will
-- \emph{always} return something when an initial parameter has been
-- set for the option |foo|. 
--
-- @param name   The name of the options  
-- @param ...    Any number of objects. Each must have an options
--               field. 
--
-- @return The found option

function lib.lookup_option(name, ...)
  local list = {...}
  for i=1,#list-1 do
    local o = list[i].options
    if o then 
      local v = rawget(o, name)
      if v then
	return v
      end
    end
  end
  return list[#list].options[name]
end



-- Done

return lib