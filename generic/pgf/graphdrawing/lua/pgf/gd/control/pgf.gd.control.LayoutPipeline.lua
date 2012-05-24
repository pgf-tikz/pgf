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

local Vertex     = require "pgf.gd.model.Vertex"
local Digraph    = require "pgf.gd.model.Digraph"
local Coordinate = require "pgf.gd.model.Coordinate"

local Options    = require "pgf.gd.control.Options"



--- The main "graph drawing pipeline" that handles the pre- and 
-- postprocessing for a graph

function LayoutPipeline.run(scope, algorithm_class)
  
  -- The involved main graphs:
  local syntactic_digraph = scope.syntactic_digraph
  local digraph = Direct.digraphFromSyntacticDigraph(syntactic_digraph)
  
  -- The pipeline...

  -- Step 1: Prepare events
  LayoutPipeline.prepareEvents(scope.events)

  -- Step 2: Compute anchor nodes (relevant for rotated hull computations)
  Anchoring:computeAnchorNode(scope.syntactic_digraph)
  
  -- Step 3: Decompose the graph into connected components, if necessary:
  local syntactic_components 
  if algorithm_class.works_only_on_connected_graphs or
     scope.syntactic_digraph.options['/graph drawing/componentwise'] then
    syntactic_components = Components:decompose(digraph)
    Components:sort(syntactic_digraph.options['/graph drawing/component order'], syntactic_components)    
  else
    -- Only one component: The graph itself...
    syntactic_components = { digraph }
  end
  
  -- Step 4: For all components do:
  for i,c in ipairs(syntactic_components) do

    -- Step 4.1: Reset random number generator to make sure that the
    -- same graph is always typeset in  the same way.
    math.randomseed(syntactic_digraph.options['/graph drawing/random seed'])

    -- Step 4.3: If requested, remove loops
    if algorithm_class.works_only_for_loop_free_graphs then
      for _,v in ipairs(c.vertices) do
	c:disconnect(v,v)
      end
    end

    -- Step 4.4: Precompute the underlying undirected graph
    local ugraph  = Direct.ugraphFromDigraph(c)
    
    -- Step 4.5: Create an algorithm object
    local algorithm = algorithm_class.new{ digraph = c, ugraph = ugraph, scope = scope }
      
    -- Step 4.6: Compute anchor_node. 
    Anchoring:computeAnchorNode(c)
    
    -- Step 4.7: Compute a spanning tree, if necessary
    if algorithm_class.needs_a_spanning_tree then
      assert(algorithm_class.works_only_on_connected_graphs)
      local spanning_algorithm_class = require(c.options["/graph drawing/spanning tree algorithm"])
      algorithm.spanning_tree =
	spanning_algorithm_class.new{
	  ugraph = ugraph,
  	  events = scope.events
        }:run()
    end

    -- Step 4.8: Compute growth-adjusted sizes
    Orientation.prepareRotateAround(algorithm, algorithm.ugraph)
    Orientation.prepareBoundingBoxes(algorithm, algorithm.ugraph.vertices)
    
    -- Step 4.9: Finally, run algorithm on this component!
    if #c.vertices > 1 or algorithm_class.run_also_for_single_node then
      -- Main run of the algorithm:
      if algorithm_class.old_graph_model then
	LayoutPipeline.runOldGraphModel(scope, c, algorithm_class, algorithm)
      else
	algorithm:run ()
      end
    end

    -- Step 4.10: Orient the graph
    Orientation.orient(algorithm, algorithm.ugraph)
  end

  -- Step 5: Packing:
  
  -- Step 5.1: Find unanchored subgraphs
  local unanchored = {}
  local anchored = {}
  local flag = true
  for _,c in ipairs(syntactic_components) do
    if c.storage[Anchoring].anchor_node then
      if flag then
	unanchored[#unanchored + 1] = c
	flag = false
      else
	anchored[#anchored + 1] = c
      end
    else
      unanchored[#unanchored + 1] = c
    end
  end
  
  -- Step 5.2: Now pack them
  Components:pack(syntactic_digraph, syntactic_components)

  -- Step 6: Ok, now comes the anchoring.

  -- Step 6.1: First, anchor everything...
  Anchoring:anchor(syntactic_digraph)
  
  -- Step 6.2: ... and then anchor those components that contain
  -- special anchoring information.
  for _,c in ipairs(anchored) do
    Anchoring:anchor(c)
  end

end
    


--- Store for each begin/end event the index of
-- its corresponding end/begin event
--
-- @param events An event list

function LayoutPipeline.prepareEvents(events)

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




local unique_count = 1

---
-- Generate a new vertex in the syntactic digraph.
--
-- This function can be used to add a vertex to a syntactic
-- digraph. Unlike the nodes added using addPgfNode, the 
-- vertex created using this function was not present in the original
-- graph. For such vertex, there is no corresponding (pgf) node in the
-- original graph; during the shipout process such a node is newly
-- created on the pgf layer. 
--
-- @param algorithm An algorithm for whose syntactic digraph the node should be added 
-- @param init  A table of initial values for the node.
--
-- The following keys are useful for init:
--
-- @param init.pos If present, an initial position of the key
-- @param init.name If present, this name will be given to the
-- node. If not present, an iternal name is generated.
-- @param init.shape If present, a shape of the node.
-- @param init.hull If present, a convex hull of the node. If not
-- present, this will be initialized with a single coordinate at the
-- origin. 
-- @param init.hull_center If present, the center of the convex hull
-- given in the previous key.
-- @param init.option If present, some options for the node.
-- @param init.generated_options A table that is passed back to the
-- higher (pgf) layer as a list of key-value pairs.
-- @param init.text The text of the node, to be passed back to the
-- higher layer. This is what should be displayed as the node's text.
--
-- @return The newly created node

function LayoutPipeline.generateNode(algorithm, init)

  -- Create new node
  init.kind = init.kind or "node"

  local v = Vertex.new (init)
  
  if not v.name then
    v.name = "pgf@gd@node@" .. unique_count;
    unique_count = unique_count + 1
  end
  
  if v.shape == "none" then
    v.shape = "rectangle"
  end

  v.options = Options.new(v.options)
  v.event_index = #algorithm.scope.events + 1

  algorithm.scope.events[#algorithm.scope.events + 1] = { 
    kind = 'node', 
    parameters = v
  }

  -- Add node to graph
  algorithm.scope.syntactic_digraph:add {v}  
  algorithm.digraph:add {v}  
  algorithm.ugraph:add {v}  
  Orientation.prepareBoundingBoxes(algorithm, {v})

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
    local node = Node.new{
      name = v.name,
      tex = {
	tex_node = v.tex.stored_tex_box_number,
	shape = v.shape,
	minX = v.hull[1].x,
	maxX = v.hull[3].x,
	minY = v.hull[1].y,
	maxY = v.hull[3].y,
	late_setup = v.tex.late_setup,
      }, 
      options = v.options,
      event_index = v.event_index,
      index = v.event_index,
      orig_vertex = v,
    }
    graph:addNode(node)
    graph.events[v.event_index] = { kind = 'node', parameters = node }
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
  for name, c in pairs (scope.clusters) do
    cluster = Cluster.new(name)
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
    for i,p in ipairs (e.bend_points) do
      e.orig_m.path [i] = Coordinate.new(p.x, p.y)
    end
  end
end





function LayoutPipeline.runOldGraphModel(scope, digraph, algorithm_class, algorithm)

  local graph = compatibility_digraph_to_graph(scope, digraph)

  algorithm.graph = graph
  graph:registerAlgorithm(algorithm)
    
  -- If requested, remove loops
  if algorithm_class.works_only_for_loop_free_graphs then
    lib.Simplifiers:removeLoopsOldModel(algorithm)
  end
    
  -- If requested, collapse multiedges
  if algorithm_class.works_only_for_simple_graphs then
    lib.Simplifiers:collapseMultiedgesOldModel(algorithm)
  end

  -- Compute anchor_node
  graph.anchor_node = digraph.storage[Anchoring].anchor_node

  if #graph.nodes > 1 or algorithm_class.run_also_for_single_node then
    -- Main run of the algorithm:
    algorithm:run ()
  end
  
  -- If requested, expand multiedges
  if algorithm_class.works_only_for_simple_graphs then
    lib.Simplifiers:expandMultiedgesOldModel(algorithm)
  end
  
  -- If requested, restore loops
  if algorithm_class.works_only_for_loop_free_graphs then
    lib.Simplifiers:restoreLoopsOldModel(algorithm)
  end
  
  compatibility_graph_to_digraph(graph)
end




-- Done

return LayoutPipeline