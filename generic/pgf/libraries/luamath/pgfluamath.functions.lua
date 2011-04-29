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

function pointnormalised (pgfx, pgfy)
   local pgfx_normalised, pgfx_normalised
   if pgfx == 0. and pgfy == 0. then
      -- Orginal pgf macro gives this result
      return tex.print(-1,
	 "\\csname pgf@x\\endcsname=0pt",
	 "\\csname pgf@y\\endcsname=1pt")
   else
      pgfx_normalised = pgfx/math.sqrt(pgfx^2 + pgfy^2)
      pgfx_normalised = pgfx_normalised - pgfx_normalised%0.00001
      pgfy_normalised = pgfy/math.sqrt(pgfx^2 + pgfy^2)
      pgfy_normalised = pgfy_normalised - pgfy_normalised%0.00001
      return tex.print(-1,
	 "\\csname pgf@x\\endcsname=",pgfx_normalised,"pt",
	 "\\csname pgf@y\\endcsname=",pgfy_normalised,"pt")
   end
end
