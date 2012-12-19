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
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

---
-- The Open Graph Drawing Framework (\textsc{ogdf}) is a large,
-- powerful graph drawing system written in C++. This library enables
-- its use inside \tikzname's graph drawing system by translating
-- back-and-forth between Lua and C++.
--
-- Since C++ code is compiled and not interpreted (like Lua), in order
-- to use the present library, you need a compiled version of the
-- \textsc{ogdf} library installed for your particular
-- architecture. 
--
-- @library

local ogdf = require "pgf.gd.ogdf"

ogdf.loaded = true -- Workaround for a bug in LuaTeX loader code


-- Load the adaptor code
local Control = require "pgf.gd.ogdf.c.Control" -- This is a compiled C file
local Bridge  = require "pgf.gd.ogdf.Bridge"    -- This is a Lua file


Control.do_declarations()


-- Declare an algorithm

declare {
  key = "ogdf layered layout",
  algorithm = {
    run =
      function (self)
	Control.run(Bridge.unbridgeGraph, self.digraph, Bridge.bridgeGraph(self.digraph, self))
      end
  },
  postconditions = { upward_oriented = true }
}

declare {
  key = "ogdf force layout",
  algorithm = {
    run =
      function (self)
	Control.run_fmmm(Bridge.unbridgeGraph, self.digraph, Bridge.bridgeGraph(self.digraph, self))
      end
  },
}
