-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local declare       = require "pgf.gd.interface.InterfaceToAlgorithms".declare


---
-- @section subsection {Fine-Tuning Positions of Nodes}
--

local _



---
-- This option allows you to slightly ``nudge'' (move) nodes after
-- they have been positioned by the given offset. The idea is that
-- this nudging is  
-- done after the position of the node has been computed, so nudging
-- has no influence on the actual graph drawing algorithms. This, in
-- turn, means that you can use nudging to ``correct'' or ``optimize''
-- the positioning of nodes after the algorithm has computed something.
--
-- \begin{codeexample}[]
-- \tikz \graph [edges=rounded corners, nodes=draw,
--               layered layout, sibling distance=0] {
--     a -- {b, c, d[nudge=(up:2mm)]} -- e -- a;
--   };
-- \end{codeexample}
--
-- @param offset An offset

declare {
  key = "nudge",
  type = "canvas coordinate"
}

---
-- A shorthand for nudging a node upwards.
--
-- \begin{codeexample}[]
-- \tikz \graph [edges=rounded corners, nodes=draw,
--               layered layout, sibling distance=0] {
--     a -- {b, c, d[nudge up=2mm]} -- e -- a;
--   };
-- \end{codeexample}
--
-- @param distance A distance by which the node is nudges.

declare {
  key = "nudge up",
  { key = "nudge", value = "(0,#1)" }
}

---
-- Like |nudge up|, but downwards.
--
-- @param distance A distance by which the node is nudges.

declare {
  key = "nudge down",
  { key = "nudge", value = "(0,-#1)" }
}

---
-- Like |nudge up|, but left.
--
-- \begin{codeexample}[]
-- \tikz \graph [edges=rounded corners, nodes=draw,
--               layered layout, sibling distance=0] {
--     a -- {b, c, d[nudge left=2mm]} -- e -- a;
--   };
-- \end{codeexample}
--
-- @param distance A distance by which the node is nudges.

declare {
  key = "nudge left",
  { key = "nudge", value = "(-#1,0)" }
}

---
-- Like |nudge left|, but right.
--
-- @param distance A distance by which the node is nudges.

declare {
  key = "nudge right",
  { key = "nudge", value = "(#1,0)" }
}

---
-- Using this option you can provide a position for a node to wish
-- it will be forced after the graph algorithms have run. So, the node
-- is positioned normally and the graph drawing algorithm does not know
-- about the position specified using |regardless at|. However,
-- afterwards, the node is placed there, regardless of what the
-- algorithm has computed (all other nodes are unaffected).
--
-- \begin{codeexample}[]
-- \tikz \graph [edges=rounded corners, nodes=draw,
--               layered layout, sibling distance=0] {
--     a -- {b,c,d[regardless at={(1,0)}]} -- e -- a;
--   };
-- \end{codeexample}
--
-- @param pos A canvas position (a coordinate).

declare {
  key = "regardless at",
  type = "canvas coordinate"
}




---
-- This option combines |desired at| and |regardless at|. Thus, the
-- algorithm is ``told'' about the desired position. If it fails to place
-- the node at the desired position, it will be put there
-- regardless. The name of the key is intended to remind one of a node
-- being ``nailed'' to the canvas.
--
-- @param pos A canvas position (a coordinate).

declare {
  key = "nail at",
  { key = "desired at", value = "#1" },
  { key = "regardless at", value = "#1" }
}

