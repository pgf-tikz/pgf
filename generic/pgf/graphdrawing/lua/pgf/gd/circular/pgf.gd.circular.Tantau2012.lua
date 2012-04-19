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
-- (measured on the circle) of "node distance", but with a minimum
-- spacing of "node sep" and a minimum radius.
--
-- The order of the nodes will be the order they are encountered, the
-- edges actually play no role.

local Tantau2012 = pgf.gd.new_algorithm_class {
  properties = {
    growth_direction = 180
  },
  graph_parameters = {
    minimum_radius = 'circular layout/radius [number]',
  }
}

-- Make public
require("pgf.gd.circular").Tantau2012 = Tantau2012


function Tantau2012:run()
  local n = #self.graph.nodes

  local sib_dists = self:computeNodeDistances ()
  local radii = self:computeNodeRadii()
  local diam, adjusted_radii = self:adjustNodeRadii(sib_dists, radii)
  
  -- Compute total necessary length. For this, iterate over all 
  -- consecutive pairs and keep track of the necessary space for 
  -- this node. We imagine the nodes to be aligned from left to 
  -- right in a line. 
  local carry = 0
  local positions = {}
  local n = #self.graph.nodes
  local function wrap(i) return (i-1)%n + 1 end
  local ideal_pos = 0
  for i = 1,n do
    positions[i] = ideal_pos + carry
    ideal_pos = ideal_pos + sib_dists[i]
    local node_sep =   self.graph.nodes[i]:getOption('/graph drawing/node post sep', self.graph)
                        + self.graph.nodes[wrap(i+1)]:getOption('/graph drawing/node pre sep', self.graph)
    local arc = node_sep + adjusted_radii[i] + adjusted_radii[wrap(i+1)] 
    local needed = carry + arc
    local dist = math.sin( arc/diam ) * diam
    needed = needed + math.max ((radii[i] + radii[wrap(i+1)]+node_sep)-dist, 0)
    carry = math.max(needed-sib_dists[i],0)    
  end
  local length = ideal_pos + carry

  local radius = length / (2 * math.pi)
  for i,node in ipairs(self.graph.nodes) do
    node.pos.x = radius * math.cos(2 * math.pi * positions[i] / length)
    node.pos.y = -radius * math.sin(2 * math.pi * positions[i] / length)
  end
end


function Tantau2012:computeNodeDistances()
  local sib_dists = {}
  local sum_length = 0
  local nodes = self.graph.nodes
  for i=1,#nodes do
     sib_dists[i] = nodes[i]:getOption('/graph drawing/node distance', self.graph)
     sum_length = sum_length + sib_dists[i]
  end

  local missing_length = self.minimum_radius * 2 * math.pi - sum_length
  if missing_length > 0 then
     -- Ok, the sib_dists to not add up to the desired minimum value. 
     -- What should we do? Hmm... We increase all by the missing amount:
     for i=1,#nodes do
	sib_dists[i] = sib_dists[i] + missing_length/#nodes
     end
  end

  sib_dists.total = math.max(self.minimum_radius * 2 * math.pi, sum_length)

  return sib_dists
end


function Tantau2012:computeNodeRadii()
  local radii = {}
  for i,n in pairs(self.graph.nodes) do
    if n.tex.shape == "circle" or n.tex.shape == "ellipse" then
      radii[i] = math.max(n:getTexWidth(),n:getTexHeight())/2
    else
      local w, h = n:getTexWidth(), n:getTexHeight()
      radii[i] = math.sqrt(w*w + h*h)/2
    end
  end
  return radii
end


function Tantau2012:adjustNodeRadii(sib_dists,radii)
  local total = 0
  for i=1,#radii do
    total = total + 2*radii[i] 
            + self.graph.nodes[i]:getOption('/graph drawing/node post sep', self.graph)
	    + self.graph.nodes[i]:getOption('/graph drawing/node pre sep', self.graph)
  end
  total = math.max(total, sib_dists.total)
  local diam = total/(math.pi)

  -- Now, adjust the radii:
  local adjusted_radii = {}
  for i=1,#radii do
    adjusted_radii[i] = (math.pi - 2*math.acos(radii[i]/diam))*diam/2
  end
  
  return diam, adjusted_radii
end


-- done

return Tantau2012