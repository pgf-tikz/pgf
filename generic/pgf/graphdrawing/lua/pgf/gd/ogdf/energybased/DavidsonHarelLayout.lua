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
-- @section subsubsection {The Davidson--Harel Layout}
--
-- The configuration is still missing!
--
-- Currently, the implementation is not really usable since it does VERY EVIL fiddling with srand!


local section


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
    
---
declare {
  key = "DavidsonHarelLayout",
  algorithm_written_in_c = "pgf.gd.ogdf.c.CLibrary.DavidsonHarelLayout_call",
  includes = {
    "#include <ogdf/energybased/DavidsonHarelLayout.h>"
  },
  code = [[
      DavidsonHarelLayout layout;
      layout.call(graph_attributes);
  ]],
  summary = "The Davidsonson--Harel layout algorithm.",
  documentation = [["
      The implementation used in |DavidsonsonHarelLayout| is based on
      the following publication:
      
      \begin{itemize}
      \item Ron Davidsonson, Davidson Harel: Drawing Graphs Nicely Using Simulated Annealing.
        \emph{ACM Transactions on Graphics,} 15(4):301--331, 1996.
      \end{itemize}
  "]],
}
	

