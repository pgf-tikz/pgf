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
-- @section subsection {Circular Layout}
--

local _


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

---
declare {
  key = "CircularLayout",
  algorithm_written_in_c = "pgf.gd.ogdf.c.CLibrary.circular_layout",
  preconditions = {
    connected = true
  },
  includes = {
    "#include <ogdf/misclayout/CircularLayout.h>"
  },
  code = [[
      CircularLayout layout;
      
      layout.minDistCircle(number_option("CircularLayout.minDistCircle"));
      layout.minDistLevel(number_option("level pre sep")+number_option("level post sep"));
      layout.minDistSibling(number_option("sibling pre sep")+number_option("sibling post sep"));

      layout.call(graph_attributes);
  ]],
  summary = "The circular layout algorithm.",
  documentation = [["
      The implementation used in CircularLayout is based on the following publication: 
      
      \begin{itemize}
      \item Ugur Dogrus\"oz, Brendan Madden, Patrick Madden: Circular
      Layout in the Graph Layout Toolkit. \emph{Proc. Graph Drawing 1996,}
      LNCS 1190, pp. 92--100, 1997.
      \end{itemize}
  "]],
}


---
declare { 
  key = "CircularLayout.minDistCircle",
  type = "length",
  initial = "1em",
  summary = "The minimal distance between nodes on a circle.",
}

---
declare {
  key = "circle sibling sep",
  { key = "CircularLayout.minDistCircle", value="#1" },
  summary = "An alias for |CircularLayout.minDistCircle|."
}