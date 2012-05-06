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
function TeXInterface:beginGraphDrawingScope(options)

  -- Create a new scope table
  local scope = {
    syntactic_digraph = Digraph.new { options = Options.new(options), syntactic_digraph = "self" },
    events            = {},
    node_names        = {},
    clusters          = {},
    storage           = Storage.new(),
  }
  
  scope.syntactic_digraph.scope   = scope
  
  -- Push scope:
  self.scopes[#self.scopes + 1] = scope
  
end


--- Returns the top scope
--
-- @return The current top scope, which is the scope in which
--         everything should happen right now.

function TeXInterface:topScope()
  return assert(self.scopes[#self.scopes], "no graph drawing scope open")
end



local magic_prefix_length = string.len("not yet positionedPGFINTERNAL") + 1


--- Adds a new node to the graph.
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
function TeXInterface:addPgfNode(box, texname, shape, x_min, y_min, x_max, y_max, options, late_setup)
  local scope = self:topScope()
  local name  = texname:sub(magic_prefix_length)

  -- Store tex box in internal table
  self.tex_boxes[#self.tex_boxes + 1] = node.copy_list(tex.box[box])

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
      stored_tex_box_number = #self.tex_boxes, 
      late_setup = late_setup,
    },
  }

  -- Create name lookup
  assert (scope.node_names[name] == nil, "node already present in graph")
  scope.node_names[name] = v

  -- Register event
  scope.events[#scope.events + 1] = { 
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

function TeXInterface:setLateNodeOptions(name, options)
  local scope = self:topScope()
  local node = assert(scope[name], "node is missing, cannot set late options")
  
  for k,v in pairs(options) do
    node.options [k] = v
  end
  
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
function TeXInterface:addPgfEdge(from, to, direction, options, pgf_options, pgf_edge_nodes)

  local scope = self:topScope()
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
    tex = {
      pgf_options = pgf_options,
      pgf_options_from_algorithm = {},
      pgf_edge_nodes = pgf_edge_nodes,
    },
    storage = Storage.new()
  }

  arc.storage.syntactic_edges[#arc.storage.syntactic_edges+1] = edge

  scope.events[#scope.events + 1] = { kind = 'edge', parameters = { arc, #arc.storage.syntactic_edges } }
end




--- Adds an event to the event sequence.
--
-- @param kind         Name/kind of the event.
-- @param parameters   Parameters of the event.
--
function TeXInterface:addEvent(kind, param)
  local scope = self:topScope()
  
  scope.events[#scope.events + 1] = { kind = kind, parameters = param}
end




--- Adds a node to a cluster
--
-- Conceptually, a cluster is a digraph whose node set is a subset of
-- the nodes of the scope's main graph. However, in most cases a
-- cluster will just be a discrete graph (contain no arcs) and, thus,
-- just identifies a set of arcs.
--
-- @param node_name    Name of a node.
-- @param cluster_name Name of a cluster.
--

function TeXInterface:addNodeToCluster(node_name, cluster_name)
  assert (type(cluster_name) == "string" and cluster_name ~= "", "illegal cluster name")
  local scope = self:topScope()
  local clusters = scope.clusters
  
  local cluster = clusters[cluster_name]
  local v = assert(scope.node_names[node_name], "node not found")

  if not cluster then
    cluster = Digraph.new{
      options = Options.new{},
      syntactic_digraph = scope.syntactic_digraph
    }
    clusters[cluster_name] = cluster
  end

  cluster:add {v}
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

function TeXInterface:runGraphDrawingAlgorithm()

  local scope = self:topScope()

  if #scope.syntactic_digraph.vertices == 0 then
    -- Nothing needs to be done
    return
  end
  
  local start = os.clock()
  LayoutPipeline:run(scope, require(scope.syntactic_digraph.options["/graph drawing/algorithm"]))
  local stop = os.clock()
  
  return stop - start
end



--- Passes the current graph back to the \TeX\ layer and removes it from the stack.
--
function TeXInterface:endGraphDrawingScope()
  local digraph = self:topScope().syntactic_digraph
  
  tex.print("\\pgfgdbeginshipout")
  
    tex.print("\\pgfgdbeginnodeshipout")
      for _,v in ipairs(digraph.vertices) do
	tex.print(
	  string.format(
	    "\\pgfgdinternalshipoutnode{%s}{%fpt}{%fpt}{%fpt}{%fpt}{%s}{%s}{%s}{%s}",
	    'not yet positionedPGFINTERNAL' .. v.name,
	    v.tex.x_min,
	    v.tex.x_max,
	    v.tex.y_min,
	    v.tex.y_max,
	    v.pos.x,
	    v.pos.y,
	    v.tex.stored_tex_box_number,
	    v.tex.late_setup))
      end
    tex.print("\\pgfgdendnodeshipout")

    tex.print("\\pgfgdbeginedgeshipout")
    for _,a in ipairs(digraph.arcs) do
        for _,m in ipairs(a.storage.syntactic_edges) do
	  local callback = {
  	    '\\pgfgdedgecallback',
	    '{', a.tail.name, '}',
	    '{', a.head.name, '}',
	    '{', m.direction,  '}',
	    '{', m.tex.pgf_options,  '}',
	    '{', m.tex.pgf_edge_nodes, '}',
	    '{',
	  }

	  for k,v in pairs(m.tex.pgf_options_from_algorithm) do
	    assert (type(k) == "string", "algorithmically generated option key must be a string")
	    assert (type(v) ~= "table", "algorithmically generated option value may not be a table")
	    callback [#callback + 1] = tostring(k) .. '={' .. tostring(v) .. '},'
	  end
	  
	  callback [#callback + 1] = '}{'

	  for _,c in ipairs(m.path) do
	    callback [#callback + 1] = '--(' .. tostring(c.x) .. 'pt,' .. tostring(c.y) .. 'pt)'	    
	  end
	  
	  callback [#callback + 1] = '}'
      
          -- hand TikZ code over to TeX
          tex.print(table.concat(callback))
	end
      end
    tex.print("\\pgfgdendedgeshipout")
  
  tex.print("\\pgfgdendshipout")
  
  table.remove(self.scopes) -- pop
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

function TeXInterface:retrieveBox(box_reference)
  local ret = self.tex_boxes[box_reference]
  self.tex_boxes[box_reference] = nil
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
function TeXInterface:setGraphParameterDefault(key,value)
  assert (not Options.defaults[key], "you may not set a parameter default twice")
  Options.defaults[key] = value
end





-- Done 

return TeXInterface