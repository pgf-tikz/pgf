-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The Orientation class is a singleton object.
--
-- It provide methods for orienting graphs.

local Orientation = {}


-- Namespace
require("pgf.gd.lib").Orientation = Orientation

local lib       = require("pgf.gd.lib")

local Transform = require("pgf.gd.lib.Transform")
local Arc       = require("pgf.gd.model.Arc")


-- Setup some options

Arc.optionSyntacticCollector("/graph drawing/orient")
Arc.optionSyntacticCollector("/graph drawing/orient'")

local point_cloud = {} -- Id
Arc.pointCloudCollector(point_cloud)

local event_index = {} -- Id
Arc.eventIndexCollector(event_index)


--- Determine rotation caused by growth
--
-- This method tries to determine in which direction the graph is supposed to
-- grow and in which direction the algorithm will grow the graph. These two
-- pieces of information togehter produce a necessary rotation around some node.
-- This rotation is stored in the graph's storage at the store key.
--
-- Note that this method does not actually cause a rotation to happen; this is
-- left to other method.
--
-- @param algorithm An algorithm
-- @param ugraph An undirected graph
-- @param store An index into the graph's storage in which to store the computed information

function Orientation:prepareRotateAround(algorithm, ugraph)

  -- Find the vertex from which we orient
  local swap = true

  local v,_,grow = lib.find (ugraph.vertices, function (v) return v.options["/graph drawing/grow"] end)
  
  if not v and ugraph.options["/graph drawing/grow"] then
    v,grow,swap = ugraph.vertices[1], ugraph.options["/graph drawing/grow"], true
  end

  if not v then
    v,_,grow =  lib.find (ugraph.vertices, function (v) return v.options["/graph drawing/grow'"] end)
    swap = false
  end
  
  if not v and ugraph.options["/graph drawing/grow'"] then
    v,grow,swap = ugraph.vertices[1], ugraph.options["/graph drawing/grow'"], false
  end

  if not v then
    v, grow, swap = ugraph.vertices[1], -90, true
  end
  
  -- Now compute the rotation
  local info = ugraph.storage[algorithm]
  local growth_direction = v.growth_direction or algorithm.growth_direction
  
  if growth_direction == "fixed" then
    return
  elseif growth_direction then
    info.from_node = v
    info.from_angle = growth_direction/360*2*math.pi
    info.to_angle = grow/360*2*math.pi
    info.swap = swap
  else
    info.from_node = v
    local other = lib.find_min(
      ugraph:outgoing(v),
      function (a)
	if a.head ~= v and a[event_index] then
	  return a, a[event_index]
	end
      end)
    info.to_node = (other and other.head) or
                   (ugraph.vertices[1] == v and ugraph.vertices[2] or ugraph.vertices[1])
    info.to_angle = grow/360*2*math.pi
    info.swap = swap
  end
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

function Orientation:prepareBoundingBoxes(algorithm, ugraph)
  
  local info = ugraph.storage[algorithm]

  if info.from_node then
    local angle = info.to_angle -
      (info.from_angle or
       math.atan2(info.to_node.pos.y - info.from_node.pos.y, info.to_node.pos.x - info.from_node.pos.x))

    for _,v in ipairs(ugraph.vertices) do
      local bb = v.storage[algorithm]
      
      if v.shape == "circle" and v.hull_center.x == 0 and v.hull_center.y == 0 then
	bb.sibling_pre = v.hull[1].x
	bb.sibling_post = v.hull[3].x
	bb.layer_pre = v.hull[1].y
	bb.layer_post = v.hull[3].y
      else
	-- Fill the bounding box field,
	bb.sibling_pre = math.huge
	bb.sibling_post = -math.huge
	bb.layer_pre = math.huge
	bb.layer_post = -math.huge

	local c = math.cos(angle)
	local s = math.sin(angle)
	for _,p in ipairs(v.hull) do
	  local x =  p.x*c + p.y*s
	  local y = -p.x*s + p.y*c
	  
	  bb.sibling_pre = math.min (bb.sibling_pre, x)
	  bb.sibling_post = math.max (bb.sibling_post, x)
	  bb.layer_pre = math.min (bb.layer_pre, y)
	  bb.layer_post = math.max (bb.layer_post, y)
	end
	
	-- Flip sibling per and post if flag:
	if info.swap then
	  bb.sibling_pre, bb.sibling_post = -bb.sibling_post, -bb.sibling_pre
	end
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
-- @param ugraph The to-be-rotated (undirected) graph
-- @param around_x The x-coordinate of the point around which the graph should be rotated
-- @param around_y The y-coordinate
-- @param from_angle An "old" angle
-- @param to_angle A "new" angle
-- @param swap A boolean that, when true, requests that the graph is
--             swapped (flipped) along the new angle

function Orientation:rotateGraphAround(ugraph, around_x, around_y, from, to, swap)

  -- Translate to origin
  local t = Transform.new_shift(-around_x, -around_y)
  
  -- Rotate to zero degrees:
  t = Transform.concat(Transform.new_rotation(-from), t)
  
  -- Swap
  if swap then
    t = Transform.concat(Transform.new_scaling(1,-1), t)
  end
  
  -- Rotate to from degrees:
  t = Transform.concat(Transform.new_rotation(to), t)
  
  -- Translate back
  t = Transform.concat(Transform.new_shift(around_x, around_y), t)

  -- perform the rotation
  for _,v in ipairs(ugraph.vertices) do
    v.pos:apply(t)
  end
  
  for _,a in ipairs(ugraph.arcs) do
    for _,p in ipairs(a[point_cloud]) do
      p:apply(t)
    end
  end
end



--- Orient the whole graph using two nodes
--
-- The whole graph is rotated so that the line from the first node to
-- the second node has the given angle. If swap is set to true, the
-- graph is also flipped along this line.
--
-- @param ugraph
-- @param first_node
-- @param seond_node
-- @param target_angle
-- @param swap 

function Orientation:orientTwoNodes(ugraph, first_node, second_node, target_angle, swap)
  if first_node and second_node then
    -- Compute angle between first_node and second_node:
    local x = second_node.pos.x - first_node.pos.x
    local y = second_node.pos.y - first_node.pos.y
    
    local angle = math.atan2(y,x)
    self:rotateGraphAround(ugraph, first_node.pos.x,
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

function Orientation:orient(algorithm, ugraph)
  
  -- Sanity check
  if #ugraph.vertices < 2 then return end
  
  -- Step 1: Search for an edge with the orient option:
  for _, a in ipairs(ugraph.arcs) do
    if a["/graph drawing/orient"] then
      return self:orientTwoNodes(ugraph, a.tail, a.head, a["/graph drawing/orient"]/360*2*math.pi, false)
    end
    if a["/graph drawing/orient'"] then
      return self:orientTwoNodes(ugraph, a.tail, a.head, a["/graph drawing/orient'"]/360*2*math.pi, true)
    end
  end
  
  -- Step 2: Search for a node with the orient option:
  for _, v in ipairs(ugraph.vertices) do
    local function f (key, flag)
      local orient = v.options['/graph drawing/' .. key]
      if orient then
	local angle, other_name = unpack (orient)
	local other = ugraph.scope.node_names[other_name]
	if ugraph:contains(other) then
	  self:orientTwoNodes(ugraph, node, other, tonumber(angle)/360*2*math.pi, flag)
	  return true
	end
      end
    end
    if f("orient", false) then return end
    if f("orient'", true) then return end
  end
  
  -- Step 3: Search for global graph orient options:
  local function f (key, flag)
    local orient = ugraph.options['/graph drawing/' .. key]
    if orient then
      local angle, name1, name2 = unpack (orient)
      local n1 = ugraph.scope.node_names[name1]
      local n2 = ugraph.scope.node_names[name2]
      if ugraph:contains(n1) and ugraph:contains(n2) then
	self:orientTwoNodes(ugraph, name1, name2, tonumber(angle)/360*2*math.pi, flag)
	return true
      end
    end
  end
  if f("orient", false) then return end
  if f("orient'", true) then return end
  
  -- Computed during preprocessing:
  local info = ugraph.storage[algorithm]
  if info.from_node and info.from_node.growth_direction ~= "fixed" and algorithm.growth_direction ~= "fixed" then
    local x = info.from_node.pos.x
    local y = info.from_node.pos.y
    local from_angle = info.from_angle or math.atan2(info.to_node.pos.y - y, info.to_node.pos.x - x)
    
    self:rotateGraphAround(ugraph, x, y, from_angle, info.to_angle, info.swap)
  end
end




-- Done

return Orientation