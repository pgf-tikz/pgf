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
-- Returns a spanning tree of self.events using dfs.

function DepthFirst:run ()
  return SpanningTreeComputation.computeSpanningTree(self.ugraph, true, self.events)
end


return DepthFirst