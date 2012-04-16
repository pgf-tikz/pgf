-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local lib     = require "pgf.gd.lib"
local control = require "pgf.gd.control"


--- The Orientation class is a singleton object.
--
-- It provide methods for orienting graphs.

lib.Orientation = {}




--- Determine rotation caused by growth
--
-- This method tries to determine in which direction the graph is supposed to
-- grow and in which direction the algorithm will grow the graph. These two
-- pieces of information togehter produce a necessary rotation around some node.
-- This rotation is stored in the graph's algorithm table in the rotate_around
-- table.
--
-- Note that this method does not actually cause a rotation to happen; this is
-- left to other method.
--
-- @param algorithm An algorithm object for whose graph the necessary rotation 
-- should be computed

function lib.Orientation:prepareRotateAround(algorithm)

  local graph = algorithm.graph

  -- First, compute the angle and the nodes that determine the growth:
  local function growth_fun (node, grow, flag)
    if grow then
      local growth_direction = node.growth_direction or algorithm.growth_direction
      if growth_direction == "fixed" then
	return false
      elseif growth_direction then
	graph[algorithm].rotate_around = {
	  from_node = node,
	  from_angle = tonumber(growth_direction)/360*2*math.pi,
	  to_angle = tonumber(grow)/360*2*math.pi,
	  swap =  flag
	}
	return true
      else
	-- Find first neighbor or, if it does not exist, first
	-- node other than myself.
	local t
	if node.edges[1] then
	  t = node.edges[1].nodes
	else
	  t = graph.nodes
	end
	
	for _, other in ipairs(t) do
	  if other ~= node then
	    graph[algorithm].rotate_around = {
	      from_node = node,
	      to_node = other,
	      to_angle = tonumber(grow)/360*2*math.pi,
	      swap = flag
	    }
	    return true
	  end
	end	       
      end
    end
  end
  
  for _, node in ipairs(graph.nodes) do
    local grow = node:getOption('/graph drawing/grow', graph)
    if growth_fun(node, grow, true) then return end
    local grow = node:getOption("/graph drawing/grow'", graph)
    if growth_fun(node, grow, false) then return end
  end
  
  growth_fun(graph.nodes[1], "-90", true)

end



--- Compute growth-adjusted node sizes
--
-- For each node of the graph, compute bounding box of the node that
-- results when the node is rotated so that it is in the correct
-- orientation for what the algorithm assumes.
--
-- The "bounding box" actually consists of the fields sibling_pre,
-- sibling_post, level_pre, level_post, which correspond to "min x",
-- "min y", "min y", and "max y" for a tree growing up.
--
-- The computation of the "bounding box" treats a centered circle in a
-- special way, all other shapes are currently treated like a
-- rectangle.

function lib.Orientation:prepareBoundingBoxes(algorithm)
  local graph = algorithm.graph

  local r = graph[algorithm].rotate_around

  if r then
    local angle = r.to_angle -
      (r.from_angle or
       math.atan2(r.to_node.pos.y - r.from_node.pos.y, r.to_node.pos.x - r.from_node.pos.x))

    for _,n in ipairs(graph.nodes) do
      if n.tex.shape == "circle" and
	(n.tex.minX + n.tex.maxX == 0) and
        (n.tex.minY + n.tex.maxY==0) then
	n[algorithm].adjusted_bounding_box = {
	  sibling_pre = n.tex.minX,
	  sibling_post = n.tex.maxX,
	  layer_pre = n.tex.minY,
	  layer_post = n.tex.maxY,
	}
      else
	-- Fill the bounding box field,
	local bb = {}
	
	local corners = {
	  { x = n.tex.minX, y = n.tex.minY },
	  { x = n.tex.minX, y = n.tex.maxY },
	  { x = n.tex.maxX, y = n.tex.minY },
	  { x = n.tex.maxX, y = n.tex.maxY }
	}
	
	bb.sibling_pre = math.huge
	bb.sibling_post = -math.huge
	bb.layer_pre = math.huge
	bb.layer_post = -math.huge
	
	for i=1,#corners do
	  local x =  corners[i].x*math.cos(angle) + corners[i].y*math.sin(angle)
	  local y = -corners[i].x*math.sin(angle) + corners[i].y*math.cos(angle)
	  
	  bb.sibling_pre = math.min (bb.sibling_pre, x)
	  bb.sibling_post = math.max (bb.sibling_post, x)
	  bb.layer_pre = math.min (bb.layer_pre, y)
	  bb.layer_post = math.max (bb.layer_post, y)
	end
	
	-- Flip sibling per and post if flag:
	if r.swap then
	  bb.sibling_pre, bb.sibling_post = -bb.sibling_post, -bb.sibling_pre
	end
	
	n[algorithm].adjusted_bounding_box = bb
      end
    end
  end
end





--- Rotate the whole graph around a point 
--
-- Causes the graph to be rotated around \meta{around} so that what
-- used to be the from_angle becomes the to_angle. If the flag "swap"
-- is set, the graph is additionally swapped along the to_angle.
--
-- @param graph The to-be-rotated graph
-- @param around_x The x-coordinate of the point around which the graph should be rotated
-- @param around_y The y-coordinate
-- @param from_angle An "old" angle
-- @param to_angle A "new" angle
-- @param swap A boolean that, when true, requests that the graph is
--             swapped (flipped) along the new angle

function lib.Orientation:rotateGraphAround(graph, around_x, around_y, from, to, swap)
   
  local function update_pos (point)
    local x = point.x
    local y = point.y
    
    -- Translate to origin
    x, y = x - around_x, y - around_y
    
    -- Rotate to zero degrees:
    x, y = x * math.cos(-from) - y *math.sin(-from), x * math.sin(-from) + y * math.cos(-from) 
    
    if swap then
      y = -y
    end
    
    -- Rotate to from degrees:
    x, y = x * math.cos(to) - y *math.sin(to), x * math.sin(to) + y * math.cos(to) 
    
    -- Translate back
    x, y = x + around_x, y + around_y
    
    -- Store
    point.x = x
    point.y = y
  end
  
  -- perform the rotation
  for _,node in ipairs(graph.nodes) do
    update_pos (node.pos)
  end
  for _,edge in ipairs(graph.edges) do
    for _,point in ipairs(edge.bend_points) do
      update_pos(point)
    end
  end
end



--- Orient the whole graph using two nodes
--
-- The whole graph is rotated so that the line from the first node to
-- the second node has the given angle. If swap is set to true, the
-- graph is also flipped along this line.
--
-- @param graph
-- @param first_node
-- @param seond_node
-- @param target_angle
-- @param swap 

function lib.Orientation:orientTwoNodes(graph, first_node, second_node,
					target_angle, swap)
  if first_node and second_node then
    -- Compute angle between first_node and second_node:
    local x = second_node.pos.x - first_node.pos.x
    local y = second_node.pos.y - first_node.pos.y
    
    local angle = math.atan2(y,x)
    
    self:rotateGraphAround(graph, first_node.pos.x,
			   first_node.pos.y, angle, target_angle, swap)
  end
end



--- Perform a post-layout orientation of the graph
--
-- Performs a post-layout orientation of the graph by performing the
-- steps documented in Section~\ref{subsection-graph-orientation-phases}.
-- of the manual.
-- 
-- @param algorithm An algorithm object.

function lib.Orientation:orient(algorithm)
   
  -- Sanity check
  if #algorithm.graph.nodes < 2 then return end
  
  -- Step 1: Search for an edge with the orient option:
  for _, edge in ipairs(algorithm.graph.edges) do
    local function f (key, flag)
      local orient = edge:getOption('/graph drawing/' .. key)
      if orient then
	self:orientTwoNodes(
	  algorithm.graph, edge.nodes[1], edge.nodes[2], tonumber(orient)/360*2*math.pi, flag)
	return true
      end
    end
    if f("orient", false) then return end
    if f("orient'", true) then return end
  end
  
  -- Step 2: Search for a node with the orient option:
  for _, node in ipairs(algorithm.graph.nodes) do
    local function f (key, flag)
      local orient = node:getOption('/graph drawing/' .. key)
      if orient then
	local angle, other_name = orient:gmatch('{(.+)}{(.+)}')()
	local other = algorithm.graph:findNode(other_name)
	if other then
	  self:orientTwoNodes(algorithm.graph, node, other, tonumber(angle)/360*2*math.pi, flag)
	  return true
	end
      end
    end
    if f("orient", false) then return end
    if f("orient'", true) then return end
  end
  
  -- Step 3: Search for global graph orient options:
  local function f (key, flag)
    local orient = algorithm.graph:getOption('/graph drawing/' .. key)
    if orient then
      local angle, name1, name2 = orient:gmatch('{(.+)}{(.+)}{(.+)}')()
      local name1 = algorithm.graph:findNode(name1)
      local name2 = algorithm.graph:findNode(name2)
      if name1 and name2 then
	self:orientTwoNodes(algorithm.graph, name1, name2, tonumber(angle)/360*2*math.pi, flag)
	return true
      end
    end
  end
  if f("orient", false) then return end
  if f("orient'", true) then return end
  
  -- Computed during preprocessing:
  local r = algorithm.graph[algorithm].rotate_around 
  if r and r.from_node.growth_direction ~= "fixed" and algorithm.growth_direction ~= "fixed" then
    local x = r.from_node.pos.x
    local y = r.from_node.pos.y
    local from_angle = r.from_angle or math.atan2(r.to_node.pos.y - y, r.to_node.pos.x - x)
    
    self:rotateGraphAround(algorithm.graph, x, y, from_angle, r.to_angle, r.swap)
  end
end




-- Done

return lib.Orientation