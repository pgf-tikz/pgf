-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$


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

local ogdf


-- Load the C++ code:

require "pgf.gd.ogdf.c.ScriptingOGDF"
