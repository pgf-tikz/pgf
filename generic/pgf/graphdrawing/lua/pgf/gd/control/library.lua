-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Load declarations from:

require "pgf.gd.control.FineTune"
require "pgf.gd.control.Anchoring"
require "pgf.gd.control.Sublayouts"
require "pgf.gd.control.Orientation"
require "pgf.gd.control.Distances"
require "pgf.gd.control.Components"
require "pgf.gd.control.ComponentAlign"
require "pgf.gd.control.ComponentDirection"
require "pgf.gd.control.ComponentDistance"
require "pgf.gd.control.ComponentOrder"


local InterfaceCore  = require "pgf.gd.interface.InterfaceCore"
local declare        = require "pgf.gd.interface.InterfaceToAlgorithms".declare



---

declare {
  key = "tail anchor",
  type = "string",

  summary = [["  
       Anchors for edges: An edge can have a |tail anchor| and a |head anchor|.
       Ideally, the edge should start at the tail anchor of the
       tail node and end at the head anchor of the head node. A graph
       drawing algorithm may choose to ignore these settings.
  "]]
}
    
---
--

declare {
  key = "head anchor",
  type = "string",

  summary = "See |tail anchor|"
}


---

declare {
  key = "nodes behind edges",
  type = "boolean",
  default = "true",

  summary = "Specifies, that nodes should be drawn behind the edges",
  documentation = [["  
       Once a graph drawing algorithm has determined positions for the nodes,
       they are drawn \emph{before} the edges are drawn; after
       all, it is hard to draw an edge between nodes when their positions
       are not yet known. However, we typically want the nodes to be
       rendered \emph{after} or rather \emph{on top} of the edges. For
       this reason, the default behaviour is that the nodes at their
       final positions are collected in a box that is inserted into the
       output stream only after the edges have been drawn -- which has
       the effect that the nodes will be placed ``on top'' of the
       edges.
      
       This behaviour can be changed using this option. When the key is
       invoked, nodes are placed \emph{behind} the edges.
  "]],
  examples = [["
      \tikz \graph [simple necklace layout, nodes={draw,fill=white},
                    nodes behind edges]
        { subgraph K_n [n=7], 1 [regardless at={(0,-1)}] };    
  "]]
}    

    
---

declare {
  key = "edges behind nodes",
  { key = "nodes behind edges", value = "false" },

  summary = [["  
      This is the default placemenet of edges: Behind the nodes.
  "]],
  examples = [["
      \tikz \graph [simple necklace layout, nodes={draw,fill=white},
                    edges behind nodes]
        { subgraph K_n [n=7], 1 [regardless at={(0,-1)}] };    
 "]]
}

---

declare {
  key = "random seed",
  type = "number",
  initial = "42",

  summary = [["  
       To ensure that the same is always shown in the same way when the
       same algorithm is applied, the random is seed is reset on each call
       of the graph drawing engine. To (possibly) get different results on
       different runs, change this value.
  "]]
}



---

declare {
  key = "weight",
  type = "number",
  initial = 1,

  summary = [["  
       Sets the ``weight'' of an edge or a node. For many algorithms, this
       number tells the algorithm how ``important'' the edge or node is.
       For instance, in a |layered layout|, an edge with a large |weight|
       will be as short as possible.
  "]],
  examples = {
    [["
      \tikz \graph [layered layout] {
        a -- {b,c,d} -- e -- a;
      };
   "]],
   [["
      \tikz \graph [layered layout] {
        a -- {b,c,d} -- e --[weight=3] a;
      };
   "]]
  }
}


---

declare {
  key = "radius",
  type = "number",
  initial = "0",

  summary = [["  
       The radius of a circular object used in graph drawing.
  "]]
}


-- The following collection kinds are internal

declare {
  key = InterfaceCore.sublayout_kind,
  layer = 0
}

declare {
  key = InterfaceCore.subgraph_node_kind,
  layer = 0
}

