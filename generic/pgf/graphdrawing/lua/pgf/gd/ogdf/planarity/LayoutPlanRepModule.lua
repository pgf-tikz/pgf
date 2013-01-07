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
-- @section subsubsection {The Planar Layout Algorithm}
--
-- The planar layout algorithm is used to compute a planar layout
-- of the planarized representation resulting from the crossing
-- minimization step. Planarized representation means that edge crossings
-- are replaced by dummy nodes of degree four, so the actual layout
-- algorithm obtains a planar graph as input. By default, the planar
-- layout algorithm produces an orthogonal drawing.

local _


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare


-- Set default
declare {
  key = "LayoutPlanRepModule",
  type = "string",
  initial = "OrthoLayout"
}
    
---
declare {
  key = "OrthoLayout",
  module_class = "OrthoLayout",
  module_base  = "LayoutPlanRepModule",
  includes = {
    "#include <ogdf/orthogonal/OrthoLayout.h>",
  },
  code = [[
      OrthoLayout* r = new OrthoLayout;
      r->separation(algo.number_option("OrthoLayout.separation"));
      return r;
  ]],
  summary = "Represents planar orthogonal drawing algorithm.",
  documentation = "Most configuration still missing!"
}

    
---
declare {
  key = "OrthoLayout.separation",
  type = "length",
  initial = "40",
  summary = "The minimum distance between edges and vertices."
}


