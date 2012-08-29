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
function Sublayouts.setupLayout(name, height, scope, layout_event, node_event, options)

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
    node_event = node_event,
    layout_node = node_event.parameters
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



-- Tests whether two graphs have a vertex in common
local function intersection(g1, g2)
  for _,v in ipairs(g1.vertices) do
    if g2:contains(v) then
      return v
    end
  end
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
  -- ... except for the layout node, if present:
  if layout.layout_node then
    syntactic_digraph:remove {layout.layout_node}
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

      local event_index = g.storage[loc].layout.node_event.event_index

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
  
  -- Ok, everything setup! Run the algorithm recursively...
  fun(scope, require(layout.options['/graph drawing/algorithm']), syntactic_digraph)
  
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
  local n = layout.layout_node
  if n then

    -- Second, invoke callback:
    local event = layout.layout_event
    local cloud = {}
    -- Add all points of the current layout to the cloud:
    for _,v in ipairs(syntactic_digraph.vertices) do
      for _,p in ipairs(v.hull) do
	cloud[#cloud+1] = p + v.pos
      end
    end
    for _,a in ipairs(syntactic_digraph.arcs) do
      for _,e in ipairs(a.storage.syntactic_edges or {}) do
	for _,p in ipairs(e.path) do
	  cloud[#cloud+1] = p + a.tail.pos
	end
      end
    end
    local x_min, y_min, x_max, y_max, c_x, c_y = Coordinate.boundingBox(cloud)
    
    -- Shift the graph so that it is centered on the origin:
    for _,v in ipairs(syntactic_digraph.vertices) do
      v.pos:unshift(c_x,c_y)
    end
    for _,p in ipairs(cloud) do
      p:unshift(c_x,c_y)
    end
    
    -- Add the node itself and its edges to the graph:
    syntactic_digraph:add {n}
    for _,e in ipairs(layout.edges) do
      if e.head == n or e.tail == n then
	syntactic_digraph:add {e.head, e.tail}
	local arc = syntactic_digraph:connect(e.tail, e.head)    
	arc.storage.syntactic_edges = arc.storage.syntactic_edges or {}
	arc.storage.syntactic_edges[#arc.storage.syntactic_edges+1] = e
      end
    end
    
    local init = {
      name = event.callback_name,
      options = {
	{ key = "layout point cloud", value = table.concat(lib.imap(cloud, tostring)) },
	{ key = "layout bounding box height", value = tostring(y_max-y_min) .. "pt" },
	{ key = "layout bounding box width", value = tostring(x_max-x_min) .. "pt" },
	{ key = "layout text", value = event.callback_text },
	{ key = "start layout node", value = ""},
      },
      options_string = event.callback_options,
      text = "\\pgfgdlayoutnodecontents"
    }

    -- And now, the "grand call":
    scope.interface.generateNode(init)
    
  end

  -- Step 5: Cleanup
  
  -- Push the computed position into the storage:
  for _,v in ipairs(syntactic_digraph.vertices) do
    v.storage[syntactic_digraph].pos = v.pos:clone()
  end

  return syntactic_digraph
end



-- Done 

return Sublayouts