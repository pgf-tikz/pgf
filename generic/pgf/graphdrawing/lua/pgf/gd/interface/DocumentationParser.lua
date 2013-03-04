-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



---
-- This class provides documentation parsers for external
-- documentation of keys. The idea is that the documentation of keys
-- is stored in keys, but will (and should) be read only on
-- demand. For this purpose, a key can set the field
-- |documentation_at| to a (Lua) filename that, when called, will
-- return a string describing one or more keys. This documentation
-- will be written into fields like |documentation| or |examples| only
-- when these fields are actually accessed.
--
-- Apart from saving space and compilation time, this approach also
-- makes it easier to separate the documentation of keys from the
-- code, which is escpecially useful in conjunction with C code.

local DocumentationParser = {}

-- Namespace
require("pgf.gd.interface").DocumentationParser = DocumentationParser


-- Imports
local InterfaceCore      = require "pgf.gd.interface.InterfaceCore"




---
-- The default parser for documentation. It works as follows:
--
-- The text is separated into parts, each part describes one key. Each
-- part begins with a line starting with three minus signs, followed by
-- |Documentation of:|, followed by the name of a key.
--
-- Inside each part, if the first line starts with
-- at least two minus signs, it is ignored.
-- In the rest of the part, when a line starts with |Summary:|,
-- everything following on that line and on all following lines up to
-- the first empty line becomes part of the |summary| field of the
-- key. When a line starts with |Example:|, everything following up to
-- the end of the part or up to the next line starting with |Example:|
-- is added to the |examples| field of the key.
--
-- Here is a typical example of how a documentation might look like:
--\begin{codeexample}[code only]
-- --------------------------------
-- Documentation of: SugiyamaLayout 
-- --------------------------------
--
-- Summary: The OGDF implementation of the Sugiyama algorithm.
--
-- This layout represents a customizable
-- implementation of Sugiyama's layout algorithm.
-- The implementation used in |SugiyamaLayout| is based on the
-- following publications:
--
-- \begin{itemize}
-- \item ...
-- \end{itemize}
--
-- Example:
-- \tikz \graph [SugiyamaLayout] { a -- {b,c,d} -- e -- a };
--
-- Example:
-- \tikz \graph [SugiyamaLayout, grow=right]
-- { a -- {b,c,d} -- e -- a };
--
-- -------------------------------------
-- Documentation of: SugiyamaLayout.runs
-- -------------------------------------
--
-- Summary: Determines, how many times the crossing minimization is
-- repeated. 
--
-- Each repetition (except for the first) starts with
-- randomly permuted nodes on each layer. Deterministic behaviour can
-- be achieved by setting |SugiyamaLayout.runs| to 1.
--\end{codeexample}

local function default_parser (string)
  local keys = {}
  local current_key = {}
  local current_doc = {}
  local current_summary = {}
  local current_examples = {}
  local current_example = {}
  local mode = "nothing"
  
  local function finish_doc ()
    if #current_doc>0 then
      local doc = table.concat(current_doc)
      if not doc:match("^[%s\n\r]*$") then
	current_key.documentation = doc
      end
      current_doc = {}
    end
  end

  local function finish_summary ()
    if #current_summary > 0 then
      local doc = table.concat(current_summary)
      if not doc:match("^[%s\n\r]*$") then
	current_key.summary = doc
      end
      current_summary = {}
    end
  end

  local function finish_example ()
    if #current_example > 0 then
      local e = table.concat(current_example)
      current_example = {}
      if not e:match("^[%s\n\r]*$") then
	current_examples[#current_examples+1] = e
      end
    end
  end
  
  local function finish_examples ()
    if #current_examples > 0  then
      current_key.examples = current_examples
      current_examples = {}
    end
  end
    
  for line in string:gmatch("(.-\r?\n)") do
    if mode == "first" and line:match("^--") then
      mode = "doc"   -- do nothing
    else
      -- does it start a key?
      local start = line:match("^---")
      if line:match("^---") then 
	finish_doc()
	finish_summary()
	finish_example()
	finish_examples()
	if current_key.key then
	  keys [#keys + 1] = current_key
	end
	current_key = { }
	mode = "start"
      else
	local summary = line:match("^%s*Summary:%s*(.*\r?\n)$")
	if summary then
	  mode = "summary"
	  current_summary[#current_summary + 1] = summary
	else
	  local example = line:match("^%s*Example:%s*(.*\r?\n)$")
	  if example then
	    mode = "example"
	    finish_example()
	    current_example = { example }
	  else
	    
	    -- Depending on the mode, add appropriately:
	    if mode == "start" then
	      current_key.key =  assert(line:match("^%s*Documentation of:%s*(.-)%s*\r?\n$"), "'Documentation of:' expected")
	      mode = "first"
	    elseif mode == "summary" then
	      if line:match("^%s*\r?\n$") then
		mode = "doc"
	      else
		current_summary[#current_summary + 1] = line
	      end
	    elseif mode == "example" then
	      current_example[#current_example + 1] = line
	    else
	      current_doc [#current_doc + 1] = line
	    end
	    
	  end
	end
      end
    end
  end
  
  finish_doc()
  finish_summary()
  finish_example()
  finish_examples()
  if current_key.key then
    keys [#keys + 1] = current_key
  end

  return keys
end


---
-- A table of formats. When a documentation string is parsed, we first
-- have to determine the format in which the documentation is
-- provided. For this, we iterate over the entries of this array in
-- reverse order (so, starting with the last entyr). Each entry must
-- have a |test| function, which gets the string as input and should
-- return |true| if the format is the one handled by this array
-- entry. If so, the |parse| function in this table will be called,
-- which should return an array of tables, each having at least a
-- |key| entry. Theses tables will then be used to update the keys
-- already installed.

DocumentationParser.formats = {
  {
    test = function (string) return true end, -- this is the fallback
    parse = default_parser
  }
}


---
-- Parse a string. This function will use
-- |DocumentationParser.formats| to determine the format of the string
-- given as input. It will then update the documentation of all
-- keys present in the string.
--
-- @param string A documentation string

function DocumentationParser.parse(string)
  local keys
  local formats = DocumentationParser.formats
  for i=#formats,1,-1 do
    if formats[i].test (string) == true then
      keys = formats[i].parse (string)
      break
    end
  end
  
  for _,entry in ipairs (keys) do
    local key = assert(InterfaceCore.keys[entry.key], "trying to document unknown key")
    if not rawget(key, "summary") then
      key.summary = entry.summary
    end
    if not rawget(key, "documentation") then
      key.documentation = entry.documentation
    end
    if not rawget(key, "examples") then
      key.examples = entry.examples
    end
  end
end



-- Done 

return DocumentationParser