-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file contains an example of how a very simple algorithm can be
-- implemented by a user.

pgf.module("pgf.graphdrawing")

--- A trivial node placing algorithm for demonstration purposes.
-- All nodes are positioned on a fixed size circle.
function drawGraphAlgorithm_simple_demo(graph)
   local radius = tonumber(graph:getOption("/graph drawing/radius"))
   local nodeCount = table.count_pairs(graph.nodes)

   local alpha = (2 * math.pi) / nodeCount
   local i = 0
   for node in table.value_iter(graph.nodes) do
      -- the interesting part...
      local node_radius = tonumber(node:getOption('/graph drawing/node radius')
                                   or radius)
      node.pos:set{x = node_radius * math.cos(i * alpha)}
      node.pos:set{y = node_radius * math.sin(i * alpha)}
      i = i + 1
   end
end
