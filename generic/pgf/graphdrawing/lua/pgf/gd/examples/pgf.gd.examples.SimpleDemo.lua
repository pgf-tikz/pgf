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
-- All nodes are positioned on a circle, independently of which edges are present...

local SimpleDemo = pgf.gd.new_algorithm_class {
  properties = { works_only_on_connected_graphs = true },
  graph_parameters = { radius = "/graph drawing/radius" }
}

function SimpleDemo:run()
  local alpha = (2 * math.pi) / #self.digraph.vertices

  for i,vertex in ipairs(self.digraph.vertices) do
    local radius = vertex.options['/graph drawing/node radius'] or self.radius
    vertex.pos.x = radius * math.cos(i * alpha)
    vertex.pos.y = radius * math.sin(i * alpha)
  end
end

return SimpleDemo