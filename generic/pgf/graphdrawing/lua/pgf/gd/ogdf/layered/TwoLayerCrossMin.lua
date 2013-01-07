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
-- @section subsubsection {The Two Layer Crossing Minimization}
--

local _


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare


---
declare {
  key = "BarycenterHeuristic",
  module_class = "BarycenterHeuristic",
  module_base  = "TwoLayerCrossMin",
  includes = {
    "#include <ogdf/layered/BarycenterHeuristic.h>"
  },
  code = [[
      return new BarycenterHeuristic;
  ]],
  summary = "The barycenter heuristic for 2-layer crossing minimization.",
}



---
declare {
  key = "GreedyInsertHeuristic",
  module_class = "GreedyInsertHeuristic",
  module_base  = "TwoLayerCrossMin",
  includes = {
    "#include <ogdf/layered/GreedyInsertHeuristic.h>"
  },
  code = [[
      return new GreedyInsertHeuristic;
  ]],
  summary = "The greedy-insert heuristic for 2-layer crossing minimization.",
}


---
declare {
  key = "SiftingHeuristic",
  module_class = "SiftingHeuristic",
  module_base  = "TwoLayerCrossMin",
  includes = {
    "#include <ogdf/layered/SiftingHeuristic.h>"
  },
  code = [[
      SiftingHeuristic* h = new SiftingHeuristic;
      if (algo.is_option("SiftingHeuristic.strategy")) {
	std::string strategy = algo.string_option("SiftingHeuristic.strategy");
	if (strategy == "left_to_right")
          h->strategy(SiftingHeuristic::left_to_right);
	else if (strategy == "desc_degree")
	  h->strategy(SiftingHeuristic::desc_degree);
	else if (strategy == "random")
	  h->strategy(SiftingHeuristic::random);
      }
      return h;
  ]],
  summary = "The sifting heuristic for 2-layer crossing minimization.",
}

---
declare {
  key = "SiftingHeuristic.strategy",
  type = "string",
  summary = "Sets a so-called ``sifting strategy.''",
  documentation = [["
      The following values are permissible: |left_to_right|,
      |desc_degree|, and |random|.  
  "]]
}
    
---
declare {
  key = "MedianHeuristic",
  module_class = "MedianHeuristic",
  module_base  = "TwoLayerCrossMin",
  includes = {
    "#include <ogdf/layered/MedianHeuristic.h>"
  },
  code = [[
      return new MedianHeuristic;
  ]],
  summary = "The median heuristic for 2-layer crossing minimization.",
}



---
declare {
  key = "SplitHeuristic",
  module_class = "SplitHeuristic",
  module_base  = "TwoLayerCrossMin",
  includes = {
    "#include <ogdf/layered/SplitHeuristic.h>"
  },
  code = [[
      return new SplitHeuristic;
  ]],
  summary = "The split heuristic for 2-layer crossing minimization.",
}
