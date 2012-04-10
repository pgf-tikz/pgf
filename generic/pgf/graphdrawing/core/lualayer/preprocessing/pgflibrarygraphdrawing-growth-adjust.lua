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


growth_adjust = {}



--- Precompute the angle of rotation for the growth.

function growth_adjust.prepare_post_layout_orientation(graph, algorithm)

  -- First, compute the angle and the nodes that determine the growth:
  local function growth_fun (node, grow, flag)
    if grow then
      local growth_direction = node.growth_direction or algorithm.growth_direction
      if growth_direction == "fixed" then
	return false
      elseif growth_direction then
	graph[algorithm].rotate_around = {
	  x = node.pos:x(),
	  y = node.pos:y(),
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
	    local x = other.pos:x() - node.pos:x()
	    local y = other.pos:y() - node.pos:y()
	    local angle = math.atan2(y,x)
	    graph[algorithm].rotate_around = {
	      x = node.pos:x(),
	      y = node.pos:y(),
	      from_angle = angle,
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

function growth_adjust.compute_bounding_boxes(graph, algorithm)
  local r = graph[algorithm].rotate_around

  if r then
    local angle = (r.to_angle - r.from_angle)

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


