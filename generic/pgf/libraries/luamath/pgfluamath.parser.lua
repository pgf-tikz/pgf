-- Copyright 2011 by Christophe Jorssen
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License.
--
-- See the file doc/generic/pgf/licenses/LICENSE for more details.
--
--	$Id$	
--
module("pgfluamath.parser", package.seeall)

local S, P, R = lpeg.S, lpeg.P, lpeg.R
local C, Cc, Ct = lpeg.C, lpeg.Cc, lpeg.Ct
local V = lpeg.V

local space_pattern = S(" \n\r\t")^0

-- All numbers are positive, ie -5 = neg(5). If not, uncomment...
-- local integer_pattern = P("-")^-1 * R("09")^1
local integer_pattern = R("09")^1
local positive_decimal_pattern = (R("09")^1 * P(".") * R("09")^1) +
                                 (P(".") * R("09")^1) +
			         (R("09")^1 * P("."))
-- local decimal_pattern = P("-")^-1 * positive_decimal_pattern
local decimal_pattern = positive_decimal_pattern
local integer = Cc("integer") * C(integer_pattern) * space_pattern
local decimal = Cc("decimal") * C(decimal_pattern) * space_pattern
local float = Cc("float") * C(decimal_pattern) * S("eE") * 
              C(integer_pattern) * space_pattern

local openparen = Cc("openparen")  * C(P("(")) * space_pattern
local closeparen = Cc("closeparen") * C(P(")")) * space_pattern

local addop = Cc("addop") * C(S("+")) * space_pattern
local mulop = Cc("mulop") * C(S("*")) * space_pattern

local grammar = P {
   "E",
   E = Ct(V("T") * (addop * V("T"))^0),
   T = Ct(V("F") * (mulop * V("F"))^0),
   F = Ct(float + decimal + integer + (openparen * V("E") * closeparen)),
}

local parser = space_pattern * grammar * -1

function string_to_expr(str)
   lpeg.match(parser,str)
   return
end

-- Needs DumpObject.lua 
-- (http://lua-users.org/files/wiki_insecure/users/PhiLho/DumpObject.lua)
-- Very useful for debugging.
function showtab (str)
   tex.sprint("\\message\{^^J ********** " .. str .. " ******* ^^J\}")
   tex.sprint("\\message\{" .. 
	      DumpObject(lpeg.match(parser,str),"\\space","^^J") .. "\}")
   return
end
