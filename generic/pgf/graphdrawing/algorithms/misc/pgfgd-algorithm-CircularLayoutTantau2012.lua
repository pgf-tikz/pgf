-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- A circular layout
--
-- This layout places the nodes on a circle, starting at the growth
-- direction.  
--
-- The objective is that nodes are ideally spaced at a distance
-- (measured on the circle) of "sibling distance", but with a minimum
-- spacing of "sibling sep". Instead of a sibling distance, the
-- "radius" key may also be specified. 
--
-- The order of the nodes will be the order they are encountered, the
-- edges actually play no role.

graph_drawing_algorithm { 
  name = 'CircularLayoutTantau2012',
  properties = {
    growth_direction = 180
  },
  graph_parameters = {
    sibling_distance = {'sibling distance', tonumber},
    sibling_sep      = {'sibling sep', tonumber}
  }
}

function CircularLayoutTantau2012:run()
  local n = #self.graph.nodes

  local sib_dist = self:computeSiblingDistance ()
  Sys:debug(sib_dist)
  local radii = self:computeNodeRadii()
  
  
  -- Compute total necessary length. For this, iterate over all 
  -- consecutive pairs and keep track of the necessary space for 
  -- this node. We imagine the nodes to be aligned from left to 
  -- right in a line. 
  local carry = 0
  local positions = {}
  local n = #self.graph.nodes
  local function wrap(i) return (i-1)%n + 1 end
  for i = 1,n do
    positions[i] = (i-1)*sib_dist + carry
    local needed = carry + radii[i] + self.sibling_sep + radii[wrap(i+1)]
    carry = math.max(needed-sib_dist,0)    
  end
  local length = n*sib_dist + carry

  local radius = length / (2 * math.pi)
  for i,node in ipairs(self.graph.nodes) do
      node.pos:set{
	x = radius * math.cos(2 * math.pi * positions[i] / length),
	y = radius * math.sin(2 * math.pi * positions[i] / length)
      }
   end
end


function CircularLayoutTantau2012:computeSiblingDistance()
  local rad = self.graph:getOption('/graph drawing/circular layout/radius')

  if rad then
    return tonumber(rad) * 2 * math.pi / #self.graph.nodes
  else
    return self.sibling_distance
  end
end


function CircularLayoutTantau2012:computeNodeRadii()
  local radii = {}
  for i,n in pairs(self.graph.nodes) do
    radii[i] = math.max(n:getTexWidth(), n:getTexHeight())/2
  end
  return radii
end