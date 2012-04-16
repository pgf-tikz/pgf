-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file defines an edge class, used in the graph representation.

pgf.module("pgf.graphdrawing")


local lib = require "pgf.gd.lib"


--- A subalgorithm for computing spanning trees
--
-- This algorithm will compute a spanning tree of a graph using the
-- breadth first method.

graph_drawing_algorithm {
  name = 'SpanningTreeBreadthFirst',
}



--- Compute a spanning tree of a graph
--
-- The computed spanning tree will be available through the fields
-- algorithm.children of each node and algorithm.spanning_tree_root of
-- the graph.
--
-- @param graph The graph for which the spanning tree should be computed 

function SpanningTreeBreadthFirst:run ()

  local algorithm = self.parent_algorithm
  local graph = self.graph

  lib.Simplifiers:computeSpanningTree(algorithm, false)
end
