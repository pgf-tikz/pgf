-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$


-- Imports
local InterfaceToAlgorithms = require "pgf.gd.interface.InterfaceToAlgorithms"
local InterfaceCore         = require "pgf.gd.interface.InterfaceCore"



---
-- This function is called by |declare| for ``module
-- keys,'' a speciality of \textsc{ogdf}.
--
-- TODO: Document!
--
-- (You cannot call this function directly, it is included for
-- documentation purposes only.)
--
-- @param t The table originally passed to |declare|.

local function declare_module (t)
  if not InterfaceCore.keys[t.module_base] then
    InterfaceToAlgorithms.declare {
      key = t.module_base,
      type = "string",
      summary = "internal key"
    }
  end
  t[1] = { key = t.module_base, value = t.module_class }
end


-- Install:

InterfaceToAlgorithms.addHandler(function (t) return t.module_class and not t[1] end, declare_module)
