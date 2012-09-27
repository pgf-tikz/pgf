-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- An implementation of the Reingold-Tilford algorithm
--
-- This implemenation follows the ideas outlined in
--
-- A. Brüggemann-Klein, D. Wood, Drawing trees nicely with TeX,
-- Electronic Publishing, 2(2), 101-115, 1989

local ReingoldTilford1981 = pgf.gd.new_algorithm_class {
  works_only_on_connected_graphs = true,
  needs_a_spanning_tree = true,
  growth_direction = 90,
}



-- local Declarations = require "pgf.gd.interface.Declarations"

-- ---
-- -- An implementation of the Reingold-Tilford algorithm
-- --
-- -- This implemenation follows the ideas outlined in
-- --
-- -- A. Brüggemann-Klein, D. Wood, Drawing trees nicely with TeX,
-- -- Electronic Publishing, 2(2), 101-115, 1989

-- local ReingoldTilford1981 = Declarations.algorithm {
--   requires = { "connected", "tree" },
--   delivers = { "upward oriented" }
-- }

-- Declarations.graph_transformation 


-- ---
-- -- Toggles, whether an extended version of the graph should be drawn.   
-- --
-- -- @codeexample
-- -- 
-- -- \tikz \graph [tree layout, missing nodes get space=false]
-- --   { a -- {b, , c -- {e, f} };
-- --
-- Declarations.key ("missing nodes get space", "boolean")
--
-- Declarations.style ("ternary tree", { ...=..., ...=..., })



-- Imports
local layered = require "pgf.gd.layered"


function ReingoldTilford1981:run()
  
  local root = self.spanning_tree.storage.root
  
  self.extended_version = self.digraph.options['/graph drawing/tree layout/missing nodes get space']
  
  self:precomputeDescendants(root, 1)
  self:computeHorizontalPosition(root)
  layered.arrange_layers_by_baselines(self, self.ugraph)

end


function ReingoldTilford1981:precomputeDescendants(node, depth)
  local descendants = { node }

  for _,arc in ipairs(self.spanning_tree:outgoing(node)) do
    local head = arc.head
    self:precomputeDescendants(head, depth+1)
    for _,d in ipairs(head.storage[self].descendants) do
      descendants[#descendants + 1] = d
    end
  end

  node.storage[self].layer = depth
  node.storage[self].descendants = descendants
end



function ReingoldTilford1981:computeHorizontalPosition(node)
  
  local children = self.spanning_tree:outgoing(node)

  node.pos.x = 0

  local child_depth = node.storage[self].layer + 1

  if #children > 0 then
    -- First, compute positions for all children:
    for i=1,#children do
      self:computeHorizontalPosition(children[i].head)
    end
    
    -- Now, compute minimum distances and shift them
    local right_borders = {}

    for i=1,#children-1 do
      
      local local_right_borders = {}
      
      -- Advance "right border" of the subtree rooted at
      -- the i-th child
      for _,d in ipairs(children[i].head.storage[self].descendants) do
	local layer = d.storage[self].layer
	local x     = d.pos.x	  
	if self.extended_version or not (layer > child_depth and d.kind == "dummy") then
	  if not right_borders[layer] or right_borders[layer].pos.x < x then
	    right_borders[layer] = d
	  end
	  if not local_right_borders[layer] or local_right_borders[layer].pos.x < x then
	    local_right_borders[layer] = d
	  end
	end
      end

      local left_borders = {}
      -- Now left for i+1 st child
      for _,d in ipairs(children[i+1].head.storage[self].descendants) do
	local layer = d.storage[self].layer
	local x     = d.pos.x	  
	if self.extended_version or not (layer > child_depth and d.kind == "dummy") then
	  if not left_borders[layer] or left_borders[layer].pos.x > x then
	    left_borders[layer] = d
	  end
	end
      end

      -- Now walk down the lines and try to find out what the minimum
      -- distance needs to be.

      local shift = -math.huge
      local first_dist = left_borders[child_depth].pos.x - local_right_borders[child_depth].pos.x
      local is_significant = false

      for layer,n2 in pairs(left_borders) do
	local n1 = right_borders[layer]
	if n1 then
	  shift = math.max(
	    shift, 
	    layered.ideal_sibling_distance(self, self.ugraph, n1, n2) + n1.pos.x - n2.pos.x
	  )
	end
	if local_right_borders[layer] then
	  if layer > child_depth and
	    (left_borders[layer].pos.x - local_right_borders[layer].pos.x <= first_dist) then 
	    is_significant = true
	  end
	end
      end

      if is_significant then
	shift = shift + self.ugraph.options['/graph drawing/tree layout/significant sep']
      end

      -- Shift all nodes in the subtree by shift:
      for _,d in ipairs(children[i+1].head.storage[self].descendants) do
	d.pos.x = d.pos.x + shift
      end
    end
    
    -- Finally, position root in the middle:
    node.pos.x = (children[1].head.pos.x + children[#children].head.pos.x) / 2
  end
end



return ReingoldTilford1981