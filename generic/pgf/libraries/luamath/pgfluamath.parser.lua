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

require("pgfluamath.functions")

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
local Cf, Cg = lpeg.Cf, lpeg.Cg
local V = lpeg.V

local space_pattern = S(" \n\r\t")^0

local digit = R("09")
local integer_pattern = P("-")^-1 * digit^1
-- Valid positive decimals are |xxx.xxx|, |.xxx| and |xxx.|
local positive_decimal_pattern = (digit^1 * P(".") * digit^1) +
                                 (P(".") * digit^1) +
			         (digit^1 * P("."))
local decimal_pattern = P("-")^-1 * positive_decimal_pattern
local integer = C(integer_pattern) * space_pattern
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

local openparen = P("(") * space_pattern
local closeparen = P(")") * space_pattern
local param_beg = Cc("param_beg")  * P("(") * space_pattern
local param_end = Cc("param_end") * P(")") * space_pattern
local opencurlybrace = Cc("opencurlybrace")  * P("{") * space_pattern
local closecurlybrace = Cc("closecurlybrace") * P("}") * space_pattern
local openbrace = Cc("openbrace")  * P("[") * space_pattern
local closebrace = Cc("closebrace") * P("]") * space_pattern

local string = Cc("string") * P('"') * C((1 - P('"'))^0) * P('"') *
               space_pattern

local addop = Cc("addop") * P("+") * space_pattern
local subop = Cc("subop") * P("-") * space_pattern
local negop = Cc("negop") * P("-") * space_pattern
local mulop = Cc("mulop") * P("*") * space_pattern
local divop = Cc("divop") * P("/") * space_pattern
local powop = Cc("powop") * P("^") * space_pattern

local orop = Cc("orop") * P("||") * space_pattern
local andop = Cc("andop") * P("&&") * space_pattern

local eqop = Cc("eqop") * P("==") * space_pattern
local neqop = Cc("neqop") * P("!=") * space_pattern

local lessop = Cc("lessop") * P("<") * space_pattern
local greatop = Cc("greatop") * P(">") * space_pattern
local lesseqop = Cc("lesseqop") * P("<=") * space_pattern
local greateqop = Cc("greateqop") * P(">=") * space_pattern

local then_mark = Cc("then") * P("?") * space_pattern
local else_mark = Cc("else") * P(":") * space_pattern
local factorial = Cc("factorial") * P("!") * space_pattern
local not_mark = Cc("not") * P("!") * space_pattern
local radians = Cc("radians") * P("r") * space_pattern

local comma = Cc("comma") * P(",") * space_pattern

function evalternary(v1,op1,v2,op2,v3)
   return pgfluamath.functions.ifthenelse(v1,v2,v3)
end

function evalbinary(v1,op,v2)
   if (op == "addop") then return pgfluamath.functions.add(v1,v2)
   elseif (op == "subop") then return pgfluamath.functions.substract(v1,v2)
   elseif (op == "mulop") then return pgfluamath.functions.multiply(v1,v2)
   elseif (op == "divop") then return pgfluamath.functions.divide(v1,v2)
   elseif (op == "powop") then return pgfluamath.functions.pow(v1,v2)
   elseif (op == "orop") then return pgfluamath.functions.orPGF(v1,v2)
   elseif (op == "andop") then return pgfluamath.functions.andPGF(v1,v2)
   elseif (op == "eqop") then return pgfluamath.functions.equal(v1,v2)
   elseif (op == "neqop") then return pgfluamath.functions.notequal(v1,v2)
   elseif (op == "lessop") then return pgfluamath.functions.less(v1,v2)
   elseif (op == "greatop") then return pgfluamath.functions.greater(v1,v2)
   elseif (op == "lesseqop") then return pgfluamath.functions.notgreater(v1,v2)
   elseif (op == "greateqop") then return pgfluamath.functions.notless(v1,v2)
   end
end

function evalprefixunary(op,v)
   if (op == "negop") then return pgfluamath.functions.neg(v)
   elseif (op == "notmark") then return pgfluamath.functions.notPGF(v)
   end
end

function evalpostfixunary(v,op)
   if (op == "radians") then return pgfluamath.functions.deg(v)
   elseif (op == "factorial") then return pgfluamath.functions.factorial(v)
   end
end


local grammar = P {
   -- "E" stands for expression
   "ternary_logical_E",
   ternary_logical_E = Cf(V("logical_or_E") * 
       Cg( then_mark * V("logical_or_E") * else_mark * V("logical_or_E"))^0,evalternary);
   logical_or_E = Cf(V("logical_and_E") * Cg(orop * V("logical_and_E"))^0,evalbinary);
   logical_and_E = Cf(V("equality_E") * Cg(andop * V("equality_E"))^0,evalbinary);
   equality_E = Cf(V("relational_E") * 
		Cg((eqop * V("relational_E")) + (neqop * V("relational_E")))^0,evalbinary);
   relational_E = Cf(V("additive_E") * Cg((lessop * V("additive_E")) +
				     (greatop * V("additive_E")) +
				  (lesseqop * V("additive_E")) +
			       (greateqop * V("additive_E")))^0,evalbinary);
   additive_E = Cf(V("multiplicative_E") * Cg((addop * V("multiplicative_E")) + 
					 (subop * V("multiplicative_E")))^0,evalbinary);
   multiplicative_E = Cf(V("power_E") * Cg((mulop * V("power_E")) + 
				      divop * V("power_E"))^0,evalbinary);
   power_E = Cf(V("postfix_unary_E") * Cg(powop * V("postfix_unary_E"))^0,evalbinary);
   postfix_unary_E = Cf(V("prefix_unary_E") * Cg(radians + factorial)^0,evalpostfixunary);
   prefix_unary_E = Cf(Cg(not_mark + negop)^0 * V("E"),evalprefixunary),
   E = string + float + decimal + integer / tonumber + 
      (openparen * V("ternary_logical_E") * closeparen) +
      (func * param_beg * V("ternary_logical_E") * 
       (comma * V("ternary_logical_E"))^0 * param_end);
}
--]]

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

function parseandeval(str)
   return lpeg.match(parser,str)
end