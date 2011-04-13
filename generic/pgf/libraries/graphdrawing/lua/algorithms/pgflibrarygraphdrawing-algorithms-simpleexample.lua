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

--- A very, yery simple node placing algorithm for demonstration purposes.
-- All nodes are positioned on a fixed size circle.
function drawGraphAlgorithm_simpleexample(graph)
   local radius = graph:getOption("radius") or 20
   local nodeCount = 0

   for node in values(graph.nodes) do
      nodeCount = nodeCount + 1
   end

   local alpha = (2 * math.pi) / nodeCount
   local i = 0
   for node in values(graph.nodes) do
      -- the interesting part...
      node.pos.x = radius * math.cos(i * alpha)
      node.pos.y = radius * math.sin(i * alpha)
      i = i + 1
   end
end
