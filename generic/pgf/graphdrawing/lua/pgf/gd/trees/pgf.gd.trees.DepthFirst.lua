-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- A (sub)algorithm for computing spanning trees
--
-- This algorithm will compute a spanning tree of a graph using the
-- depth first method.

local DepthFirst = pgf.gd.new_algorithm_class {}

-- Store in namespace
require("pgf.gd.trees").DepthFirst = DepthFirst

-- Imports
local SpanningTreeComputation = require "pgf.gd.trees.SpanningTreeComputation"


--- Compute a spanning tree of a graph
--
-- The computed spanning tree will be available through the fields
-- algorithm.children of each node and algorithm.spanning_tree_root of
-- the graph.
--
-- @param graph The graph for which the spanning tree should be computed 

function DepthFirst:run ()
  SpanningTreeComputation:computeSpanningTree(self.parent_algorithm, true)
end


return DepthFirst