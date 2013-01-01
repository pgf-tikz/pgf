-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


---
-- @section subsubsection {Computing Acyclic Subgraphs Module}
--

local _


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

    
---
declare {
  key = "DfsAcyclicSubgraph",
  module_class = "DfsAcyclicSubgraph",
  module_base  = "AcyclicSubgraphModule",
  includes = {
    "#include <ogdf/layered/DfsAcyclicSubgraph.h>",
  },
  code = [[
      return new DfsAcyclicSubgraph;
  ]],
  summary = "DFS-based algorithm for computing a maximal acyclic subgraph.",
  documentation = [["
      The algorithm simply removes all DFS-backedges and works in linear-time.
  "]]
}
    

    
---
declare {
  key = "GreedyCycleRemoval",
  module_class = "GreedyCycleRemoval",
  module_base  = "AcyclicSubgraphModule",
  includes = {
    "#include <ogdf/layered/GreedyCycleRemoval.h>",
  },
  code = [[
      return new GreedyCycleRemoval;
  ]],
  summary = "Greedy algorithm for computing a maximal acyclic subgraph.",
  documentation = [["
      The algorithm applies a greedy heuristic to compute a maximal
      acyclic subgraph and works in linear-time. 
  "]]
}
    
