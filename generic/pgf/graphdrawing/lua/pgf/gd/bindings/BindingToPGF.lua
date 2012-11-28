-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


---
-- This class binds the graph drawing system to
-- \pgfname/\tikzname\ display system by overriding (that is,
-- implementing) the methods of the |Binding| class. 
--

local BindingToPGF = {}
BindingToPGF.__index = BindingToPGF
setmetatable(BindingToPGF, require "pgf.gd.bindings.Binding") -- subclass of Binding


-- Namespace
require("pgf.gd.bindings").BindingToPGF = BindingToPGF

-- Imports
local lib = require "pgf.gd.lib"


-- The implementation

-- Forward
local table_in_pgf_syntax

function BindingToPGF:__tostring()
  return "BindingToPGF"
end


-- Scope handling

function BindingToPGF:resumeGraphDrawingCoroutine(text)
  tex.print(text)
  tex.print("\\directlua{pgf.gd.interface.InterfaceToDisplay.resumeGraphDrawingCoroutine()}")
end


-- Declarations

function BindingToPGF:declareAlgorithmCallback(t)
  tex.print("\\pgfgdcallbackdeclarealgorithm{" .. t.key .. "}{" .. t.phase .. "}")
end

function BindingToPGF:declareParameterCallback(t)
  tex.print("\\pgfgdcallbackdeclareparameter{" .. t.key .. "}{"
	    .. t.type .. "}{" .. tostring(t.default or "") .. "}")
end

function BindingToPGF:declareParameterSequenceCallback(t)
  tex.print("\\pgfgdcallbackdeclareparametersequence{" .. t.key
	    .. "}{" .. table_in_pgf_syntax(t) .. "}{" .. (t.default or "") .. "}")
end

function BindingToPGF:declareCollectionKind(t)
  tex.print("\\pgfgdcallbackdeclarecollectionkind{" .. t.key .. "}")
end

-- Rendering


function BindingToPGF:renderStart()
  tex.print("\\pgfgdcallbackbeginshipout")
end

function BindingToPGF:renderStop()
  tex.print("\\pgfgdcallbackendshipout")
end


-- Rendering collections

function BindingToPGF:renderCollection(collection)
  tex.print("\\pgfgdcallbackrendercollection{".. collection.kind .. "}{"
	    .. table_in_pgf_syntax(collection.generated_options) .. "}")
end

function BindingToPGF:renderCollectionStartKind(kind, layer)
  tex.print("\\pgfgdcallbackrendercollectionkindstart{" .. kind .. "}{" .. tostring(layer) .. "}")
end

function BindingToPGF:renderCollectionStopKind(kind, layer)
  tex.print("\\pgfgdcallbackrendercollectionkindstop{" .. kind .. "}{" .. tostring(layer) .. "}")
end


-- Managing vertices (pgf nodes)

local boxes = {}
local box_count = 0

function BindingToPGF:everyVertexCreation(v)
  local info = v.storage[self]
  
  -- Save the box!
  box_count = box_count + 1
  boxes[box_count] = node.copy_list(tex.box[info.tex_box_number])
  
  -- Special tex stuff, should not be considered by gd algorithm
  info.box_count = box_count
end

function BindingToPGF:renderVertex(v)
  local info = assert(v.storage[self], "thou shalt not modify the syntactic digraph")
  tex.print(
    string.format(
      "\\pgfgdcallbackrendernode{%s}{%fpt}{%fpt}{%fpt}{%fpt}{%s}{%s}{%s}",
      'not yet positionedPGFINTERNAL' .. v.name,
      info.x_min,
      info.x_max,
      info.y_min,
      info.y_max,
      v.pos.x,
      v.pos.y,
      info.box_count))
end

function BindingToPGF:retrieveBox(index, box_num)
  tex.box[box_num] = assert(boxes[index], "no box stored at given index")
  boxes[index] = nil -- remove from memory
end

function BindingToPGF:renderVerticesStart()
  tex.print("\\pgfgdcallbackbeginnodeshipout")
end

function BindingToPGF:renderVerticesStop()
  tex.print("\\pgfgdcallbackendnodeshipout")
end


-- Managing edges

function BindingToPGF:renderEdge(e)
  local info = assert(e.storage[self], "thou shalt not modify the syntactic digraph")
  
  local function get_anchor(e, anchor)
    local a = e.options[anchor]
    if a and a ~= "" then
      return "." .. a
    else
      return ""
    end
  end
  
  local callback = {
    '\\pgfgdcallbackedge',
    '{', e.tail.name .. get_anchor(e, "tail anchor"), '}',
    '{', e.head.name .. get_anchor(e, "head anchor"), '}',
    '{', e.direction,  '}',
    '{', info.pgf_options or "",  '}',
    '{', info.pgf_edge_nodes or "", '}',
    '{', table_in_pgf_syntax(e.generated_options), '}',
    '{'
  }
  
  local path_ends_with_curveto = false
  
  for i=1,#e.path do
    local c = e.path[i]
    
    if type(c) == "table" then
      callback [#callback + 1] = '--(' .. tostring(c.x + e.tail.pos.x) .. 'pt,' .. tostring(c.y + e.tail.pos.y) .. 'pt)'
    elseif c == "moveto" then
      i = i + 1
      local d = e.path[i]
      callback [#callback + 1] = '(' .. tostring(d.x + e.tail.pos.x) .. 'pt,' .. tostring(d.y + e.tail.pos.y) .. 'pt)'
    elseif c == "closepath" then
      callback [#callback + 1] = '--cycle'
    elseif c == "curveto" then
      local d1, d2, d3 = e.path[i+1], e.path[i+2], e.path[i+3]
      i = i + 3
      callback [#callback + 1] = '..controls(' .. tostring(d1.x + e.tail.pos.x) .. 'pt,' .. tostring(d1.y + e.tail.pos.y) .. 'pt)and('
                                               .. tostring(d2.x + e.tail.pos.x) .. 'pt,' .. tostring(d2.y + e.tail.pos.y) .. 'pt)..'
      if d3 then
	callback [#callback + 1] = '(' .. tostring(d3.x + e.tail.pos.x) .. 'pt,' .. tostring(d3.y + e.tail.pos.y) .. 'pt)'
      else
	path_ends_with_curveto = true
      end
    else				     
      error("illegal operation in edge path")
    end
  end

  if path_ends_with_curveto then
    callback [#callback + 1] = "}"
  else
    callback [#callback + 1] = '--}'
  end
  
  -- hand TikZ code over to TeX
  tex.print(table.concat(callback))
end
      
      
function BindingToPGF:renderEdgesStart()
  tex.print("\\pgfgdcallbackbeginedgeshipout")
end

function BindingToPGF:renderEdgesStop()
  tex.print("\\pgfgdcallbackendedgeshipout")
end


-- Vertex creation

function BindingToPGF:createVertex(init)
  -- Now, go back to TeX...
 coroutine.yield(
   table.concat({
      "\\pgfgdcallbackcreatevertex{", init.name, "}",
      "{", init.shape, "}",
      "{", table_in_pgf_syntax(init.generated_options), ",", init.pgf_options or "", "}",
      "{", (init.text or ""), "}"
    }))
  -- ... and come back with a new node!
end



-- Local helpers

function table_in_pgf_syntax (t, prefix)
  prefix = prefix or "/graph drawing/"
  return table.concat( lib.imap( t, function(table)
	   if table.value then
	     return prefix .. table.key .. "={" .. tostring(table.value) .. "}"
	   else
	     return prefix .. table.key
	   end
	 end), ",")
end



return BindingToPGF