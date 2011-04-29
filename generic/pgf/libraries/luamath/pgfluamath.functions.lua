-- Copyright 2011 by Christophe Jorssen
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License.
--
-- See the file doc/generic/pgf/licenses/LICENSE for more details.

module("pgfluamath.functions", package.seeall)

function round(x)
   if x<0 then
      return -math.ceil(math.abs(x)) 
   else 
      return math.ceil(x) 
   end
end

function split_braces(s)
   -- (Thanks to mpg and zappathustra from fctt)
   -- Make unpack available whatever lua version is used 
   -- (unpack in lua 5.1 table.unpack in lua 5.2)
   local unpack = table.unpack or unpack
   local t = {}
   for i in s:gmatch('%b{}') do
      table.insert(t, tonumber(i:sub(2, -2)))
   end
   return unpack(t)
end