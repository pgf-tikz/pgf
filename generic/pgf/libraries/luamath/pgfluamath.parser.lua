-- Copyright 2011 by Christophe Jorssen
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License.
--
-- See the file doc/generic/pgf/licenses/LICENSE for more details.
--
-- $Id$	

module("pgfluamath.parser", package.seeall)

-- From pgfmathparser.code.tex
local operator_table = {
   [1] = {
      symbol = "+",
      name = "add",
      arity = 2,
      fixity = "infix",
      precedence = 500},
   [2] = {
      symbol = "-",
      name = "substract",
      arity = 2,
      fixity = "infix",
      precedence = 500},
   [3] = {
      symbol = "*",
      name = "multiply",
      arity = 2,
      fixity = "infix",
      precedence = 700},
   [4] = {
      symbol = "/",
      name = "divide",
      arity = 2,
      fixity = "infix",
      precedence = 700},
   [5] = {
      symbol = "^",
      name = "pow",
      arity = 2,
      fixity = "infix",
      precedence = 900},
   [6] = {
      symbol = ">",
      name = "greater",
      arity = 2,
      fixity = "infix",
      precedence = 250},
   [7] = {
      symbol = "<",
      name = "less",
      arity = 2,
      fixity = "infix",
      precedence = 250},
   [8] = {
      symbol = "==",
      name = "equal",
      arity = 2,
      fixity = "infix",
      precedence = 250},
   [9] = {
      symbol = ">=",
      name = "notless",
      arity = 2,
      fixity = "infix",
      precedence = 250},
   [10] = {
      symbol = "<=",
      name = "notgreater",
      arity = 2,
      fixity = "infix",
      precedence = 250},
   [11] = {
      symbol = "&&",
      name = "and",
      arity = 2,
      fixity = "infix",
      precedence = 200},
   [12] = {
      symbol = "||",
      name = "or",
      arity = 2,
      fixity = "infix",
      precedence = 200},
   [13] = {
      symbol = "!=",
      name = "notequalto",
      arity = 2,
      fixity = "infix",
      precedence = 250},
   [14] = {
      symbol = "!",
      name = "not",
      arity = 1,
      fixity = "prefix",
      precedence = 975},
   [15] = {
      symbol = "?",
      name = "ifthenelse",
      arity = 3,
      fixity = "infix",
      precedence = 100},
   [16] = {
      symbol = ":",
      name = "@@collect",
      arity = 2,
      fixity = "infix",
      precedence = 101},
   [17] = {
      symbol = "!",
      name = "factorial",
      arity = 1,
      fixity = "postfix",
      precedence = 800},
   [18] = {
      symbol = "r",
      name = "deg",
      arity = 1,
      fixity = "postfix",
      precedence = 600},
}

--[[ Dont't think those are needed?
\pgfmathdeclareoperator{,}{@collect}   {2}{infix}  {10}
\pgfmathdeclareoperator{[}{@startindex}{2}{prefix} {7}
\pgfmathdeclareoperator{]}{@endindex}  {0}{postfix}{6}
\pgfmathdeclareoperator{(}{@startgroup}{1}{prefix} {5}
\pgfmathdeclareoperator{)}{@endgroup}  {0}{postfix}{4}
\pgfmathdeclareoperator{\pgfmath@bgroup}{@startarray}{1}{prefix} {3}
\pgfmathdeclareoperator{\pgfmath@egroup}{@endarray}  {1}{postfix}{2}% 
\pgfmathdeclareoperator{"}{}{1}{prefix}{1} --"
\pgfmathdeclareoperator{@}{}{0}{postfix}{0}
--]]

local S, P, R = lpeg.S, lpeg.P, lpeg.R
local C, Cc, Ct = lpeg.C, lpeg.Cc, lpeg.Ct
local V = lpeg.V

local space_pattern = S(" \n\r\t")^0

local digit = R("09")
local integer_pattern = P("-")^-1 * digit^1
-- Valid positive decimals are |xxx.xxx|, |.xxx| and |xxx.|
local positive_decimal_pattern = (digit^1 * P(".") * digit^1) +
                                 (P(".") * digit^1) +
			         (digit^1 * P("."))
local decimal_pattern = P("-")^-1 * positive_decimal_pattern
local integer = Cc("integer") * C(integer_pattern) * space_pattern
local decimal = Cc("decimal") * C(decimal_pattern) * space_pattern
local float = Cc("float") * C(decimal_pattern) * S("eE") * 
              C(integer_pattern) * space_pattern

local lower_letter = R("az")
local upper_letter = R("AZ")
local letter = lower_letter + upper_letter
local alphanum = letter + digit
local alphanum_ = alphanum + S("_")
local alpha_ = letter + S("_")
-- TODO: Something like _1 should *not* be allowed as a function name
local func_pattern = alpha_ * alphanum_^0
local func = Cc("function") * C(func_pattern) * space_pattern

local openparen = Cc("openparen")  * C(P("(")) * space_pattern
local closeparen = Cc("closeparen") * C(P(")")) * space_pattern
local opencurlybrace = Cc("opencurlybrace")  * C(P("{")) * space_pattern
local closecurlybrace = Cc("closecurlybrace") * C(P("}")) * space_pattern
local openbrace = Cc("openbrace")  * C(P("[")) * space_pattern
local closebrace = Cc("closebrace") * C(P("]")) * space_pattern

local string = Cc("string") * C(P('"')) * C((1 - P('"'))^0) * C(P('"')) *
               space_pattern

local addop = Cc("addop") * C(P("+")) * space_pattern
local subop = Cc("subop") * C(P("-")) * space_pattern
local mulop = Cc("mulop") * C(P("*")) * space_pattern
local divop = Cc("divop") * C(P("/")) * space_pattern
local powop = Cc("powop") * C(S("^")) * space_pattern

local orop = Cc("orop") * C(P("||")) * space_pattern
local andop = Cc("andop") * C(P("&&")) * space_pattern

local eqop = Cc("eqop") * C(P("==")) * space_pattern
local neqop = Cc("neqop") * C(P("!=")) * space_pattern

local lessop = Cc("lessop") * C(P("<")) * space_pattern
local greatop = Cc("greatop") * C(P(">")) * space_pattern
local lesseqop = Cc("lesseqop") * C(P("<=")) * space_pattern
local greateqop = Cc("greateqop") * C(P(">=")) * space_pattern

local colon = Cc("colon") * C(P(":")) * space_pattern
local question_mark = Cc("question mark") * C(P("?")) * space_pattern
local exclamation_mark = Cc("exclamation mark") * C(P("!")) * space_pattern
local radians = Cc("radians") * C(P("r")) * space_pattern

local comma = Cc("comma") * C(P(",")) * space_pattern

local grammar = P {
   "E",
   E = Ct(V("T") * ((addop * V("T")) + (subop * V("T")))^0),
   T = Ct(V("F") * ((mulop * V("F")) + (divop * V("F")))^0),
   F = Ct(string + float + decimal + integer
   + (openparen * V("E") * closeparen))
   + (func * openparen * V("E") * closeparen),
}


local grammar2 = P {
   "logical_or_E",
   logical_or_E = Ct(V("logical_and_E") * (orop * V("logical_and_E"))^0),
   logical_and_E = Ct(V("equality_E") * (andop * V("equality_E"))^0),
   equality_E = Ct(V("relational_E") * 
		((eqop * V("relational_E")) + (neqop * V("relational_E")))^0),
   relational_E = Ct(V("additive_E") * ((lessop * V("additive_E")) +
				     (greatop * V("additive_E")) +
				  (lesseqop * V("additive_E")) +
			       (greateqop * V("additive_E")))^0),
   additive_E = Ct(V("multiplicative_E") * ((addop * V("multiplicative_E")) + 
					 (subop * V("multiplicative_E")))^0),
   multiplicative_E = Ct(V("power_E") * ((mulop * V("power_E")) + 
				      divop * V("power_E"))^0),
   power_E = Ct(V("E") * (powop * V("E"))^0),
   E = float + decimal + integer + (openparen * V("logical_or_E") * closeparen),
}
--]]

local parser = space_pattern * grammar * -1
local parser2 = space_pattern * grammar2 * -1

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

function showtab2 (str)
   tex.sprint("\\message\{^^J ********** " .. str .. " ******* ^^J\}")
   tex.sprint("\\message\{" .. 
	      DumpObject(lpeg.match(parser2,str),"\\space","^^J") .. "\}")
   return
end
