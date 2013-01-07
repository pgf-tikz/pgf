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
-- @section subsection {The FMMM Method}
--
-- The configuration is still missing!

local section


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
    
---
declare {
  key = "FMMMLayout",
  algorithm_written_in_c = "pgf.gd.ogdf.c.CLibrary.FMMMLayout_call",
  includes = {
    "#include <ogdf/energybased/FMMMLayout.h>"
  },
  code = [[
      FMMMLayout layout;
      layout.unitEdgeLength(number_option("node distance")); 
      layout.randSeed(number_option("random seed"));
      layout.newInitialPlacement(false);
      layout.qualityVersusSpeed(FMMMLayout::qvsGorgeousAndEfficient);
      layout.call(graph_attributes);
  ]],
  summary = "The fast multipole multilevel layout algorithm.",
  documentation = [["
      |FMMMLayout| implements a force-directed graph drawing
      method suited also for very large graphs. It is based on a
      combination of an efficient multilevel scheme and a strategy for
      approximating the repulsive forces in the system by rapidly
      evaluating potential fields.
 
      The implementation is based on the following publication:
      
      \begin{itemize}
      \item Stefan Hachul, Michael J\"unger: Drawing Large Graphs with
        a Potential-Field-Based Multilevel Algorithm. \emph{12th
        International Symposium on Graph Drawing 1998 (GD '04)}, New York, LNCS 3383,
        pp. 285--295, 2004.
      \end{itemize}
  "]],
}
	

