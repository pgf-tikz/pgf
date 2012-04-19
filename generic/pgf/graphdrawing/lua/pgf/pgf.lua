-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$


-- Declare the pgf namespace:
-- (Skip, till old module stuff has been replaced)

pgf = {}



--- Writes some debug info on the TeX output, separating the parameters
-- by spaces. 
--
-- @param ... List of parameters to write to the \TeX\ output.

function pgf.debug(...)
  local stacktrace = debug.traceback("",2)
  texio.write_nl("Debug called for: ")
  -- this is to even print out nil arguments in between
  local args = {...}
  for i = 1, table.getn(args) do
    if i ~= 1 then texio.write(" ") end
    texio.write(tostring(args[i]))
  end
  texio.write_nl('')
  for w in string.gmatch(stacktrace, "/.-:.-:.-%c") do
    texio.write('by ', string.match(w,".*/(.*)"))
  end
end





return pgf