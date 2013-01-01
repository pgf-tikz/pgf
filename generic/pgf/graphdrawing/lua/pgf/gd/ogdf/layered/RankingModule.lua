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
-- @section subsubsection {The Ranking Module}
--

local _


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

    
---
declare {
  key = "LongestPathRanking",
  module_class = "LongestPathRanking",
  module_base  = "RankingModule",
  includes = {
    "#include <ogdf/layered/LongestPathRanking.h>",
  },
  code = [[
      LongestPathRanking* r = new LongestPathRanking;
      r->separateDeg0Layer(algo.bool_option("LongestPathRanking.separateDeg0Layer"));
      r->separateMultiEdges(algo.bool_option("LongestPathRanking.separateMultiEdges"));
      r->optimizeEdgeLength(algo.bool_option("LongestPathRanking.optimizeEdgeLength"));
      if (algo.is_module_set<AcyclicSubgraphModule>())
        r->setSubgraph(algo.new_module<AcyclicSubgraphModule>());
      return r;
  ]],
  summary = "The longest-path ranking algorithm.",
  documentation = [["
      |LongestPathRanking| implements the well-known longest-path
      ranking algorithm, which can be used as first phase in
      |SugiyamaLayout|. The implementation contains a special
      optimization for reducing edge lengths, as well as special
      treatment of mixed-upward graphs (for instance, \textsc{uml}
      class diagrams).  
  "]]
}
    
---
declare {
  key = "LongestPathRanking.separateDeg0Layer",
  type = "boolean",
  initial = "true",
  summary = "If set to true, isolated nodes are placed on a separate layer."
}

---
declare {
  key = "LongestPathRanking.separateMultiEdges",
  type = "boolean",
  initial = "true",
  summary = "If set to true, multi-edges will span at least two layers."
}

---
declare {
  key = "LongestPathRanking.optimizeEdgeLength",
  type = "boolean",
  initial = "true",
  summary = [["If set to true the ranking algorithm tries to reduce
      edge length even if this might increase the height of the
      layout. Choose false, if the longest-path ranking known from the
      literature should be used."]] 
}







---
declare {
  key = "OptimalRanking",
  module_class = "OptimalRanking",
  module_base  = "RankingModule",
  includes = {
    "#include <ogdf/layered/OptimalRanking.h>",
  },
  code = [[
      OptimalRanking* r = new OptimalRanking;
      r->separateMultiEdges(algo.bool_option("OptimalRanking.separateMultiEdges"));
      if (algo.is_module_set<AcyclicSubgraphModule>())
        r->setSubgraph(algo.new_module<AcyclicSubgraphModule>());
      return r;
  ]],
  summary = "The optimal ranking algorithm.",
  documentation = [["
      The |OptimalRanking| implements the LP-based algorithm for
      computing a node ranking with minimal edge lengths, which can
      be used as first phase in |SugiyamaLayout|. 
  "]]
}
        
---
declare {
  key = "OptimalRanking.separateMultiEdges",
  type = "boolean",
  initial = "true",
  summary = "If set to true, multi-edges will span at least two layers."
}






---
declare {
  key = "CoffmanGrahamRanking",
  module_class = "CoffmanGrahamRanking",
  module_base  = "RankingModule",
  includes = {
    "#include <ogdf/layered/CoffmanGrahamRanking.h>",
  },
  code = [[
      CoffmanGrahamRanking* r = new CoffmanGrahamRanking;
      r->width(algo.number_option("CoffmanGrahamRanking.width"));
      if (algo.is_module_set<AcyclicSubgraphModule>())
        r->setSubgraph(algo.new_module<AcyclicSubgraphModule>());
      return r;
  ]],
  summary = "The coffman graham ranking algorithm.",
  documentation = [["
      |CoffmanGrahamRanking| implements a node ranking
      algorithmn based on the coffman graham scheduling algorithm,
      which can be used as first phase in SugiyamaLayout. The aim of
      the algorithm is to ensure that the height of the ranking (the
      number of layers) is kept small.  
  "]]
}
        
---
declare {
  key = "CoffmanGrahamRanking.width",
  type = "number",
  initial = "3",
  summary = "A mysterious width parameter..."
}
