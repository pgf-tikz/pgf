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
-- The |Sublayouts| module handles graphs for which multiple layouts are defined. 
--
-- Please see Section~\ref{section-gd-sublayouts} for an overview of
-- sublayouts. 
--

local Sublayouts = {}

-- Namespace
require("pgf.gd.control").Sublayouts = Sublayouts


-- Includes

local Digraph    = require "pgf.gd.model.Digraph"
local Vertex     = require "pgf.gd.model.Vertex"
local Coordinate = require "pgf.gd.model.Coordinate"

local lib        = require "pgf.gd.lib"


---
-- Setup a layout. 
--
-- @param name The name (actually a number) of the sublayout to be processed.
-- @param height The height of the layout in the stack of sublayouts.
-- @param scope The graph drawing scope to which this layout should belong
-- @param layout_event The event corresponding to the layout. 
-- @param node_event The event corresponding to the layout's
-- node. This is a dummy node, but when a new node representing the
-- layout is created, its event index will be this.  
-- @param options Some options (this table will be used to decide which
-- algorithm is to be used later on).
--
function Sublayouts.setupLayout(name, height, scope, layout_event, options)
  
  local sls = scope.sublayout_stack
  local sublayouts = scope.collections.sublayout_collection
    
  -- Clear stack from height onwards
  for i=#sls,height,-1 do
    sls[i] = nil
  end
  
  -- Create new entry:
  local layout = { 
    name = name,
    vertices = {},
    edges = {},
    parent_layout = scope.sublayout_stack[height-1],
    child_layouts = {},
    options = options,
    layout_event = layout_event,
    event_index = layout_event.event_index,
    subgraph_nodes = {},
  }
  
  -- Enter:
  sls[height] = layout
  
  assert (not sublayouts[name], "layout already exists")
  sublayouts[name]            = layout
  sublayouts[#sublayouts + 1] = layout

  -- Setup child array
  if layout.parent_layout then
    local child_array = layout.parent_layout.child_layouts
    child_array[#child_array+1] = layout
  else
    assert(#sublayouts == 1, "there may be only one root layout per scope")
  end
end



-- Offset a node by an offset. This will \emph{also} offset all
-- subnodes, which arise from sublayouts.
--
-- @param vertex A vertex
-- @param pos A offset
--
local function offset_vertex(v, delta)
  v.pos:shiftByCoordinate(delta)
  for _,sub in ipairs(v.storage[Sublayouts].subs or {}) do
    offset_vertex(sub, delta)
  end
end


-- Nudge positioning. You can call this function  several times on the
-- same graph; nudging will be done only once. 
--
-- @param graph A graph
--
local function nudge(graph)
  for _,v in ipairs(graph.vertices) do
    local nudge = v.options['/graph drawing/nudge']
    if nudge and not v.storage[Sublayouts].alreadyNudged then
      offset_vertex(v, Coordinate.new(nudge[1],nudge[2]))
      v.storage[Sublayouts].alreadyNudged = true
    end
  end
end



-- Create subgraph nodes
--
-- @param scope A scope
-- @param syntactic_digraph The syntactic digraph.
-- @param test Only for vertices whose subgraph collection passes this test will we create subgraph nodes 
local function create_subgraph_node(scope, syntactic_digraph, vertex)
  
  local subgraph_node_collection = assert(scope.collections['subgraph node collection'], "no subgraph node collection")
  local subgraph_collection = assert(subgraph_node_collection[vertex.name], "collection not found")
  
  local cloud = {}
  -- Add all points of n's collection, except for v itself, to the cloud:
  for _,v in ipairs(subgraph_collection.vertices) do
    if vertex ~= v then
      assert(syntactic_digraph:contains(v), "the layout must contain all nodes of the subgraph")
      for _,p in ipairs(v.hull) do
	cloud[#cloud+1] = p + v.pos
      end
    end
  end
  for _,e in ipairs(subgraph_collection.edges) do
    for _,p in ipairs(e.path) do
      cloud[#cloud+1] = p + e.tail.pos
    end
  end
  local x_min, y_min, x_max, y_max, c_x, c_y = Coordinate.boundingBox(cloud)

  -- Shift the graph so that it is centered on the origin:
  for _,p in ipairs(cloud) do
    p:unshift(c_x,c_y)
  end
  
  local init = {
    name = vertex.name,
    options = {
      { key = "subgraph point cloud", value = table.concat(lib.imap(cloud, tostring)) },
      { key = "subgraph bounding box height", value = tostring(y_max-y_min) .. "pt" },
      { key = "subgraph bounding box width", value = tostring(x_max-x_min) .. "pt" },
      { key = "subgraph text", value = vertex.options['/graph drawing/subgraph node text'] },
      { key = "start subgraph node", value = ""},
    },
    options_string = vertex.options['/graph drawing/subgraph node options'],
    text = "\\pgfgdsubgraphnodecontents"
  }
    
  -- And now, the "grand call":
  scope.interface.generateNode(init)
  
  -- Shift it were it belongs
  vertex.pos:shift(c_x,c_y)
  
  -- Remember all the subnodes for nudging and regardless
  -- positioning
  local subs = {}
  for _,v in ipairs(subgraph_collection.vertices) do
    if v ~= vertex then
      subs[#subs+1] = v
    end
  end
  
  vertex.storage[Sublayouts].subs = subs
end


-- Tests whether two graphs have a vertex in common
local function intersection(g1, g2)
  for _,v in ipairs(g1.vertices) do
    if g2:contains(v) then
      return v
    end
  end
end

-- Tests whether a graph is a set is a subset of another
local function special_vertex_subset(vertices, graph)
  for _,v in ipairs(vertices) do
    if not graph:contains(v) and not (v.kind == "subgraph node") then
      return false
    end
  end
  return true
end


---
-- The layout recursion
--
-- @param scope The graph drawing scope
-- @param layout The to-be-laid-out collection
-- @param fun The to-be-called function for laying out the graph.
--
-- @return A layed out graph.
function Sublayouts.layoutRecursively(scope, layout, fun)
  
  local algorithm = assert(require(layout.options['/graph drawing/algorithm']), "algorithm not found")
  local uncollapsed_subgraph_nodes = lib.copy(layout.subgraph_nodes)
  
  -- Step 1: Iterate over all sublayouts of the current layout:
  local resulting_graphs = {}
  local loc = {} -- unique index
   
  -- Now, iterate over all sublayouts
  for i,child in ipairs(layout.child_layouts) do
    resulting_graphs[i] = Sublayouts.layoutRecursively(scope, child, fun)
    resulting_graphs[i].storage[loc].layout = child
  end

  
  -- Step 2: Run the merge process:
  local merged_graphs = {}
  
  while #resulting_graphs > 0 do
    
    local n = #resulting_graphs
    
    -- Setup marked array:
    local marked = {}
    for i=1,n do
      marked[i] = false
    end
    
    -- Mark first graph and copy everything from there
    marked[1] = true
    local touched = {}
    for _,v in ipairs(resulting_graphs[1].vertices) do
      v.pos = v.storage[resulting_graphs[1]].pos
      v.storage[touched] = true
    end    

    -- Repeatedly find a node that is connected to a marked node:
    local i = 1
    while i <= n do
      if not marked[i] then
	for j=1,n do
	  if marked[j] then
	    local v = intersection(resulting_graphs[i], resulting_graphs[j])
	    if v then
	      -- Aha, they intersect at vertex v

	      -- Mark the i-th graph:
	      marked[i] = true
	      connected_some_graph = true
	      
	      -- Shift the i-th graph:
	      local x_offset = v.pos.x - v.storage[resulting_graphs[i]].pos.x
	      local y_offset = v.pos.y - v.storage[resulting_graphs[i]].pos.y

	      	      
	      for _,u in ipairs(resulting_graphs[i].vertices) do
		if u.storage[touched] ~= true then
		  u.storage[touched] = true
		  u.pos = u.storage[resulting_graphs[i]].pos:clone()
		  u.pos:shift(x_offset, y_offset)
		end
	      end
	      
	      -- Restart
	      i = 0
	      break
	    end		
	  end
	end
      end
      i = i + 1
    end

    -- Now, we can collapse all marked graphs into one graph:
    local merge = Digraph.new { syntactic_digraph = "self" }
    local remaining = {}
    
    -- Add all vertices and edges:
    for i=1,n do
      if marked[i] then
	merge:add (resulting_graphs[i].vertices)
	for _,a in ipairs(resulting_graphs[i].arcs) do
	  merge:connect(a.tail,a.head)
	end
      else
	remaining[#remaining + 1] = resulting_graphs[i]
      end
    end

    -- Remember the first layout this came from:
    merge.storage[loc].layout = resulting_graphs[1].storage[loc].layout

    -- Restart with rest:
    merged_graphs[#merged_graphs+1] = merge
    
    resulting_graphs = remaining
  end
  
  -- Step 3: Run the algorithm on the layout:

  -- Create a new syntactic digraph:
  local syntactic_digraph = Digraph.new {
    syntactic_digraph = "self",
    options = layout.options
  }

  -- Copy all vertices and edges from the collection...
  syntactic_digraph:add (layout.vertices)
  for _,e in ipairs(layout.edges) do
    syntactic_digraph:add {e.head, e.tail}
    local arc = syntactic_digraph:connect(e.tail, e.head)    
    arc.storage.syntactic_edges = arc.storage.syntactic_edges or {}
    arc.storage.syntactic_edges[#arc.storage.syntactic_edges+1] = e
  end

  -- Find out which subgraph nodes can be created now and make them part of the merged graphs
  local subgraph_node_collection = scope.collections['subgraph node collection']
  for i=#uncollapsed_subgraph_nodes,1,-1 do
    local v = uncollapsed_subgraph_nodes[i]
    local subgraph_collection = assert(subgraph_node_collection[v.name], "collection not found")
    local vertices = subgraph_collection.vertices
    -- Test, if all vertices of the subgraph are in one of the merged graphs.
    for _,g in ipairs(merged_graphs) do
      if special_vertex_subset(vertices, g) then
	-- Ok, we can create a subgraph now
	create_subgraph_node(scope, syntactic_digraph, v)
	-- Make it part of the collapse!
	g:add{v}
	-- Do not consider again
	uncollapsed_subgraph_nodes[i] = false
	break
      end
    end
  end
  
  
  
  -- Collapse the nodes that are part of a merged_graph
  local collapsed_vertices = {}
  for _,g in ipairs(merged_graphs) do
    local intersection = {}
    for _,v in ipairs(g.vertices) do
      if syntactic_digraph:contains(v) then
	intersection[#intersection+1] = v
      end
    end
    if #intersection > 0 then
      -- Compute bounding box of g (this should actually be the convex
      -- hull) Hmm...:
      local array = {}
      for _,v in ipairs(g.vertices) do
	for _,p in ipairs(v.hull) do
	  array[#array+1] = p + v.pos
	end
      end
      for _,a in ipairs(g.arcs) do
	for _,e in ipairs(a.storage.syntactic_edges or {}) do
	  for _,p in ipairs(e.path) do
	    array[#array+1] = p + a.tail.pos
	  end
	end
      end
      local x_min, y_min, x_max, y_max, c_x, c_y = Coordinate.boundingBox(array)
      
      -- Shift the graph so that it is centered on the origin:
      for _,v in ipairs(g.vertices) do
	v.pos:unshift(c_x,c_y)
      end
      x_min = x_min - c_x
      x_max = x_max - c_x
      y_min = y_min - c_y
      y_max = y_max - c_y
      
      local event_index = g.storage[loc].layout.event_index

      local v = Vertex.new {
	-- Standard stuff
	shape = "none",
	kind  = "node",
	hull  = { Coordinate.new(x_min, y_min), Coordinate.new(x_min, y_max), 
		  Coordinate.new(x_max, y_max),
		  Coordinate.new(x_max, y_min) },
	options = {},
	event_index = event_index,
      }
      
      -- Update node_event
      scope.events[event_index].parameters = v
      
      local collapse_vertex = syntactic_digraph:collapse(
	intersection,
	v,
	nil,
	function (new_arc, arc)
	  for _,e in ipairs(arc.storage.syntactic_edges) do
	    local s_edges = new_arc.storage.syntactic_edges or {}
	    s_edges[#s_edges + 1] = e
	    new_arc.storage.syntactic_edges = s_edges
	  end
	end)
      syntactic_digraph:remove(intersection)
      collapsed_vertices[#collapsed_vertices+1] = collapse_vertex
    end
  end
  
  -- Sort the vertices
  table.sort(syntactic_digraph.vertices, function(u,v) return u.event_index < v.event_index end) 
  
  -- Should we "hide" the subgraph nodes?
  local hidden_node
  if not algorithm.include_subgraph_nodes then
    local subgraph_nodes = lib.imap (syntactic_digraph.vertices,
      function (v) if v.kind == "subgraph node" then return v end end) 
    
    if #subgraph_nodes > 0 then
      hidden_node = Vertex.new {}
      syntactic_digraph:collapse(subgraph_nodes, hidden_node)
      syntactic_digraph:remove (subgraph_nodes)
      syntactic_digraph:remove {hidden_node}
    end
  end
  
  -- Ok, everything setup! Run the algorithm recursively...
  fun(scope, algorithm, syntactic_digraph)

  if hidden_node then
    syntactic_digraph:expand(hidden_node)
  end
  
  -- Now, we need to expand the collapsed vertices once more:
  for i=#collapsed_vertices,1,-1 do
    syntactic_digraph:expand(
      collapsed_vertices[i],
      function (c, v)
	v.pos:shiftByCoordinate(c.pos)
      end
    )
    for _,a in ipairs(syntactic_digraph:outgoing(collapsed_vertices[i])) do
      for _,e in ipairs(a.storage.syntactic_edges) do
	for _,p in ipairs(e.path) do
	  p:shiftByCoordinate(a.tail.pos)
	  p:unshiftByCoordinate(e.tail.pos)
	end
      end
    end
  end
  syntactic_digraph:remove(collapsed_vertices)

  -- Step 4: Create the layout node if necessary
  for i=#uncollapsed_subgraph_nodes,1,-1 do
    if uncollapsed_subgraph_nodes[i] then
      create_subgraph_node(scope, syntactic_digraph, uncollapsed_subgraph_nodes[i])
    end
  end
  
  -- Now seems like a good time to nudge and do regardless positioning
  nudge(syntactic_digraph)

  -- Step 5: Cleanup  
  -- Push the computed position into the storage:
  for _,v in ipairs(syntactic_digraph.vertices) do
    v.storage[syntactic_digraph].pos = v.pos:clone()
  end

  return syntactic_digraph
end





---
-- Regardless positioning.
--
-- @param graph A graph
--
function Sublayouts.regardless(graph)
  for _,v in ipairs(graph.vertices) do
    local regardless = v.options['/graph drawing/regardless at']
    if regardless then
      offset_vertex(v, Coordinate.new(regardless[1],regardless[2]) - v.pos)
    end
  end
end



-- Done 

return Sublayouts