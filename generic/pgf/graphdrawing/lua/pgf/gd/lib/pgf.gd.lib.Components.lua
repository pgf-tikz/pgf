-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The Components class is a singleton object.
--
-- Its methods provide methods for handling components, include their packing code. 

local Components = {}


-- Namespace
local lib     = require "pgf.gd.lib"
lib.Components = Components

-- Imports

local Digraph    = require "pgf.gd.model.Digraph"
local Coordinate = require "pgf.gd.model.Coordinate"
local Vertex     = require "pgf.gd.model.Vertex"
local Arc        = require "pgf.gd.model.Arc"

local Transform  = require "pgf.gd.lib.Transform"


-- Collectors
local point_cloud = {}
Arc.pointCloudCollector(point_cloud)


--- Decompose a graph into its components
--
-- @param graph A to-be-decomposed graph
--
-- @return An array of graph objects that represent the connected components of the graph. 

function Components:decompose (digraph)

  -- The list of connected components (node sets)
  local components = {}
  
  -- Remember, which graphs have already been visited
  local visited = {}
  
  for _,v in ipairs(digraph.vertices) do
    if not visited[v] then
      -- Start a depth-first-search of the graph, starting at node n:
      local stack = { v }
      local component = Digraph.new {
	syntactic_digraph = digraph.syntactic_digraph,
	options = digraph.options
      }
      
      while #stack >= 1 do
	local tos = stack[#stack]
	stack[#stack] = nil -- pop
	
	if not visited[tos] then
	  
	  -- Visit pos:
	  component:add { tos }
	  visited[tos] = true

	  -- Push all unvisited neighbors:
	  for _,a in ipairs(digraph:incoming(tos)) do
	    local neighbor = a.tail
	    if not visited[neighbor] then
	      stack[#stack+1] = neighbor -- push
	    end
	  end
	  for _,a in ipairs(digraph:outgoing(tos)) do
	    local neighbor = a.head
	    if not visited[neighbor] then
	      stack[#stack+1] = neighbor -- push
	    end
	  end
	end
      end
      
      -- Ok, vertices will now contain all vertices reachable from n.
      components[#components+1] = component
    end
  end
  
  if #components < 2 then
    return { digraph }
  end
  
  for _,c in ipairs(components) do
    table.sort (c.vertices, function (u,v) return u.event_index < v.event_index end)
    for _,v in ipairs(c.vertices) do
      for _,a in ipairs(digraph:outgoing(v)) do
	c:connect(a.tail, a.head)
      end
      for _,a in ipairs(digraph:incoming(v)) do
	c:connect(a.tail, a.head)
      end
    end
  end
  
  return components
end




--- Handling of component order
--
-- Components are ordered according to a function that is stored in
-- a key of the Components:component_ordering_functions table (subject
-- to change...) whose name is the graph option /graph
-- drawing/component order. 
--
-- @param component_order An ordering method
-- @param subgraphs A list of to-be-sorted subgraphs

function Components:sort(component_order, subgraphs)
  if component_order then
    local f = Components.component_ordering_functions[component_order]
    if f then
      table.sort (subgraphs, f)
    end
  end
end


-- Right now, we hardcode the functions here. Perhaps make this
-- dynamic in the future. Could easily be done on the tikzlayer,
-- acutally. 

Components.component_ordering_functions = {
  ["increasing node number"] = 
    function (g,h) 
      if #g.vertices == #h.vertices then
	return g.vertices[1].event_index < h.vertices[1].event_index
      else
	return #g.vertices < #h.vertices 
      end
    end,
  ["decreasing node number"] = 
    function (g,h) 
      if #g.vertices == #h.vertices then
	return g.vertices[1].event_index < h.vertices[1].event_index
      else
	return #g.vertices > #h.vertices 
      end
    end,
  ["by first specified node"] = nil,
}




local function compute_rotated_bb(vertices, angle, sep, store)
  
  local r = Transform.new_rotation(-angle)
  
  for _,v in ipairs(vertices) do
    -- Find the rotated bounding box field,
    local t = Transform.concat(r,Transform.new_shift(v.pos.x, v.pos.y))
    
    local min_x = math.huge
    local max_x = -math.huge
    local min_y = math.huge
    local max_y = -math.huge
	
    for i=1,#v.hull do
      local c = v.hull[i]:clone()
      c:apply(t)
      
      min_x = math.min (min_x, c.x)
      max_x = math.max (max_x, c.x)
      min_y = math.min (min_y, c.y)
      max_y = math.max (max_y, c.y)
    end

    -- Enlarge by sep:
    min_x = min_x - sep
    max_x = max_x + sep
    min_y = min_y - sep
    max_y = max_y + sep
    
    local center = v.hull_center:clone()
    
    center:apply(t)
    
    v.storage[store].min_x = min_x
    v.storage[store].max_x = max_x
    v.storage[store].min_y = min_y
    v.storage[store].max_y = max_y
    v.storage[store].c_y = center.y
  end
end



--- Pack components
--
-- Rearranges the positions of nodes. 
-- See Section~\ref{subsection-gd-component-packing} for details.
--
-- @param graph The graph
-- @param components A list of components

function Components:pack(syntactic_digraph, components)

  local store = {} -- Unique id
  
  -- Step 1: Preparation, rotation to target direction
  local sep = syntactic_digraph.options['/graph drawing/component sep']
  local angle = syntactic_digraph.options['/graph drawing/component direction']/180*math.pi
  
  local mark = {}
  for _,c in ipairs(components) do
    
    -- Setup the lists of to-be-considered nodes
    local vertices = {}
    for _,v in ipairs(c.vertices) do
      vertices [#vertices + 1] = v
    end

    for _,a in ipairs(c.arcs) do
      for _,p in ipairs(a[point_cloud]) do
	vertices [#vertices + 1] = Vertex.new { pos = p, kind = "dummy" }
      end
    end
    c.storage[store] = vertices

    compute_rotated_bb(vertices, angle, sep/2, store)
  end
  
  local x_shifts = { 0 }
  local y_shifts = {}
  
  -- Step 2: Vertical alignment
  for i,c in ipairs(components) do
    local max_max_y = -math.huge
    local max_center_y = -math.huge
    local min_min_y = math.huge
    local min_center_y = math.huge
    
    for _,v in ipairs(c.vertices) do
      local info = v.storage[store]
      max_max_y = math.max(info.max_y, max_max_y)
      max_center_y = math.max(info.c_y, max_center_y)
      min_min_y = math.min(info.min_y, min_min_y)
      min_center_y = math.min(info.c_y, min_center_y)
    end
    
    -- Compute alignment line
    local valign = syntactic_digraph.options['/graph drawing/component align']
    local line
    if valign == "counterclockwise bounding box" then
      line = max_max_y
    elseif valign == "counterclockwise" then
      line = max_center_y
    elseif valign == "center" then
      line = (max_max_y + min_min_y) / 2
    elseif valign == "clockwise" then
      line = min_center_y
    elseif valign == "first node" then
      line = c.vertices[1].storage[store].c_y
    else 
      line = min_min_y
    end
    
    -- Overruled?
    for _,v in ipairs(c.vertices) do
      if v.options['/graph drawing/align here'] then
	line = v.storage[store].c_y
	break
      end
    end

    -- Ok, go!
    y_shifts[i] = -line

    -- Adjust nodes:
    for _,v in ipairs(c.storage[store]) do
      local info = v.storage[store]
      info.min_y = info.min_y - line
      info.max_y = info.max_y - line
      info.c_y = info.c_y - line
    end
  end

  -- Step 3: Horizontal alignment
  local y_values = {}

  for _,c in ipairs(components) do
    for _,v in ipairs(c.storage[store]) do
      local info = v.storage[store]
      y_values[#y_values+1] = info.min_y
      y_values[#y_values+1] = info.max_y
      y_values[#y_values+1] = info.c_y
    end
  end
  
  table.sort(y_values)
  
  local y_ranks = {}
  local right_face = {}
  for i=1,#y_values do
    y_ranks[y_values[i]] = i
    right_face[i] = -math.huge
  end

  
  
  for i=1,#components-1 do
    -- First, update right_face:
    local touched = {}
    
    for _,v in ipairs(components[i].storage[store]) do
      local info = v.storage[store]      
      local border = info.max_x
      
      for i=y_ranks[info.min_y],y_ranks[info.max_y] do
	touched[i] = true
	right_face[i] = math.max(right_face[i], border)
      end
    end
    
    -- Fill up the untouched entries:
    local right_max = -math.huge
    for i=1,#y_values do
      if not touched[i] then
	-- Search for next and previous touched
	local interpolate = -math.huge
	for j=i+1,#y_values do
	  if touched[j] then
	    interpolate = math.max(interpolate,right_face[j] - (y_values[j] - y_values[i]))
	    break
	  end
	end
	for j=i-1,1,-1 do
	  if touched[j] then
	    interpolate = math.max(interpolate,right_face[j] - (y_values[i] - y_values[j]))
	    break
	  end
	end
	right_face[i] = math.max(interpolate,right_face[i])
      end
      right_max = math.max(right_max, right_face[i])
    end

    -- Second, compute the left face
    local touched = {}
    local left_face = {}
    for i=1,#y_values do
      left_face[i] = math.huge
    end
    for _,v in ipairs(components[i+1].storage[store]) do
      local info = v.storage[store]
      local border = info.min_x

      for i=y_ranks[info.min_y],y_ranks[info.max_y] do
	touched[i] = true
	left_face[i] = math.min(left_face[i], border)
      end
    end
    
    -- Fill up the untouched entries:
    local left_min = math.huge
    for i=1,#y_values do
      if not touched[i] then
	-- Search for next and previous touched
	local interpolate = math.huge
	for j=i+1,#y_values do
	  if touched[j] then
	    interpolate = math.min(interpolate,left_face[j] + (y_values[j] - y_values[i]))
	    break
	  end
	end
	for j=i-1,1,-1 do
	  if touched[j] then
	    interpolate = math.min(interpolate,left_face[j] + (y_values[i] - y_values[j]))
	    break
	  end
	end
	left_face[i] = interpolate
      end
      left_min = math.min(left_min, left_face[i])
    end

    -- Now, compute the shift.
    local shift = -math.huge

    if syntactic_digraph.options['/graph drawing/component packing'] == "rectangular" then
      shift = right_max - left_min
    else
      for i=1,#y_values do
	shift = math.max(shift, right_face[i] - left_face[i])
      end
    end
    
    -- Adjust nodes:
    x_shifts[i+1] = shift
    for _,v in ipairs(components[i+1].storage[store]) do
      local info = v.storage[store]
      info.min_x = info.min_x + shift
      info.max_x = info.max_x + shift
    end
  end
  
  -- Now, rotate shifts
  for i,c in ipairs(components) do
    local x =  x_shifts[i]*math.cos(angle) - y_shifts[i]*math.sin(angle)
    local y =  x_shifts[i]*math.sin(angle) + y_shifts[i]*math.cos(angle)
    
    for _,v in ipairs(c.storage[store]) do
      v.pos.x = v.pos.x + x
      v.pos.y = v.pos.y + y
    end
  end
end






-- Done

return Components