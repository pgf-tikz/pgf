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
}

function SimpleDemo:run()
  local g = self.digraph
  local alpha = (2 * math.pi) / #g.vertices

  for i,vertex in ipairs(g.vertices) do
    local radius = vertex.options['/graph drawing/node radius'] or g.options['/graph drawing/radius']
    vertex.pos.x = radius * math.cos(i * alpha)
    vertex.pos.y = radius * math.sin(i * alpha)
  end

  self.digraph.syntactic_digraph:add {
    pgf.gd.model.Vertex.new {
      pos = pgf.gd.model.Coordinate.new (100,0),
      generated_text = "hallo welt",
      generated_options = { draw = "black" },
    } 
  }
end

return SimpleDemo