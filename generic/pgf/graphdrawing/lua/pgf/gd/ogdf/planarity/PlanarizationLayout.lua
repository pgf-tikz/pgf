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
-- @section subsection {Planarization Layout}
--

local _


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

---
declare {
  key = "PlanarizationLayout",
  algorithm_written_in_c = "pgf.gd.ogdf.c.CLibrary.PlanarizationLayout_call",
  preconditions = {
    connected = true,
    loop_free = true,
  },
  postconditions = {
    fixed = true
  },
  includes = {
    "#include <ogdf/planarity/PlanarizationLayout.h>"
  },
  code = [[
      PlanarizationLayout layout;
      layout.preprocessCliques(bool_option("PlanarizationLayout.preprocessCliques"));
      layout.minCliqueSize(static_cast<int>(number_option("PlanarizationLayout.minCliqueSize")));

      if (is_module_set<LayoutPlanRepModule>())
        layout.setPlanarLayouter(new_module<LayoutPlanRepModule>());
	
      layout.call(graph_attributes);
  ]],
  summary = "Laying out planar graphs.",
  documentation = [["
      |PlanarizationLayout| is a customizable layout algorithms for
      drawing planar graphs. The implementation used in
      PlanarizationLayout is based on the following publication:
 
      \begin{itemize}
      \item C. Gutwenger, P. Mutzel: An Experimental Study of Crossing
        Minimization Heuristics. \emph{11th International Symposium on Graph
        Drawing 2003, Perugia (GD '03),} LNCS 2912, pp. 13-24, 2004.
      \end{itemize}
  "]],
}
	

---
declare {
  key = "PlanarizationLayout.preprocessCliques",
  type = "boolean",
  initial = "false",
  summary = "Specifies, whether clique preprocessing is applied.",
  documentation = [["
      If set to true, a preprocessing for cliques (complete subgraphs)
      is performed and cliques will be laid out in a special form (straight-line,
      not orthogonal). The preprocessing may reduce running time and improve
      layout quality if the input graphs contains dense subgraphs.   
  "]]
}
    


---
declare {
  key = "PlanarizationLayout.minCliqueSize",
  type = "number",
  initial = "10",
  summary = [["If preprocessing of cliques is enabled, this option
      determines the minimal size of cliques to search for."]]
}



      
-- Load modules:
    
require "pgf.gd.ogdf.planarity.LayoutPlanRepModule"
    