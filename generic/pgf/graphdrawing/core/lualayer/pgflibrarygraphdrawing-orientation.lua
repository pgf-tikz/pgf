-- Copyright 2012 by Till Tantau, replacing code by Jannis Pohlmann from 2011
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

pgf.module("pgf.graphdrawing")

orientation = {}



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

function orientation.rotate_graph_around(graph, around_x, around_y, from, to, swap)
   
   local function update_pos (point)
      local x = point:x()
      local y = point:y()
      
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
      point:set { x = x; y = y }
   end

   -- perform the rotation
   for node in table.value_iter(graph.nodes) do
      update_pos (node.pos)
   end
   for edge in table.value_iter(graph.edges) do
      for point in table.value_iter(edge.bend_points) do
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

function orientation.orient_two_nodes(graph, first_node, second_node,
				      target_angle, swap)
   if first_node and second_node then
      -- Compute angle between first_node and second_node:
      local x = second_node.pos:x() - first_node.pos:x()
      local y = second_node.pos:y() - first_node.pos:y()
      
      local angle = math.atan2(y,x)

      orientation.rotate_graph_around(graph, first_node.pos:x(),
				      first_node.pos:y(), angle, target_angle, swap)
   end
end




--- Helper function for graphs with a growth direction
--
-- This function can be called by algorithms that orient a graph in
-- a way that permits speaking of a natural "direction of growth", but
-- that do not wish to take the /graph drawing/grow node parameter
-- into account. In this case, they should call this function, the
-- necessary rotations will be performed in the postprocessing. If the
-- natural direction of growth computed by the algorithm is not
-- downward (the default), the direction must be given as a
-- parameter. 
-- 
-- @param graph The graph.

function orientation.algorithm_has_grown_the_graph_in_a_direction(graph, angle)
   local angle = angle or -90
   for _, node in pairs(graph.nodes) do
      node.growth_direction = angle
   end
end


--- Helper function for graphs with a growth direction
--
-- This function is the complement of the previous one; it is to be
-- called when the graph drawing algorithm has, indeed, taken care of
-- the requested grow keys. It will cause the post layout orientation
-- mechanism to "leave the graph alone" (unless, of course, some other
-- orientation keys have been explicitly set).
-- 
-- @param graph The graph.

function orientation.algorithm_has_taken_care_of_user_grow_requests(graph)
   for _, node in pairs(graph.nodes) do
      node.growth_direction = "fixed"
   end
end


--- Perform a post-layout orientation of the graph
--
-- Performs a post-layout orientation of the graph by performing the
-- steps documented in Section~\ref{subsection-graph-orientation-phases}.
-- of the manual.
-- 
-- @param graph The graph.

function orientation.perform_post_layout_steps(graph)
   
   -- Sanity check
   if #graph.nodes < 2 then return end
   
   -- Step 1: Search for an edge with the orient option:
   for _, edge in ipairs(graph.edges) do
      local function f (key, flag)
	 local orient = edge:getOption('/graph drawing/' .. key)
	 if orient then
	    orientation.orient_two_nodes(
	       graph, edge.nodes[1], edge.nodes[2], tonumber(orient)/360*2*math.pi, flag)
	    return true
	 end
      end
      if f("orient", false) then return end
      if f("orient'", true) then return end
   end
   
   -- Step 2: Search for a node with the orient option:
   for _, node in ipairs(graph.nodes) do
      local function f (key, flag)
	 local orient = node:getOption('/graph drawing/' .. key)
	 if orient then
	    local angle, other_name = orient:gmatch('{(.+)}{(.+)}')()
	    local other = graph:findNode(other_name)
	    if other then
	       orientation.orient_two_nodes(graph, node, other, tonumber(angle)/360*2*math.pi, flag)
	       return true
	    end
	 end
      end
      if f("orient", false) then return end
      if f("orient'", true) then return end
   end
   
   -- Step 3: Search for global graph orient options:
   local function f (key, flag)
      local orient = graph:getOption('/graph drawing/' .. key)
      if orient then
	 local angle, name1, name2 = orient:gmatch('{(.+)}{(.+)}{(.+)}')()
	 local name1 = graph:findNode(name1)
	 local name2 = graph:findNode(name2)
	 if name1 and name2 then
	    orientation.orient_two_nodes(graph, name1, name2, tonumber(angle)/360*2*math.pi, flag)
	    return true
	 end
      end
   end
   if f("orient", false) then return end
   if f("orient'", true) then return end

   -- Step 4: Search for growth keys:
   local function growth_fun (node, grow, flag)
      if grow then
	 if node.growth_direction == "fixed" then
	    return false
	 elseif node.growth_direction then
	    orientation.rotate_graph_around(
	       graph, node.pos:x(), node.pos:y(),
	       tonumber(node.growth_direction)/360*2*math.pi, tonumber(grow)/360*2*math.pi,
	       flag)
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
		  orientation.orient_two_nodes(
		     graph, node, other, tonumber(grow)/360*2*math.pi, flag)
		  return true
	       end
	    end	       
	 end
      end
   end

   for _, node in ipairs(graph.nodes) do
      local grow = node:getOption('/graph drawing/grow')
      if growth_fun(node, grow, false) then return end
      local grow = node:getOption("/graph drawing/grow'")
      if growth_fun(node, grow, true) then return end
   end

   growth_fun(graph.nodes[1], "-90", false)
end





