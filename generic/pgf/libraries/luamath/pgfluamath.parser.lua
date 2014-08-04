-- Copyright 2011 by Christophe Jorssen and Mark Wibrow
-- Copyright 2014 by Christian Feuersaenger
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License.
--
-- See the file doc/generic/pgf/licenses/LICENSE for more details.
--
-- $Id$	

local pgfluamathparser = pgfluamathparser or {}

pgfluamathfunctions = require("pgfluamath.functions")

-- lpeg is always present in luatex
local lpeg = require("lpeg")

local S, P, R = lpeg.S, lpeg.P, lpeg.R
local C, Cc, Ct = lpeg.C, lpeg.Cc, lpeg.Ct
local Cf, Cg, Cs = lpeg.Cf, lpeg.Cg, lpeg.Cs
local V = lpeg.V
local match = lpeg.match

local space_pattern = S(" \n\r\t")^0
local tex_unit = 
        P('pt') + P('mm') + P('cm') + P('in') + 
        P('ex') + P('em') + P('bp') + P('pc') + 
        P('dd') + P('cc') + P('sp');

local one_digit_pattern = R("09")
local positive_integer_pattern = one_digit_pattern^1
-- FIXME : it might be a better idea to remove '-' from all number_patterns! Instead, rely on the prefix operator 'neg' to implement negative numbers.
-- Is that wise? It is certainly less efficient...
local integer_pattern = S("+-")^-1 * positive_integer_pattern 
-- Valid positive decimals are |xxx.xxx|, |.xxx| and |xxx.|
local positive_integer_or_decimal_pattern = positive_integer_pattern * ( P(".") * one_digit_pattern^0)^-1 + 
                                 (P(".") * one_digit_pattern^1) 
local integer_or_decimal_pattern = S("+-")^-1 * positive_integer_or_decimal_pattern 
local fpu_pattern = R"15" * P"Y" * positive_integer_or_decimal_pattern * P"e" * P("-")^-1 * R("09")^1 * P"]"
local unbounded_pattern = P"inf" + P"INF" + P"nan" + P"NaN" + P"Inf"
local number_pattern = C(unbounded_pattern + fpu_pattern + integer_or_decimal_pattern * (S"eE" * integer_pattern + C(tex_unit))^-1)

local underscore_pattern = P("_")

local letter_pattern = R("az","AZ")
local alphanum__pattern = letter_pattern + one_digit_pattern + underscore_pattern

local identifier_pattern = letter_pattern^1 * alphanum__pattern^0 

local openparen_pattern = P("(") * space_pattern
local closeparen_pattern = P(")")
local opencurlybrace_pattern = P("{")
local closecurlybrace_pattern = P("}")
local openbrace_pattern = P("[")
local closebrace_pattern = P("]")

-- hm. what about '\\' or '\%' ?
-- accept \pgf@x, \count0, \dimen42, \c@pgf@counta, \wd0, \ht0, \dp 0
local controlsequence_pattern = P"\\" * C( (R("az","AZ") + P"@")^1) * space_pattern* C( R"09"^0 )

-- local string = P('"') * C((1 - P('"'))^0) * P('"')

local comma_pattern = P(",") * space_pattern


----------------
local TermOp = C(S("+-")) * space_pattern
local RelationalOp = C( P"==" + P"!=" + P"<=" + P">=" + P"<" + P">" ) * space_pattern
local FactorOp = C(S("*/")) * space_pattern

-- Grammar
local Exp, Term, Factor = V"Exp", V"Term", V"Factor"
local Prefix = V"Prefix"
local Postfix = V"Postfix"



local function eval (v1, op, v2)
  if (op == "+") then return v1 + v2
  elseif (op == "-") then return v1 - v2
  elseif (op == "*") then return v1 * v2
  elseif (op == "/") then return v1 / v2
  else
	error("This function must not be invoked for operator "..op)
  end
end

local pgfStringToFunctionMap = pgfluamathfunctions.stringToFunctionMap
local function function_eval(name, ... )
	local f = pgfStringToFunctionMap[name]
	if not f then
		error("Function '" .. name .. "' is undefined (did not find pgfluamathfunctions."..name .." (looked into pgfluamathfunctions.stringToFunctionMap))")
	end
	-- FIXME: validate signature
	return f(...)
end


local func = 
       (C(identifier_pattern) * space_pattern * openparen_pattern * Exp * (comma_pattern * Exp)^0 * closeparen_pattern) / function_eval;

local functionWithoutArg = identifier_pattern / function_eval

-- this is what can occur as exponent after '^'.
-- I have the impression that the priorities could be implemented in a better way than this... but it seems to work.
local pow_exponent = 
				-- allows 2^-4,  2^1e4, 2^2
				-- FIXME : why not 2^1e2 ?
				Cg(C(integer_or_decimal_pattern) 
				-- 2^pi, 2^multiply(2,2)
				+ Cg(func+functionWithoutArg) 
				-- 2^(2+2)
				+ openparen_pattern * Exp * closeparen_pattern )

local function prefix_eval(op, x)
	if op == "-" then
		return pgfluamathfunctions.neg(x)
	elseif op == "!" then
		return pgfluamathfunctions.notPGF(x)
	else
		error("This function must not be invoked for operator "..op)
	end
end


local prefix_operator = C( S"-!" )
local prefix_operator_pattern = (prefix_operator * space_pattern * Cg(Prefix) ) / prefix_eval

-- apparently, we need to distinghuish between <expr> ! and  <expr> != <expr2>:
local postfix_operator = C( S"r!" - P"!=" )  + C(P"^") * space_pattern * pow_exponent


local ternary_eval = pgfluamathfunctions.ifthenelse

local factorial_eval = pgfluamathfunctions.factorial
local deg = pgfluamathfunctions.deg
local pow_eval = pgfluamathfunctions.pow

-- @param prefix the argument before the postfix operator.
-- @param op either nil or the postfix operator
-- @param arg either nil or the (mandatory) argument for 'op'
local function postfix_eval(prefix, op, arg)
	local result
	if op == nil then
		result = prefix
	elseif op == "r" then
		if arg then error("parser setup error: expected nil argument") end
		result = deg(prefix)
	elseif op == "!" then
		if arg then error("parser setup error: expected nil argument") end
		result = factorial_eval(prefix)
	elseif op == "^" then
		if not arg then error("parser setup error: ^ with its argument") end
		result = pow_eval(prefix, arg)
	else
		error("Parser setup error: " .. tostring(op) .. " unexpected in this context")
	end
	return result
end

local function relational_eval(v1, op, v2)
	local fct
	if (op == "==") then fct = pgfluamathfunctions.equal
	elseif (op == "!=") then fct = pgfluamathfunctions.notequal
	elseif (op == "<") then fct = pgfluamathfunctions.less
	elseif (op == ">") then fct = pgfluamathfunctions.greater
	elseif (op == ">=") then fct = pgfluamathfunctions.notless
	elseif (op == "<=") then fct = pgfluamathfunctions.notgreater
	else
		error("This function must not be invoked for operator "..op)
	end
	return fct(v1,v2)
end

-- @return either the box property or nil
-- @param cs "wd", "ht", or "dp"
-- @param intSuffix some integer
local function get_tex_box(cs, intSuffix)
	-- assume get_tex_box is only called when a dimension is required.
	local result
	pgfluamathparser.units_declared = true
	local box =tex.box[tonumber(intSuffix)]
	if not box then error("There is no box " .. intSuffix) end
	if cs == "wd" then
		result = box.width / 65536
	elseif cs == "ht" then
		result = box.height / 65536
	elseif cs == "dp" then
		result = box.depth / 65536
	else	
		result = nil
	end
	return result
end


local function controlsequence_eval(cs, intSuffix)
	local result
	if intSuffix and #intSuffix >0 then
		if cs == "count" then
			result= pgfluamathparser.get_tex_count(intSuffix)
		elseif cs == "dimen" then
			result= pgfluamathparser.get_tex_dimen(intSuffix)
		else
			result = get_tex_box(cs,intSuffix)
			if not result then
				-- this can happen - we cannot expand \chardef'ed boxes here.
				-- this will be done by the TeX part
				error('I do not know/support the TeX register "\\' .. cs .. '"')
			end
		end
	else
		result = pgfluamathparser.get_tex_register(cs)
	end
	return result
end

pgfluamathparser.units_declared = false
function pgfluamathparser.get_tex_register(register)
    -- register is a string which could be a count or a dimen.    
    if pcall(tex.getcount, register) then
        return tex.count[register]
    elseif pcall(tex.getdimen, register) then
        pgfluamathparser.units_declared = true
        return tex.dimen[register] / 65536 -- return in points.
    else
        error('I do not know the TeX register "' .. register .. '"')
        return nil
    end
    
end

function pgfluamathparser.get_tex_count(count)
    -- count is expected to be a number
    return tex.count[tonumber(count)]
end

function pgfluamathparser.get_tex_dimen(dimen)
    -- dimen is expected to be a number
    pgfluamathparser.units_declared = true
    return tex.dimen[tonumber(dimen)] / 65536
end

function pgfluamathparser.get_tex_sp(dimension)
    -- dimension should be a string
    pgfluamathparser.units_declared = true
    return tex.sp(dimension) / 65536
end


local initialRule = V"initial"

local Summand = V"Summand"
local Relational = V"Relational"
local LogicalOr = V"LogicalOr"
local LogicalAnd = V"LogicalAnd"

local pgftonumber = pgfluamathfunctions.tonumber
local tonumber_withunit = pgfluamathparser.get_tex_sp
local function number_optional_units_eval(x, unit)
	if not unit then
		return pgftonumber(x)
	else
		return tonumber_withunit(x)
	end
end

-- Grammar
--
-- for me: 
-- - use '/' to evaluate all expressions which contain a _constant_ number of captures.
-- - use Cf to evaluate expressions which contain a _dynamic_ number of captures
--
-- see unittest_luamathparser.tex for tons of examples
local G = P{ "initialRule",
	initialRule = space_pattern* Exp * -1;
	-- ternary operator (or chained ternary operators):
	-- FIXME : is this chaining a good idea!?
	Exp = Cf( Relational * Cg(P"?" * space_pattern * Relational * P":" *space_pattern * Relational )^0, ternary_eval) ;
	-- FIXME : do we really allow something like " 1 == 1 != 2" ? I would prefer (1==1) != 2 !?
	Relational = Cf(LogicalOr * Cg(RelationalOp * LogicalOr)^0, relational_eval);
	LogicalOr = Cf(LogicalAnd * (P"||" * space_pattern * LogicalAnd)^0, pgfluamathfunctions.orPGF);
	LogicalAnd = Cf(Summand * (P"&&" * space_pattern * Summand)^0, pgfluamathfunctions.andPGF);
	Summand = Cf(Term * Cg(TermOp * Term)^0, eval) ;
	Term = Cf(Prefix * Cg(FactorOp * Prefix)^0, eval);
	Prefix = prefix_operator_pattern + Postfix;
	-- this calls 'postfix_eval' with nil arguments if it is no postfix operation.. but that does not hurt (right?)
	Postfix = Factor * (postfix_operator * space_pattern)^-1 / postfix_eval;
	Factor = 
		 (
		number_pattern / number_optional_units_eval
		+ func
		+ functionWithoutArg
		+ openparen_pattern * Exp * closeparen_pattern
		+ controlsequence_pattern / controlsequence_eval
		) *space_pattern
	;
}

-- This is the (only fully functional) math parser function in this module.
-- FIXME: cleanup the rest
--
-- @param str a string like "1+1" which is accepted by the PGF math language
-- @return either nil if the string is illegal or the resulting number (or string)
function pgfluamathparser.pgfmathparse(str)
	pgfluamathparser.units_declared = false

	return match(G,str)
end

local pgfmathparse = pgfluamathparser.pgfmathparse
local tostringfixed = pgfluamathfunctions.tostringfixed
local tostringfpu = pgfluamathfunctions.toTeXstring

-- A Utility function which simplifies the interaction with the TeX code
-- @param expression the input expression (string)
-- @param outputFormatChoice 0 if the result should be a fixed point number, 1 if it should be in FPU format
-- @param showErrorMessage (boolean) true if any error should be displayed, false if errors should simply result in an invocation of TeX's parser (the default)
-- 
-- it defines \pgfmathresult and \ifpgfmathunitsdeclared
function pgfluamathparser.texCallParser(expression, outputFormatChoice, showErrorMessage)
	local success, result 
	if showErrorMessage then
		result = pgfmathparse(expression)
		success = true
	else
		success, result = pcall(pgfmathparse, expression)
	end

	if success and result then 
		local result_str
		if outputFormatChoice == 0 then
			-- luamath/output format=fixed
			result_str = tostringfixed(result)
		else
			-- luamath/output format=fixed
			result_str = tostringfpu(result)
		end
		tex.sprint("\\def\\pgfmathresult{" .. result_str .. "}")
		if pgfluamathparser.units_declared then
			tex.sprint("\\pgfmathunitsdeclaredtrue")
		else
			tex.sprint("\\pgfmathunitsdeclaredfalse")
		end
	else
		tex.sprint("\\def\\pgfmathresult{}")
		tex.sprint("\\pgfmathunitsdeclaredfalse")
	end
end

--[[
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

local parser = space_pattern * grammar * -1
--]]

-- Namespaces will be searched in the following order. 
pgfluamathparser.function_namespaces = {
   'pgfluamathfunctions', 'math', '_G'}


function pgfluamathparser.get_tex_box(box, dimension)
   -- assume get_tex_box is only called when a dimension is required.
   pgfluamathparser.units_declared = true
   if dimension == 'width' then
      return tex.box[box].width / 65536 -- return in points.
   elseif dimension == 'height' then
      return tex.box[box].height / 65536
   else
      return tex.box[box].depth / 65536
   end        
end


-- transform named box specification 
-- e.g., \wd\mybox -> pgfluamathparser.get_tex_box["mybox"].width
--
function pgfluamathparser.process_tex_box_named(box) 
   return 'pgfluamathparser.get_tex_box(\\number'  .. box[2] .. ', "' .. box[1] .. '")'
end

-- transform numbered box specification 
-- e.g., \wd0 -> pgfluamathparser.get_tex_box["0"].width
--
function pgfluamathparser.process_tex_box_numbered(box)
    return 'pgfluamathparser.get_tex_box("' .. box[2] .. '", "' .. box[1] .. '")'
end

-- transform a register
-- e.g., \mycount -> pgfluamathparser.get_tex_register["mycount"]
--       \dimen12 -> pgfluamathparser.get_tex_dimen[12]
--
function pgfluamathparser.process_tex_register(register)
    if register[2] == nil then -- a named register
        return 'pgfluamathparser.get_tex_register("' .. register[1]:sub(2, register[1]:len()) .. '")'
    else -- a numbered register
        return 'pgfluamathparser.get_tex_' .. register[1]:sub(2, register[1]:len()) .. '(' .. register[2] .. ')'
    end
end

-- transform a 'multiplier'
-- e.g., 0.5 -> 0.5* (when followed by a box/register)
--
function pgfluamathparser.process_muliplier(multiplier)
    return multiplier .. '*'
end

-- transform an explicit dimension to points
-- e.g., 1cm -> pgfluamathparser.get_tex_sp("1cm")
--
function pgfluamathparser.process_tex_dimension(dimension)
    return 'pgfluamathparser.get_tex_sp("' .. dimension .. '")'
end

-- Check the type and 'namespace' of a function F.
--
-- If F cannot be found as a Lua function or a Lua number in the
-- namespaces in containted in pgfluamathparser.function_namespaces
-- then an error results. 
--
-- if F is a Lua function and isn't followd by () (a requirement of Lua) 
-- then the parentheses are inserted.
--
-- e.g., random -> random() (if random is a function in the _G namespace)
--       pi     -> math.pi  (if pi is a constant that is only in the math namespace)
--
function pgfluamathparser.process_function(function_table) 
    local function_name = function_table[1]
    local char = function_table[2]
    if (char == nil) then
        char = ''
    end
    for _, namespace in pairs(pgfluamathparser.function_namespaces) do
        local function_type = assert(loadstring('return type(' .. namespace .. '.' .. function_name .. ')'))()
        if function_type == 'function' then
            if not (char == '(') then
                char = '()'
            end
            return namespace .. '.' .. function_name .. char
        elseif function_type == 'number' then
            return namespace .. '.' .. function_name .. char            
        end
    end
    pgfluamathparser.error = 'I don\'t know the function or constant \'' .. function_name .. '\''
end


pgfluamathparser.remove_spaces = lpeg.Cs((lpeg.S' \n\t' / '' + 1)^0)
 
 
function pgfluamathparser.evaluate(expression)
    assert(loadstring('pgfluamathparser._result=' .. expression))()
    pgfluamathparser.result = pgfluamathparser._result
end
 
function pgfluamathparser.parse(expression)
   pgfluamathparser.write_to_log("Parsing expression:" .. expression)
   pgfluamathparser.units_declared = false
   
   pgfluamathparser.error = nil
   pgfluamathparser.result = nil    
   
   -- Remove spaces
   expression = pgfluamathparser.remove_spaces:match(expression)

   parsed_expression = 
      pgfluamathparser.transform_operands:match(expression)
   pgfluamathparser.write_to_log("Transformed expression:" 
				   .. parsed_expression) 
end

function pgfluamathparser.eval(expression)
   pgfluamathparser.write_to_log("Evaluating expression:" .. expression)
   pcall(pgfluamathparser.evaluate, expression)
   pgfluamathparser.write_to_log("Result:" .. pgfluamathparser.result)
   if pgfluamathparser.result == nil then
      pgfluamathparser.error = "Sorry, I could not evaluate  '" .. expression .. "'"
      return nil
   else        
      return pgfluamathparser.result
   end
end
 
pgfluamathparser.trace = true

function pgfluamathparser.write_to_log (s)
   if pgfluamathparser.trace then
      texio.write_nl(s)
   end
end

-- NOTE: \pgfmathparse{pi/3.14} will fail giving pgfluamathfunctions.pi()3.14
-- (the / is missing, probably gobbled by one of the captures of the grammar).

pgfluamathparser.transform_operands = P({
    'transform_operands';
    
    one_char = lpeg.P(1),
    lowercase = lpeg.R('az'),
    uppercase = lpeg.R('AZ'),
    numeric = lpeg.R('09'),
    dot = lpeg.P('.'),
    exponent = lpeg.S('eE'),    
    sign_prefix = lpeg.S('-+'),
    begingroup = lpeg.P('('),
    endgroup = lpeg.P(')'),
    backslash = lpeg.P'\\',
    at = lpeg.P'@',
    
    alphabetic = lpeg.V'lowercase' + lpeg.V'uppercase', 
    alphanumeric = lpeg.V'alphabetic' + lpeg.V'numeric',
    
    integer = lpeg.V'numeric'^1,
    real = lpeg.V'numeric'^0 * lpeg.V'dot' * lpeg.V'numeric'^1,
    scientific = (lpeg.V'real' + lpeg.V'integer') * lpeg.V'exponent' * lpeg.V'sign_prefix'^0 * lpeg.V'integer',
    
    number = lpeg.V'scientific' + lpeg.V'real' + lpeg.V'integer',
    function_name = lpeg.V('alphabetic') * lpeg.V('alphanumeric')^0,
    
    tex_cs = lpeg.V'backslash' * (lpeg.V'alphanumeric' + lpeg.V'at')^1,
    tex_box_dimension_primative = lpeg.V'backslash' * (lpeg.P'wd' + lpeg.P'ht' + lpeg.P'dp'),
    tex_register_primative = lpeg.V'backslash' * (lpeg.P'count' + lpeg.P'dimen'),
    
    tex_primative = lpeg.V'tex_box_dimension_primative' + lpeg.V'tex_register_primative',
    tex_macro = -lpeg.V'tex_primative' * lpeg.V'tex_cs',        
    
    tex_unit = 
        lpeg.P('pt') + lpeg.P('mm') + lpeg.P('cm') + lpeg.P('in') + 
        lpeg.P('ex') + lpeg.P('em') + lpeg.P('bp') + lpeg.P('pc') + 
        lpeg.P('dd') + lpeg.P('cc') + lpeg.P('sp'),
        
    tex_register_named = lpeg.C(lpeg.V'tex_macro'),
    tex_register_numbered = lpeg.C(lpeg.V'tex_register_primative') * lpeg.C(lpeg.V'integer'), 
    tex_register_basic = lpeg.Cs(lpeg.Ct(lpeg.V'tex_register_numbered' + lpeg.V'tex_register_named') / pgfluamathparser.process_tex_register),
    
    tex_multiplier = lpeg.Cs((lpeg.V'tex_register_basic' + lpeg.C(lpeg.V'number')) / pgfluamathparser.process_muliplier),    
    
    tex_box_width = lpeg.Cs(lpeg.P('\\wd') / 'width'),
    tex_box_height = lpeg.Cs(lpeg.P('\\ht') / 'height'),
    tex_box_depth = lpeg.Cs(lpeg.P('\\dp') / 'depth'),
    tex_box_dimensions = lpeg.V'tex_box_width' + lpeg.V'tex_box_height' + lpeg.V'tex_box_depth',
    tex_box_named = lpeg.Cs(lpeg.Ct(lpeg.V'tex_box_dimensions' * lpeg.C(lpeg.V'tex_macro')) / pgfluamathparser.process_tex_box_named),
    tex_box_numbered = lpeg.Cs(lpeg.Ct(lpeg.V'tex_box_dimensions' * lpeg.C(lpeg.V'number')) / pgfluamathparser.process_tex_box_numbered),
    tex_box_basic = lpeg.V'tex_box_named' + lpeg.V'tex_box_numbered',
    
    tex_register = lpeg.Cs(lpeg.V'tex_multiplier' * lpeg.V'tex_register_basic') + lpeg.V'tex_register_basic',
    tex_box = lpeg.Cs(lpeg.Cs(lpeg.V'tex_multiplier') * lpeg.V'tex_box_basic') + lpeg.V'tex_box_basic',
    tex_dimension = lpeg.Cs(lpeg.V'number' * lpeg.V'tex_unit' / pgfluamathparser.process_tex_dimension),
    
    tex_operand = lpeg.Cs(lpeg.V'tex_dimension' + lpeg.V'tex_box' + lpeg.V'tex_register'),
    
    function_name = lpeg.V'alphabetic' * (lpeg.V'alphanumeric'^1),
    function_operand = lpeg.Cs(lpeg.Ct(lpeg.C(lpeg.V'function_name') * lpeg.C(lpeg.V'one_char') + lpeg.C(lpeg.V'function_name')) / pgfluamathparser.process_function),
    
    -- order is (always) important!
    operands = lpeg.V'tex_operand' + lpeg.V'number' +  lpeg.V'function_operand',
    
    transform_operands = lpeg.Cs((lpeg.V'operands' + 1)^0)
 })


return pgfluamathparser
--[[ NEW: 2012/02/21, CJ, work in progress
-- We need 3 parsers (or 2, 2 and 3 could be merged)
-- (1) To get the number associated with a (\chardef'ed) box (e.g. 
--     \ht\mybox -> \ht26) 
--     This is part of a TeX ->(\directlua == \edef) -> lua -> (lpeg parser 1)
--     -> TeX -> (\directlua == \edef)
-- (2) To transform math and functions operands
-- (3) To transform units, dimen and count register

-- TODO: strings delimited by "..."
-- TODO: units. \pgfmathparse{12+1cm}\pgfmathresult and \the\dimexpr 12pt+1cm\relax have the same result. Note: \pgfmathparse{(12+1)cm} won't work in plain pgfmath.
-- TODO: Parser 3


pgfluamath = pgfluamath or {}

pgfluamath.debug = true

local lpeg = require('lpeg')
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local C, Cc, Cs = lpeg.C, lpeg.Cc, lpeg.Cs
local Cf, Cg, Ct = lpeg.Cf, lpeg.Cg, lpeg.Ct
local match = lpeg.match

local space = S(' \n\t')

local lowercase = R('az')
local uppercase = R('AZ')
local alphabetic = lowercase + uppercase

local digit = R('09')

local alphanumeric = alphabetic + digit

local dot = P('.')
local exponent = S('eE')
local sign_prefix = S('+-')

local integer = digit^1
local float = (digit^1 * dot * digit^0) + (digit^0 * dot * digit^1)
local scientific = (float + integer) * exponent * sign_prefix^-1 * integer

local number = scientific + float + integer

local at = P('@')

local backslash = P('\\')

local box_width = P('\\wd')
local box_height = P('\\ht')
local box_depth = P('\\dp')
local box_dimension = box_width + box_height + box_depth

local tex_cs = backslash * (alphabetic + at)^1

local lparen = P('(')
local rparen = P(')')

local lbrace = P('{')
local rbrace = P('}')

local lbracket = P('[')
local rbracket = P(']')

local thenop = P('?')
local elseop = P(':')

local orop = P('||')
local andop = P('&&')

local eqop = P('==')
local neqop = P('!=')

local greaterop = P('>')
local lessop = P('<')
local greatereqop = P('>=')
local lesseqop = P('<=')

local addop = P('+')
local subop = P('-')

local mulop = P('*')
local divop = P('/')

local powop = P('^')

local radop = P('r')

local notop = P('!')
local negop = P('-')

local comma = P(',')

function pgfluamath.namedbox_to_numberedbox (s)
   -- Transforms '{\wd|\ht|\dp}\mybox' to '{\wd|\ht|\dp}\number\mybox'
   local function transform (capture) 
      print('Captured ' .. capture) 
      return '\\number' .. capture
   end
   local dimension_of_a_named_box = 
      box_dimension * space^0 * (tex_cs / transform)
   -- P(1) matches exactly one character
   -- V(1) is the entry of the grammar with index 1. It defines the initial rule.
   -- The manual says: 
   -- "If that entry is a string, it is assumed to be the name of the initial rule. 
   -- Otherwise, LPeg assumes that the entry 1 itself is the initial rule."
   local grammar = 
      P({
	   [1] = (dimension_of_a_named_box + P(1)) * V(1) + P(true)
	})
   return print(match(Cs(grammar),s))
end
--[[
namedbox_to_numberedbox('test')
namedbox_to_numberedbox('\\test')
namedbox_to_numberedbox('\\wd\\test0')
namedbox_to_numberedbox('\\wd\\test01')
namedbox_to_numberedbox('\\wd\\test@t 012')
namedbox_to_numberedbox(' \\wd  \\test012')
namedbox_to_numberedbox('\\wd\\test012\\test \\ht\\zozo0')
namedbox_to_numberedbox('\\wd0')
--]]
--[[

-- Grammar (from lowest to highest precedence)
-- Need to adjust to the precedences in plain pgfmath parser
-- IfThenElse Expression
local ITE_E = V('ITE_E')
-- logical OR Expression
local OR_E = V('OR_E')
-- logical AND Expression
local AND_E = V('AND_E')
-- EQuality Expression
local EQ_E = V('EQ_E')
-- Relational EQuality Expression
local REQ_E = V('REQ_E')
-- ADDitive Expression
local ADD_E = V('ADD_E')
-- MULtiplicative Expression
local MUL_E = V('MUL_E')
-- POWer Expression
local POW_E = V('POW_E')
-- POSTfix Expression
local POST_E = V('POST_E')
-- PREfix Expression
local PRE_E = V('PRE_E')
-- ARRAY Expression
local ARRAY_E = V('ARRAY_E')
-- Expression
local E = V('E')

function pgfluamath.transform_math_expr (s, f_patt)
   if pgfluamath.debug then
      texio.write_nl('pgfluamath: parsing expression "' .. s ..'"')
   end
   -- f_patt extends the grammar dynamically at the time of the call to the
   -- parser.
   -- The idea is to have a set of predefined acceptable functions (via e.g.
   -- \pgfmathdeclarefunction)
   if not f_patt then
      -- P(false) is a pattern that always fails
      -- (neutral element for the + operator on patterns)
      f_patt = P(false)
   end
   local function transform_ITE(a, b, c)
      if not b then
	 return a
      else
	 return string.format('pgfluamath.defined_functions.ifthenelse.code(%s,%s,%s)', a, b, c)
      end
   end
   local function transform_binary(a, b, c)
      if not b then
	 return a
      else
	 return string.format('pgfluamath.defined_functions.%s.code(%s,%s)', b, a, c)
      end
   end
   local function transform_postunary(a, b)
      if not b then
	 return a
      else
	 return string.format('pgfluamath.defined_functions.%s.code(%s)', b, a)
      end
   end
   local function transform_preunary(a, b)
      if not b then
	 return a
      else
	 return string.format('pgfluamath.defined_functions.%s.code(%s)', a, b)
      end
   end
   local function transform_array(a, b)
      -- One exception to the mimmic of plain pgfmath. I do not use the equivalent array function to transform the arrays because I don't know how to handle both cases {1,{2,3}[1],4}[1] and {1,{2,3},4}[1][1] with the parser and the array function.
      -- So I convert a pgf array to a lua table. One can access one entry of the table like this ({1,2})[1] (note the parenthesis, ie {1,2}[1] won't work).
      local s
      if not b then
	 s = '{'
      else
	 s = '({'
      end
      for i = 1,#a do
	 -- We change the index to fit with pgfmath plain convention (index starts at 0 while in lua index starts at 1)
	 s = s .. '[' .. tostring(i-1) .. ']=' .. a[i]
	 if i < #a then
	    s = s .. ','
	 end
      end
      if b then
	 s = s .. '})'
	 for i = 1,#b do
	    s = s .. '[' .. b[i] .. ']'
	 end
      else
	 s = s .. '}'
      end
      return s
   end
   local grammar = 
      lpeg.P({
		'ITE_E',
		ITE_E = (OR_E * (thenop * OR_E * elseop * OR_E)^-1) / transform_ITE,
		OR_E = (AND_E * (orop * Cc('orPGF') * AND_E)^-1) / transform_binary,
		AND_E = (EQ_E * (andop * Cc('andPGF') * EQ_E)^-1) / transform_binary,
		EQ_E = (REQ_E * ((eqop * Cc('equal') + neqop * Cc('notequal')) * REQ_E)^-1) / transform_binary,
		REQ_E = (ADD_E * ((lessop * Cc('less') + greaterop * Cc('greater') + lesseqop * Cc('notgreater') + greatereqop * Cc('notless')) * ADD_E)^-1) / transform_binary,
		ADD_E = Cf(MUL_E * Cg((addop * Cc('add') + subop * Cc('substract')) * MUL_E)^0,transform_binary),
		MUL_E = Cf(POW_E * Cg((mulop * Cc('multiply') + divop * Cc('divide')) * POW_E)^0,transform_binary),
		POW_E = Cf(POST_E * Cg(powop * Cc('pow') * POST_E)^0,transform_binary),
		POST_E = (PRE_E * (radop * Cc('rad'))^-1) / transform_postunary,
		PRE_E = ((notop * Cc('notPGF') + negop * Cc('neg'))^-1 * E) / transform_preunary,
		ARRAY_E = (lbrace * Ct(ITE_E * (comma * ITE_E)^0) * rbrace * Ct((lbracket * ITE_E * rbracket)^0)) / transform_array,
		E = ((integer + float)^-1 * tex_cs^1) + f_patt + C(number) + (lparen * ITE_E * rparen) + ARRAY_E + lbrace * ITE_E * rbrace
	     })
   return lpeg.match(Cs(grammar),s)
end

function pgfluamath.ptransform_math_expr(s, f_patt)
   local st = pgfluamath.transform_math_expr(s, f_patt)
   if st ~= nil then
      return texio.write_nl(st)
   end
end

pgfluamath.defined_functions = {}
pgfluamath.defined_functions_pattern = P(false)

function pgfluamath.declare_new_function (name, nargs, code)
   -- nil is true
   -- The function name CANNOT be a lua reserved word (so no 'and' nor 'or')
   if pgfluamath.defined_functions[name] then
      print('Function ' .. name .. ' is already defined. ' ..
	    'I overwrite it!')
   end
   pgfluamath.defined_functions[name] = {['name'] = name, ['nargs'] = nargs, ['code'] = code}
   
   -- TODO
   -- We need a function to dynamically (depending on the number of arguments) define a patten (in order to avoid the long ifcase-type structure).
   local pattern
   if nargs == 0 then
      pattern = P(name) / function (s) return name .. '()' end
   else if nargs == 1 then
	 pattern = ((P(name) * lparen * Cs(ITE_E) * rparen) / function (s) return 'pgfluamath.defined_functions.' .. name .. '.code(' .. s .. ')' end)
      else if nargs == 2 then
	    pattern = (P(name) * lparen * Cs(ITE_E) * comma * Cs(ITE_E) * rparen / function (s1,s2) return 'pgfluamath.defined_functions.' .. name .. 'code(' .. s1 .. ',' .. s2 .. ')' end)
	 else if nargs == 3 then
	       pattern = (P(name) * lparen * Cs(ITE_E) * comma * Cs(ITE_E) * comma * Cs(ITE_E) * rparen / function (s1,s2,s3) return 'pgfluamath.defined_functions.' .. name .. 'code(' .. s1 .. ',' .. s2 .. ',' .. s3 .. ')' end)
	    end
	 end
      end
   end
   -- TODO
   -- This needs to be regenerated every time a new function is added, in conjunction with a sort of the table (see IMPORTANT below)
   pgfluamath.defined_functions_pattern = pgfluamath.defined_functions_pattern + pattern  
end

-- IMPORTANT: for 'function' with *0* argument, the longest string, the first
-- ie declaring pi before pit won't work.
pgfluamath.declare_new_function('pit',0)
pgfluamath.declare_new_function('pi',0)
pgfluamath.declare_new_function('exp',1)
pgfluamath.declare_new_function('toto',1)
pgfluamath.declare_new_function('gauss',2)

pgfluamath.ptransform_math_expr('exp(exp(1+1))',pgfluamath.defined_functions_pattern)

pgfluamath.ptransform_math_expr('1?(2?3:4^5):gauss(6+toto(7),8+9>10?11:12))',pgfluamath.defined_functions_pattern)

pgfluamath.ptransform_math_expr('!(1!=-2)>3?(4+5*6+7?8||9&&10:11):12^13r||14')
pgfluamath.ptransform_math_expr('-1^2\\test\\toto^3')
pgfluamath.ptransform_math_expr('{1,{2+3,4}[1],5}[2]+6')
pgfluamath.ptransform_math_expr('{1,{2+3,4},5}[1][1]')
pgfluamath.ptransform_math_expr('{1,{2,3},4}[1][1]')
pgfluamath.ptransform_math_expr('{1,{2,3}[1],4}[1]')

--Loadstring: If it succeeds in converting the string to a *function*, it returns that function; otherwise, it returns nil and an error message.
toto = loadstring('texio.write_nl(' .. pgfluamath.transform_math_expr('{1,{2,3},4}[1][1]') .. ')')
toto()

-- IMPORTANT NOTE!!
-- local function add (a,b) will fail within loadstring. Needs to be global. loadstring opens a new chunk that does not know the local variables of other chunks.

--toto = loadstring('texio.write_nl(' .. pgfluamath.transform_math_expr('{1,{2,3E-1+7}[1],4}[1]') .. ')')
--toto()

return pgfluamath
--]]
