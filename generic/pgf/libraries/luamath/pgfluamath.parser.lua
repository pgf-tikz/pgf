-- Copyright 2011 by Christophe Jorssen and Mark Wibrow
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

require("pgfluamath.functions")

-- lpeg is always present in luatex
local lpeg = require("lpeg")

local S, P, R = lpeg.S, lpeg.P, lpeg.R
local C, Cc, Ct = lpeg.C, lpeg.Cc, lpeg.Ct
local Cf, Cg, Cs = lpeg.Cf, lpeg.Cg, lpeg.Cs
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

-- **************
-- * Mark's way * 
-- **************

-- Namespaces will be searched in the following order. 
pgfluamathparser.function_namespaces = {
   'pgfluamathfunctions', 'math', '_G'}

pgfluamathparser.units_declared = false

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

function pgfluamathparser.get_tex_register(register)
    -- register is a string which could be a count or a dimen.    
    if pcall(tex.getcount, register) then
        return tex.count[register]
    elseif pcall(tex.getdimen, register) then
        pgfluamathparser.units_declared = true
        return tex.dimen[register] / 65536 -- return in points.
    else
        pgfluamathparser.error = 'I do not know the TeX register "' .. register '"'
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

-- NOTE: \pgfmathparse{pi/3.14} will fail giving pgfluamathfunctions.pi()3.14
-- (the / is missing, probablu gobbled by one of the captures of the grammar).

lpeg = require'lpeg'

pgfluamathparser.transform_operands = lpeg.P{
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
    signed_number = lpeg.V'sign_prefix'^0 * lpeg.V'number',
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
 }
 
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

return pgfluamathparser
