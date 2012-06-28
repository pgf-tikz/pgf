-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
-- Copyright 2011 by Jannis Pohlmann
-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The TeXInterface class is a singleton object.
-- Its methods define the interface between the TeX layer and the Lua layer;
-- all calls from the TeX layer will be directed to this object.

local TeXInterface = {
  scopes = {},
  parameter_defaults = {},
  tex_boxes = {},
  collection_kinds = {}
}

-- Namespace
require("pgf.gd.control").TeXInterface = TeXInterface

-- Imports
local LayoutPipeline = require "pgf.gd.control.LayoutPipeline"
local Options        = require "pgf.gd.control.Options"

local Vertex     = require "pgf.gd.model.Vertex"
local Digraph    = require "pgf.gd.model.Digraph"
local Coordinate = require "pgf.gd.model.Coordinate"

local Storage    = require "pgf.gd.lib.Storage"
local Event      = require "pgf.gd.lib.Event"






--- Start a graph drawing scope.
--
-- The options string consisting of |{key}{value}| pairs is parsed and 
-- assigned to the graph. These options are used to configure the different
-- graph drawing algorithms shipped with \tikzname.
--
-- @see endScope
--
-- @param options A string containing |{key}{value}| pairs of 
--                \tikzname\ options.
--
function TeXInterface.beginGraphDrawingScope(options)

  -- Create a new scope table
  local scope = {
    syntactic_digraph = Digraph.new { options = Options.new(options), syntactic_digraph = "self" },
    events            = {},
    node_names        = {},
    storage           = Storage.new(),
    coroutine         = nil,
    interface         = TeXInterface
  }
  
  scope.syntactic_digraph.scope   = scope
  
  -- Push scope:
  TeXInterface.scopes[#TeXInterface.scopes + 1] = scope
  
end


--- Returns the top scope
--
-- @return The current top scope, which is the scope in which
--         everything should happen right now.

function TeXInterface.topScope()
  return assert(TeXInterface.scopes[#TeXInterface.scopes], "no graph drawing scope open")
end



local magic_prefix_length = string.len("not yet positionedPGFINTERNAL") + 1


---
-- Add a new node from the pgf-layer to the syntactic graph.
--
-- This function is called for each node of the graph by the \TeX\
-- layer. The \meta{name} is the name of the node including the
-- internal prefix added by the \TeX\ layer to indicate that the node
-- ``does not yet exist.'' The parameters \meta{x_min} to \meta{y_max}
-- specify a bounding box around the node; note that the origin lies
-- at the anchor postion of the node. The \meta{options} are a table
-- of options that will be stored internally (it will not be
-- copied). Graph drawing algorithms may use these options to treat  
-- the node in special ways. The \meta{lateSetup} is \TeX\ code that
-- just needs to be passed back when the node is finally
-- positioned. It is used to add ``decorations'' to a node after
-- positioning like a label.
--
-- @param box       Box register holding the node.
-- @param name      Name of the node.
-- @param shape     The pgf shape of the node (e.g. "circle" or "rectangle")
-- @param x_min     Minimum x point of the bouding box.
-- @param y_min     Minimum y point of the bouding box.
-- @param x_max     Maximum x point of the bouding box.
-- @param y_max     Maximum y point of the bouding box.
-- @param options   Lua-Options for the node.
-- @param lateSetup Options for the node.
--
function TeXInterface.addPgfNode(box, texname, shape, x_min, y_min, x_max, y_max, options, late_setup)
  local scope = TeXInterface.topScope()
  local name  = texname:sub(magic_prefix_length)

  -- Store tex box in internal table
  TeXInterface.tex_boxes[#TeXInterface.tex_boxes + 1] = node.copy_list(tex.box[box])

  -- Create new node
  local v = Vertex.new { 

    -- Standard stuff
    name  = name,
    shape = shape,
    kind  = "node",
    hull  = { Coordinate.new(x_min, y_min), Coordinate.new(x_min, y_max), 
	      Coordinate.new(x_max, y_max), Coordinate.new(x_max,y_min) },
    hull_center = Coordinate.new((x_min + x_max)/2, (y_min+y_max)/2),
    
    -- Event numbering
    event_index = #scope.events + 1,

    -- Local options
    options = Options.new(options),
      
    -- Special tex stuff, should not be considered by gd algorithm
    tex = {
      x_min = x_min,
      y_min = y_min,
      x_max = x_max,
      y_max = y_max,
      stored_tex_box_number = #TeXInterface.tex_boxes, 
      late_setup = late_setup,
    },
  }

  -- Create name lookup
  assert (scope.node_names[name] == nil, "node already present in graph")
  scope.node_names[name] = v

  -- Register event
  scope.events[#scope.events + 1] = Event.new { 
    kind = 'node', 
    parameters = v
  }

  -- Add node to graph
  scope.syntactic_digraph:add {v}

end


--- Sets options for an already existing node
--
-- This function allows you to change the options of a node that already exists. 
--
-- @param name      Name of the node.
-- @param options   Lua-Options for the node.

function TeXInterface.setLateNodeOptions(name, options)
  local scope = TeXInterface.topScope()
  local node = assert(scope.node_names[name], "node is missing, cannot set late options")
  
  Options.add(node.options, options)  
end



---
-- Declare a new collection kind. 
--
-- @param kind A string that specifies a collection kind.
-- @param layer A layer. Kinds are rendered in the order of the
-- layers, where kinds with a negative layer number get rendered
-- behind all nodes and edge and kinds with a positive layer
-- number get rendered before all ndoes and edges. Layer 0 collections
-- do not get rendered. 

function TeXInterface.addCollectionKind(kind, layer)
  
  local kinds = TeXInterface.collection_kinds
  
  -- Search for position:
  local found
  for i=1,#kinds do
    if kinds[i].layer > layer or (
      kinds[i].layer == layer and kinds[i].kind > kind) then
      found = i
      break
    end
  end

  if found and kinds[found].kind == kind then
    -- replace
    kinds[found].layer = layer
  else
    table.insert(kinds, found or #kinds+1, { kind = kind, layer = layer })
  end
end




---
-- Convert a table into a node property table.
--
-- The input is a table whose keys are either node names or
-- numbers. It will be converted to a table whose keys are vertices (with
-- the same values). For a key that is a number, the vertex with this
-- number will be used as the key.
--
-- @param t Table whose keys are names and numbers
-- @return Table whose keys are vertices

function TeXInterface.convertNameKeysToVertexKeys(t)
  local scope = TeXInterface.topScope()
  local vertices = scope.syntactic_digraph.vertices
  local names    = scope.node_names
  
  local new = {}
  for k,v in pairs(t) do
    if type(k) == "number" then
      new [assert(vertices[k], "node index out of bounds")] = v
    else
      new [assert(names[k], "unknown node name")]    = v
    end
  end
  return new  
end







---
-- Adds a syntactic edge from one node to another by name.  
--
-- Both parameters are node names and have to exist before an edge can be
-- created between them.
--
-- @see addNode
--
-- @param from           Name of the node the edge begins at.
-- @param to             Name of the node the edge ends at.
-- @param direction      Direction of the edge (e.g. |--| for an undirected edge 
--                       or |->| for a directed edge from the first to the second 
--                       node).
-- @param options        A table of options for the edge that are relevant to graph drawing algorithms.
-- @param pgf_options    A string that should be passed back to \pgfgdedgecallback unmodified.
-- @param pgf_edge_nodes Another string that should be passed back to \pgfgdedgecallback unmodified.
--
function TeXInterface.addPgfEdge(from, to, direction, options, pgf_options, pgf_edge_nodes)

  local scope = TeXInterface.topScope()
  local tail = scope.node_names[from]
  local head = scope.node_names[to]

  assert (tail and head, "attempting to create edge between nodes " .. from ..
                         " and ".. to ..", at least one of which is not in the graph")

  local arc = scope.syntactic_digraph:connect(tail, head)
  
  local edge = {
    head = head,
    tail = tail,
    event_index = #scope.events+1,
    options = Options.new(options),
    direction = direction,
    path = {},
    generated_options = {}, -- options generated by the algorithm
    tex = {
      pgf_options = pgf_options,
      pgf_edge_nodes = pgf_edge_nodes,
    },
    storage = Storage.new()
  }

  arc.storage.syntactic_edges = arc.storage.syntactic_edges or {}
  arc.storage.syntactic_edges[#arc.storage.syntactic_edges+1] = edge

  scope.events[#scope.events + 1] = Event.new { kind = 'edge', parameters = { arc, #arc.storage.syntactic_edges } }
end




--- Adds an event to the event sequence.
--
-- @param kind         Name/kind of the event.
-- @param parameters   Parameters of the event.
--
function TeXInterface.addEvent(kind, param)
  local scope = TeXInterface.topScope()
  
  scope.events[#scope.events + 1] = Event.new { kind = kind, parameters = param}
end





---
-- Create the graph drawing coroutine.
--
-- This function creates a coroutine that will run the current graph
-- drawing algorithm. Coroutines are needed since a graph drawing
-- algorithm may choose to create a new node. In this case, the
-- algorithm needs to be suspended and control must be returned back
-- to \TeX, so that the node can be typeset in order to determine the
-- precise size information. Once this is done, control must be passed
-- back to the exact point inside the algorithm where the node was
-- created. Clearly, all of these actions are exactly what coroutines
-- are for.
--
function TeXInterface.createGraphDrawingCoroutine()
  local scope = TeXInterface.topScope()
  assert(not scope.coroutine, "coroutine already created for current gd scope")
  scope.coroutine = coroutine.create(TeXInterface.runGraphDrawingAlgorithm)
end



---
-- Resume the graph drawing coroutine.
--
-- This function is the work horse of the coroutine management. It
-- gets called whenever control passes back from the \TeX\ level to
-- the Lua level. We resume the graph drawing coroutine so that the
-- algorithm can start/proceed. The tricky part is when the algorithm
-- yields, but is not done. In this case, the code needed for creating
-- a new node is passed back to \TeX, but also code for, then,
-- resuming the coroutine.
--
function TeXInterface.resumeGraphDrawingCoroutine()
  local scope = TeXInterface.topScope()
  assert(scope.coroutine, "coroutine must already be created for current gd scope")
  local ok, text = coroutine.resume(scope.coroutine)
  assert(ok, text)
  if coroutine.status(scope.coroutine) ~= "dead" then
    tex.print(text)
    tex.print("\\directlua{pgf.gd.control.TeXInterface.resumeGraphDrawingCoroutine()}")
  end
end


--- Arranges the current graph using the specified algorithm. 
--
-- The algorithm is derived from the graph options and is loaded on
-- demand from the corresponding algorithm file. For a fictitious algorithm 
-- |simple| this file is per convention called 
-- |pgflibrarygraphdrawing-algorithms-simple.lua|. It is required to define
-- at least one function as an entry point to the algorithm. The name of the
-- function is again predetermined as |graph_drawing_algorithm_simple|.
-- When a graph is to be layed out, this function is called with the graph
-- as its only parameter.
--
-- @return Time it took to run the algorithm

function TeXInterface.runGraphDrawingAlgorithm()

  local scope = TeXInterface.topScope()

  if #scope.syntactic_digraph.vertices == 0 then
    -- Nothing needs to be done
    return
  end
  
  local start = os.clock()
  LayoutPipeline.run(scope, require(scope.syntactic_digraph.options["/graph drawing/algorithm"]))
  local stop = os.clock()
  
  return stop - start
end




local unique_count = 1

---
-- The ``node creation callback.''
--
-- This method gets called whenever the graph drawing algorithm
-- request a new node to be created. What happens is that control is
-- temporarily passed back to \TeX, which will create a node. This
-- causes a new vertex to be added to the syntactic digraph, which is
-- then returned.
--
-- @param init This is the array of initial values for the
-- to-be-created vertex.
--
-- @return The new vertex.
--
function TeXInterface.generateNode(init)
  
  local scope = TeXInterface.topScope()
  
  -- Setup node
  if not init.name then
    init.name = "pgf@gd@node@" .. unique_count
    unique_count = unique_count + 1
  else
    assert (scope.node_names[init.name] == nil, "node already present in graph")
  end
  
  if not init.shape or init.shape == "none" then
    init.shape = "rectangle"
  end
  
  -- Create the text needed for creating a new node:
  local opt = {}
  for k,v in pairs(init.generated_options or {}) do
    assert (type(v) ~= "table", "algorithmically generated option value may not be a table")
    assert (type(k) == "number" or type(k) == "string", "algorithmically generated option value may not be a table")
    if type(k) == "number" then
      opt [#opt + 1] = tostring(v) .. ','
    else
      opt [#opt + 1] = tostring(k) .. '={' .. tostring(v) .. '},'
    end
  end
  local tex_command = "\\pgfgdgeneratenodecallback{" .. init.name
                  .. "}{" .. init.shape .. "}{" ..  table.concat(opt) .. "}{"
		.. (init.text or "") .. "}"

  -- Now, go back to TeX...
  coroutine.yield(tex_command)	      
  -- ... and come back with a new node!

  local v = scope.syntactic_digraph.vertices[#scope.syntactic_digraph.vertices]
  assert (v.name == init.name, "internal node creation failed")

  return v  
end


local function option_table_to_string (options)
  local s = { "{" }
  
  for k,v in pairs(options) do
    assert (type(v) ~= "table", "algorithmically generated option value may not be a table")
    if type(k) == "number" then
      s [#s + 1] = tostring(v) .. ','
    elseif type(k) == "string" then
      s [#s + 1] = tostring(k) .. '={' .. tostring(v) .. '},'
    else
      assert (false, "algorithmically generated option key must be a string")
    end
  end

  s[#s+1] = "}"

  return table.concat(s)
end


--- Passes the current graph back to the \TeX\ layer and removes it from the stack.
--
function TeXInterface.endGraphDrawingScope()
  local scope = TeXInterface.topScope()
  local digraph = scope.syntactic_digraph
  
  tex.print("\\pgfgdbeginshipout")
  
    tex.print("\\pgfgdbeginnodeshipout")
      for _,vertex in ipairs(digraph.vertices) do
	assert(vertex.tex, "Thou shalt not modify the syntactic digraph")
	tex.print(
	  string.format(
	    "\\pgfgdshipoutnodecallback{%s}{%fpt}{%fpt}{%fpt}{%fpt}{%s}{%s}{%s}{%s}",
	    'not yet positionedPGFINTERNAL' .. vertex.name,
	    vertex.tex.x_min,
	    vertex.tex.x_max,
	    vertex.tex.y_min,
	    vertex.tex.y_max,
	    vertex.pos.x,
	    vertex.pos.y,
	    vertex.tex.stored_tex_box_number,
	    vertex.tex.late_setup))
      end
    tex.print("\\pgfgdendnodeshipout")

    tex.print("\\pgfgdbeginedgeshipout")
      for _,a in ipairs(digraph.arcs) do
        for _,m in ipairs(a.storage.syntactic_edges or {}) do
	  local callback = {
  	    '\\pgfgdedgecallback',
	    '{', a.tail.name, '}',
	    '{', a.head.name, '}',
	    '{', m.direction,  '}',
	    '{', m.tex and m.tex.pgf_options or "",  '}',
	    '{', m.tex and m.tex.pgf_edge_nodes or "", '}',
	    option_table_to_string(m.generated_options),
	    '{'
	  }

	  for _,c in ipairs(m.path) do
	    callback [#callback + 1] = '--(' .. tostring(c.x) .. 'pt,' .. tostring(c.y) .. 'pt)'	    
	  end
	  
	  callback [#callback + 1] = '}'
      
          -- hand TikZ code over to TeX
          tex.print(table.concat(callback))
	end
      end
    tex.print("\\pgfgdendedgeshipout")

    local kinds = TeXInterface.collection_kinds
    local collections = scope.collections
    
    tex.print("\\pgfgdbeginprekindshipout")
      for i=1,#kinds do
	tex.print("\\pgfgdset{" .. kinds[i].kind .. "/begin rendering/.try}")
	if kinds[i].layer < 0 then
	  for _,c in ipairs(collections[kinds[i].kind] or {}) do
	    tex.print(
	      '\\pgfgdset{'.. kinds[i].kind .. "/render/.try="
		.. option_table_to_string(c.generated_options or {}).."}")
	  end
	end
	tex.print("\\pgfgdset{" .. kinds[i].kind .. "/end rendering/.try}")
      end
    tex.print("\\pgfgdendprekindshipout")
    
    tex.print("\\pgfgdbeginpostkindshipout")
      for i=1,#kinds do
	tex.print("\\pgfgdset{" .. kinds[i].kind .. "/begin rendering/.try}")
	if kinds[i].layer > 0 then
	  for _,c in ipairs(collections[kinds[i].kind] or {}) do
	    tex.print(
	      '\\pgfgdset{'.. kinds[i].kind .. "/render/.try="
		.. option_table_to_string(c.generated_options or {}).."}")
	  end
	end
	tex.print("\\pgfgdset{" .. kinds[i].kind .. "/end rendering/.try}")
      end
    tex.print("\\pgfgdendpostkindshipout")

  tex.print("\\pgfgdendshipout")
  
  table.remove(TeXInterface.scopes) -- pop
end



--- Callback for box retrieval
--
-- This method gets called by the the pgf layer. Its job is to return
-- a specific box contents. This can be done only using a callback
-- since when the graph drawing engine issues its
-- pgfgdinternalshipoutnode commands, these "pile up" and get executed
-- only much later. It is only when each command is executed
-- individually that we are "ready" to retrieve the stored box
-- contents, making this callback nessary

function TeXInterface.retrieveBox(box_reference)
  local ret = TeXInterface.tex_boxes[box_reference]
  TeXInterface.tex_boxes[box_reference] = nil
  return ret
end



--- Defines a default value for a graph parameter. 
--
-- Whenever a graph parameter has not been set by the user explicitly,
-- the value that was last set using this function is used instead.
--
-- @param key The commplete path of the to-be-defined key
-- @param value A string containing the value
--
function TeXInterface.setParameterDefault(key,value)
  assert (not Options.defaults[key], "you may not set a parameter default twice")
  Options.defaults[key] = value
end


---
-- Specifies, that a given parameter accumulates. This means that when
-- the same option is used several times, the value of the option is
-- not overwritten each time, but, rather, the new values are added to
-- the table that is stored in the option.
--
-- @param key The commplete path of the to-be-defined key
--
function TeXInterface.setParameterAccumulates(key)
  Options.accumulates[key] = true
end



-- Done 

return TeXInterface