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
-- @section subsection {Balloon Layout}
--

local _


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

---
declare {
  key = "BalloonLayout",
  algorithm_written_in_c = "pgf.gd.ogdf.c.CLibrary.BalloonLayout_call",
  preconditions = {
    connected = true
  },
  includes = {
    "#include <ogdf/misclayout/BalloonLayout.h>"
  },
  code = [[
      BalloonLayout layout;
      layout.call(graph_attributes);
  ]],
  summary = "A ``balloon layout''.",
  documentation = [["
      This algorithm computes a radial (balloon) layout based on a
      spanning tree. The algorithm is partially based on the paper
      \emph{On Balloon Drawings of Rooted Trees} by Lin and Yen and on
      \emph{Interacting with Huge Hierarchies: Beyond Cone Trees} by
      Carriere and Kazman.
  "]],
}
