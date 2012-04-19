-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- A trivial node placing algorithm for demonstration purposes.
-- All nodes are positioned on a fixed size circle.

local SimpleDemo = pgf.gd.new_algorithm_class {
  graph_parameters = { radius = "radius [number]" }
}

function SimpleDemo:run()
  local alpha = (2 * math.pi) / #self.graph.nodes

  for i,node in ipairs(self.graph.nodes) do
    local node_radius = tonumber(node:getOption('/graph drawing/node radius') or self.radius)
    node.pos.x = node_radius * math.cos(i * alpha)
    node.pos.y = node_radius * math.sin(i * alpha)
  end
end

return SimpleDemo