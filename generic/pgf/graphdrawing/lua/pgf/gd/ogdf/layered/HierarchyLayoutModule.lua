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
-- @section subsubsection {The Hierarchy Layout Modules}
--

local _


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare


-- Set the default of the HierarchyLayoutModule

declare {
  key = "HierarchyLayoutModule",
  type = "string",
  initial = "FastHierarchyLayout",
  summary = "internal key"
}

    
---
declare {
  key = "FastHierarchyLayout",
  module_class = "FastHierarchyLayout",
  module_base  = "HierarchyLayoutModule",
  includes = {
    "#include <ogdf/layered/FastHierarchyLayout.h>",
  },
  code = [[
      FastHierarchyLayout* r = new FastHierarchyLayout;
      r->layerDistance(algo.number_option("level pre sep") + algo.number_option("level post sep"));
      r->nodeDistance(algo.number_option("sibling pre sep") + algo.number_option("sibling post sep"));
      r->fixedLayerDistance(algo.bool_option("FastHierarchyLayout.fixedLayerDistance"));
      return r;
  ]],
  summary = "Coordinate assignment phase for the Sugiyama algorithm by Buchheim et al.",
  documentation = [["
      This class implements a hierarchy layout algorithm, that is, it
      layouts hierarchies with a given order of nodes on each
      layer. It is used as a third phase of the Sugiyama algorithm.  

      All edges of the layout will have at most two
      bends. Additionally, for each edge having exactly two bends, the
      segment between them is drawn vertically. This applies in
      particular to the long edges arising in the first phase of the
      Sugiyama algorithm. 

      The implementation is based on:

      \begin{itemize}
      \item 
      Christoph Buchheim, Michael Jünger, Sebastian Leipert: A Fast
      Layout Algorithm for k-Level Graphs. \emph{Proc. Graph
	Drawing 2000}, volumne 1984 of LNCS, pages 229--240, 2001.
      \end{itemize}
  "]]
}
    
---
declare {
  key = "FastHierarchyLayout.fixedLayerDistance",
  type = "boolean",
  initial = "false",
  summary = "If true, the distance between neighbored layers is fixed, otherwise variable."
}




---
declare {
  key = "FastSimpleHierarchyLayout",
  module_class = "FastSimpleHierarchyLayout",
  module_base  = "HierarchyLayoutModule",
  includes = {
    "#include <ogdf/layered/FastSimpleHierarchyLayout.h>",
  },
  code = [[
      FastSimpleHierarchyLayout* r = new FastSimpleHierarchyLayout(
	static_cast<int>(algo.number_option("sibling distance")),
	static_cast<int>(algo.number_option("level distance")));
      return r;
  ]],
  summary = "Coordinate assignment phase for the Sugiyama algorithm by Ulrik Brandes and Boris Köpf.",
  documentation = [["
      This class implements a hierarchy layout algorithm, that is, it
      layouts hierarchies with a given order of nodes on each
      layer. It is used as a third phase of the Sugiyama algorithm. 

      The algorithm runs in three phases:
      \begin{enumerate}
      \item Alignment (4x)
      \item Horizontal Compactation (4x)
      \item Balancing
      \end{enumerate}
      The alignment and horizontal compactification phases are calculated
      downward, upward, left-to-right and right-to-left. The four
      resulting layouts are combined in a balancing step. 

      Warning: The implementation is known to not always produce a
      correct layout. Therefore this Algorithm is for testing purpose
      only. 

      The implementation is based on:

      \begin{itemize}
      \item 
        Ulrik Brandes, Boris Köpf: Fast and Simple Horizontal
        Coordinate Assignment. \emph{LNCS} 2002, Volume 2265/2002,
        pp. 33--36  
      \end{itemize}
  "]]
}
