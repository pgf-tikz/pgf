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
--
-- See http://journal.stuffwithstuff.com/2011/03/19/pratt-parsers-expression-parsing-made-easy/ for precedence with peg grammar

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

local integer_pattern = P("-")^-1 * R("09")^1
local positive_decimal_pattern = (R("09")^1 * P(".") * R("09")^1) +
                                 (P(".") * R("09")^1) +
			         (R("09")^1 * P("."))
local decimal_pattern = P("-")^-1 * positive_decimal_pattern
local integer = Cc("integer") * C(integer_pattern) * space_pattern
local decimal = Cc("decimal") * C(decimal_pattern) * space_pattern
local float = Cc("float") * C(decimal_pattern) * S("eE") * 
              C(integer_pattern) * space_pattern

local openparen = Cc("openparen")  * C(P("(")) * space_pattern
local closeparen = Cc("closeparen") * C(P(")")) * space_pattern

local addop = Cc("addop") * C(S("+-")) * space_pattern
local mulop = Cc("mulop") * C(S("*/")) * space_pattern

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
