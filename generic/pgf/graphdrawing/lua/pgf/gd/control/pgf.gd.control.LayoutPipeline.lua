-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- The LayoutPipeline class is a singleton object.
--
-- Its methods implement the steps that are applied 
-- to all graphs prior and after a graph drawing algorithm is
-- called.

local LayoutPipeline = {}


-- Namespace
require("pgf.gd.control").LayoutPipeline = LayoutPipeline


-- Imports
local Anchoring   = require "pgf.gd.lib.Anchoring"
local Components  = require "pgf.gd.lib.Components"
local Direct      = require "pgf.gd.lib.Direct"
local Orientation = require "pgf.gd.lib.Orientation"
local Storage     = require "pgf.gd.lib.Storage"
local Simplifiers = require "pgf.gd.lib.Simplifiers"
local LookupTable = require "pgf.gd.lib.LookupTable"

local Vertex      = require "pgf.gd.model.Vertex"
local Digraph     = require "pgf.gd.model.Digraph"
local Coordinate  = require "pgf.gd.model.Coordinate"

local Options     = require "pgf.gd.control.Options"
local Sublayouts  = require "pgf.gd.control.Sublayouts"

local lib         = require "pgf.gd.lib"

-- Forward definitions

local prepare_events
local compute_collections



--- The main "graph drawing pipeline" that handles the pre- and 
-- postprocessing for a graph

function LayoutPipeline.run(scope, algorithm_class)
  
  -- The pipeline...
  
  -- Step 1: Preparations
  
  -- Step 1.1: Prepare events
  prepare_events(scope.events)
  
  -- Step 1.2: Compute collections
  scope.collections = compute_collections(scope.syntactic_digraph, scope.collections)
    
  -- Pick first layout:
  local root_layout = assert(scope.collections.sublayout_collection[1], "no layout in scope")

  Sublayouts.layoutRecursively(scope, root_layout, LayoutPipeline.runOnLayout)
  
  -- Now, anchor!
  Anchoring.anchor(scope.syntactic_digraph, scope)
  
  -- And, now, do regadless
  Sublayouts.regardless(scope.syntactic_digraph)
  
end


---
-- Invoked from the layout recursion
--
-- @param scope The graph drawing scope, in which the
-- syntactic_digraph will have been restricted to the current layout
-- and in which sublayouts will have been contracted to a single node.
-- @param algorithm_class The to-be-applied algorithm_class
--
function LayoutPipeline.runOnLayout(scope, algorithm_class, layout_graph)
  
  -- The involved main graphs:
  local digraph = Direct.digraphFromSyntacticDigraph(layout_graph)
  
  -- Step 1: Decompose the graph into connected components, if necessary:
  local syntactic_components 
  if algorithm_class.works_only_on_connected_graphs or
     layout_graph.options['/graph drawing/componentwise'] then
     syntactic_components = Components.decompose(digraph)
     Components.sort(layout_graph.options['/graph drawing/component order'], syntactic_components)    
  else
    -- Only one component: The graph itself...
    syntactic_components = { digraph }
  end
  
  -- Step 2: For all components do:
  for i,c in ipairs(syntactic_components) do
  
    -- Step 2.1: Reset random number generator to make sure that the
    -- same graph is always typeset in  the same way.
    math.randomseed(layout_graph.options['/graph drawing/random seed'])

    -- Step 2.3: If requested, remove loops
    if algorithm_class.works_only_for_loop_free_graphs then
      for _,v in ipairs(c.vertices) do
	c:disconnect(v,v)
      end
    end

    -- Step 2.4: Precompute the underlying undirected graph
    local ugraph  = Direct.ugraphFromDigraph(c)
    
    -- Step 2.5: Create an algorithm object
    local algorithm = algorithm_class.new{ digraph = c, ugraph = ugraph, scope = scope }
      
    -- Step 2.6: Compute anchor_node. 
--    Anchoring.computeAnchorNode(c, scope)
    
    -- Step 2.7: Compute a spanning tree, if necessary
    if algorithm_class.needs_a_spanning_tree then
      assert(algorithm_class.works_only_on_connected_graphs)
      local spanning_algorithm_class = require(c.options["/graph drawing/spanning tree algorithm"])
      algorithm.spanning_tree =
	spanning_algorithm_class.new{
	  ugraph = ugraph,
  	  events = scope.events
        }:run()
    end

    -- Step 2.8: Compute growth-adjusted sizes
    Orientation.prepareRotateAround(algorithm, c)
    Orientation.prepareBoundingBoxes(algorithm, c, c.vertices)
    
    -- Step 2.9: Finally, run algorithm on this component!
    if #c.vertices > 1 or algorithm_class.run_also_for_single_node then
      -- Main run of the algorithm:
      if algorithm_class.old_graph_model then
	LayoutPipeline.runOldGraphModel(scope, c, algorithm_class, algorithm)
      else
	algorithm:run ()
      end
    end
    
    -- Step 2.10: Sync the graphs
    c:sync()
    ugraph:sync()
    if algorithm.spanning_tree then
      algorithm.spanning_tree:sync()
    end
    
    -- Step 2.10: Orient the graph
    Orientation.orient(algorithm, c, scope)
  end

  -- Step 5: Packing:
  Components.pack(layout_graph, syntactic_components)
end
    


--
-- Store for each begin/end event the index of
-- its corresponding end/begin event
--
-- @param events An event list

prepare_events =
  function (events)
    local stack = {}

    for i=1,#events do
      if events[i].kind == "begin" then
	stack[#stack + 1] = i
      elseif events[i].kind == "end" then
	local tos = stack[#stack]
	stack[#stack] = nil -- pop
	
	events[tos].end_index = i
	events[i].begin_index = tos
      end
    end
  end


--
-- Compute the collections
--
-- @param syntactic_digraph The syntactic digraph
-- @param collection_table A table of collections.
--
-- @return A table of collection arrays. For each collection kind, there
-- will be one entry in this table, which will be a lookup table. Each
-- element of this lookup table will be table having the fields |name|,
-- |vertices| (an array of vertex objects), and |edges| (an array of
-- edges). 

compute_collections =
  function (syntactic_digraph, collection_table)
    for _,v in ipairs(syntactic_digraph.vertices) do
      for _,entry in ipairs(v.options['/graph drawing/collection memberships'] or {}) do
	local kind, name = entry.kind, entry.name
	local lookup = collection_table[kind] or {}
	local t = lookup[name] 
	if not t then
	  t = { name = name, vertices = {}, edges = {}, options = {}, options = Options.new() }
	  lookup[name]        = t
	  lookup[#lookup + 1] = t
	end
	if not t.vertices[v] then
	  LookupTable.add(t.vertices,{v})
	end
	Options.add(t.options,entry.options)
	collection_table[kind] = lookup
      end
    end

    for _,a in ipairs(syntactic_digraph.arcs) do
      for _,e in ipairs(a.storage.syntactic_edges or {}) do
	for _,entry in ipairs(e.options['/graph drawing/collection memberships'] or {}) do
	  local kind, name = entry.kind, entry.name
	  local lookup = collection_table[kind] or {}
	  local t = lookup[name] 
	  if not t then
	    t = { name = name, vertices = {}, edges = {}, options = Options.new() }
	    lookup[name]        = t
	    lookup[#lookup + 1] = t
	  end
	  if not t.edges[e] then
	    LookupTable.add(t.edges,{e})
	  end
	  Options.add(t.options, entry.options)
	  collection_table[kind] = lookup
	end
      end
    end

    return collection_table
  end




---
-- Generate a new vertex in the syntactic digraph. Calling this method
-- allows algorithms to create nodes that are not present in the
-- original input graph.
--
-- In order to create the node, control is temporarily passed back
-- from the Lua layer to the \TeX\ layer through the use of coroutines.
--
-- @param algorithm An algorithm for whose syntactic digraph the node should be added 
-- @param init  A table of initial values for the node. The following
-- fields will be used:
-- @param init.name If present, this name will be given to the
-- node. If not present, an iternal name is generated. Note that this
-- name may not be the name of an already present node of the graph;
-- in this case an error results.
-- @param init.shape If present, a shape of the node.
-- @param init.generated_options A table that is passed back to the
-- higher (pgf) layer as a list of key-value pairs.
-- @param init.text The text of the node, to be passed back to the
-- higher layer. This is what should be displayed as the node's text.
--
-- @return The newly created node

function LayoutPipeline.generateNode(algorithm, init)
  
  local v = algorithm.scope.interface.generateNode(init)
  
  -- Add node to graph
  algorithm.digraph:add {v}  
  algorithm.ugraph:add {v}  
  Orientation.prepareBoundingBoxes(algorithm, algorithm.digraph, {v})

  return v
end




---
-- Generate a new edge in the syntactic digraph.
--
-- Similar to generateVertex, this function adds a new edge to the
-- syntactic digraph. 
--
-- @param algorithm An algorithm for whose syntactic digraph the node should be added 
-- @param tail A syntactic tail vertex
-- @param head A syntactic head vertex
-- @param init A table of initial values for the edge.
--
-- The following keys are useful for init:
--
-- @param init.direction If present, a direction for the edge. Defaults to "--".
-- @param init.option If present, some options for the node.
-- @param init.generated_options A table that is passed back to the
-- higher (pgf) layer as a list of key-value pairs.

function LayoutPipeline.generateEdge(algorithm, tail, head, init)

  assert (tail and head, "attempting to create edge between nodes " .. tostring(tail) ..
  	                 " and ".. tostring(head) ..", at least one of which is not in the graph")
  
  local scope = algorithm.scope
  
  local arc = scope.syntactic_digraph:connect(tail, head)
  
  local edge = {}
  for k,v in pairs(init) do
    edge[k] = v
  end

  edge.head = head
  edge.tail = tail
  edge.event_index = #scope.events+1
  edge.options = Options.new(edge.options or {})
  edge.direction = edge.direction or "--"
  edge.path = edge.path or {}
  edge.generated_options = edge.generated_options or {}
  edge.storage = Storage.new()

  arc.storage.syntactic_edges = arc.storage.syntactic_edges or {}
  arc.storage.syntactic_edges[#arc.storage.syntactic_edges+1] = edge

  scope.events[#scope.events + 1] = { kind = 'edge', parameters = { arc, #arc.storage.syntactic_edges } }
  
  local direction = edge.direction
  if direction == "->" then
    algorithm.digraph:connect(tail, head)
  elseif direction == "<-" then
    algorithm.digraph:connect(head, tail)
  elseif direction == "--" or direction == "<->" then
    algorithm.digraph:connect(tail, head)
    algorithm.digraph:connect(head, tail)
  end
  algorithm.ugraph:connect(tail, head)
  algorithm.ugraph:connect(head, tail)
end











-- Compat
local Node = require "pgf.gd.model.Node"
local Graph = require "pgf.gd.model.Graph"
local Edge = require "pgf.gd.model.Edge"
local Cluster = require "pgf.gd.model.Cluster"
local lib     = require "pgf.gd.lib"





local unique_count = 0

local function compatibility_digraph_to_graph(scope, g)
  local graph = Graph.new()

  -- Graph options
  graph.options = g.options
  graph.orig_digraph = g

  -- Events
  for i,e in ipairs(scope.events) do
    graph.events[i] = e
  end
  
  -- Nodes
  for _,v in ipairs(g.vertices) do
    if not v.name then
      -- compat needs unique name
      v.name = "auto generated node nameINTERNAL" .. unique_count
      unique_count = unique_count + 1
    end
    local node = Node.new{
      name = v.name,
      tex = {
	tex_node = v.tex and v.tex.stored_tex_box_number,
	shape = v.shape,
	minX = v.hull[1].x,
	maxX = v.hull[3].x,
	minY = v.hull[1].y,
	maxY = v.hull[3].y,
      }, 
      options = v.options,
      event_index = v.event_index,
      index = v.event_index,
      orig_vertex = v,
    }
    graph:addNode(node)
    graph.events[v.event_index or (#graph.events+1)] = { kind = 'node', parameters = node }
  end

  -- Edges
  local mark = {}
  for _,a in ipairs(g.arcs) do
    local da = g.syntactic_digraph:arc(a.tail, a.head)
    if da then
      for _,m in ipairs(da.storage.syntactic_edges) do
	if m.storage[mark] ~= true then
	  m.storage[mark] = true
	  local from_node = graph:findNode(da.tail.name)
	  local to_node = graph:findNode(da.head.name)
	  local edge = graph:createEdge(from_node, to_node, m.direction, m.tex.pgf_aux, m.options, m.tex.pgf_options)
	  edge.event_index = m.event_index
	  edge.orig_m = m
	  graph.events[m.event_index] = { kind = 'edge', parameters = edge }
	end
      end
    end
    local da = g.syntactic_digraph:arc(a.head, a.tail)
    if da then 
      for _,m in ipairs(da.storage.syntactic_edges) do
	if m.storage[mark] ~= true then
	  m.storage[mark] = true
	  local from_node = graph:findNode(da.tail.name)
	  local to_node = graph:findNode(da.head.name)
	  local edge = graph:createEdge(from_node, to_node, m.direction, m.tex.pgf_aux, m.options, m.tex.pgf_options)
	  edge.event_index = m.event_index
	  edge.orig_m = m
	  graph.events[m.event_index] = { kind = 'edge', parameters = edge }
	end
      end
    end
  end
  
  table.sort(graph.edges, function(e1,e2) return e1.event_index < e2.event_index end)
  for _,n in ipairs (graph.nodes) do
    table.sort(n.edges, function(e1,e2) return e1.event_index < e2.event_index end)
  end
  
  -- Clusters
  for _, c in ipairs(scope.collections['same rank'] or {}) do
    cluster = Cluster.new(c.name)
    graph:addCluster(cluster)
    for _,v in ipairs(c.vertices) do
      if g:contains(v) then
	cluster:addNode(graph:findNode(v.name))
      end
    end
  end
  
  return graph
end


local function compatibility_graph_to_digraph(graph)
  for _,n in ipairs(graph.nodes) do
    n.orig_vertex.pos.x = n.pos.x
    n.orig_vertex.pos.y = n.pos.y
  end
  for _,e in ipairs(graph.edges) do
    local tail = e:getTail()
    for i,p in ipairs (e.bend_points) do
      e.orig_m.path [i] = Coordinate.new(p.x - tail.pos.x, p.y - tail.pos.y)
    end
  end
end





function LayoutPipeline.runOldGraphModel(scope, digraph, algorithm_class, algorithm)

  local graph = compatibility_digraph_to_graph(scope, digraph)

  algorithm.graph = graph
  graph:registerAlgorithm(algorithm)
    
  -- If requested, remove loops
  if algorithm_class.works_only_for_loop_free_graphs then
    Simplifiers:removeLoopsOldModel(algorithm)
  end
    
  -- If requested, collapse multiedges
  if algorithm_class.works_only_for_simple_graphs then
    Simplifiers:collapseMultiedgesOldModel(algorithm)
  end

  -- Compute anchor_node
  graph.anchor_node = digraph.storage[Anchoring].anchor_node

  if #graph.nodes > 1 or algorithm_class.run_also_for_single_node then
    -- Main run of the algorithm:
    algorithm:run ()
  end
  
  -- If requested, expand multiedges
  if algorithm_class.works_only_for_simple_graphs then
    Simplifiers:expandMultiedgesOldModel(algorithm)
  end
  
  -- If requested, restore loops
  if algorithm_class.works_only_for_loop_free_graphs then
    Simplifiers:restoreLoopsOldModel(algorithm)
  end

  compatibility_graph_to_digraph(graph)
end




-- Done

return LayoutPipeline