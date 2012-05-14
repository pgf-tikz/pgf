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


local LayoutPipeline = require "pgf.gd.control.LayoutPipeline"


--- An example algorithm that demonstrates how the "table with node
-- keys" options works and how new edges can be created.

local SimpleEdgeDemo = pgf.gd.new_algorithm_class {}

function SimpleEdgeDemo:run()
  
  -- As in a SimpleDemo:
  local g = self.digraph
  local alpha = (2 * math.pi) / #g.vertices

  for i,vertex in ipairs(g.vertices) do
    local radius = vertex.options['/graph drawing/node radius'] or g.options['/graph drawing/radius']
    vertex.pos.x = radius * math.cos(i * alpha)
    vertex.pos.y = radius * math.sin(i * alpha)
  end

  -- Now add some edges:
  for _,tail in ipairs(g.vertices) do
    local table = tail.options['/graph drawing/new edges to']
    for head, number in pairs(table or {}) do
      if number > 0 then
	LayoutPipeline.generateEdge (self, tail, head, {})
      end
    end
  end
end

return SimpleEdgeDemo