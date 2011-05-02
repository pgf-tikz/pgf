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

function split_braces_to_explist(s)
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

function split_braces_to_table(s)
   local t = {}
   for i in s:gmatch('%b{}') do
      table.insert(t, tonumber(i:sub(2, -2)))
   end
   return t
end

function mod(x,y)
   if x/y < 0 then
      return -(math.abs(x)%math.abs(y))
   else
      return math.abs(x)%math.abs(y)
   end
end

function Mod(x,y)
   return math.abs(x)%math.abs(y)
end

function factorial(n)
   if n == 0 then
      return 1
   else
      return n * factorial(n-1)
   end
end

function pointnormalised (pgfx, pgfy)
   local pgfx_normalised, pgfx_normalised
   if pgfx == 0. and pgfy == 0. then
      -- Orginal pgf macro gives this result
      tex.dimen['pgf@x'] = "0pt"
      tex.dimen['pgf@y'] = "1pt"
      return nil
   else
      pgfx_normalised = pgfx/math.sqrt(pgfx^2 + pgfy^2)
      pgfx_normalised = pgfx_normalised - pgfx_normalised%0.00001
      pgfy_normalised = pgfy/math.sqrt(pgfx^2 + pgfy^2)
      pgfy_normalised = pgfy_normalised - pgfy_normalised%0.00001
      tex.dimen['pgf@x'] = tostring(pgfx_normalised) .. "pt"
      tex.dimen['pgf@y'] = tostring(pgfy_normalised) .. "pt"
      return nil
   end
end
