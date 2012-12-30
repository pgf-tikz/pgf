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
-- @section subsubsection {The ``Hello World'' of Graph Drawing -- Written in C}

local section


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

---
declare {
  key = "fast simple demo layout",
  algorithm_written_in_c = "pgf.gd.examples.c.FastSimpleDemo.fast_hello_world",
  summary = "This algorithm is a reimplementation of the |SimpleDemo| algorithm, but written in~C.",
  documentation = [["  
      Just like the |SimpleDemo| algorithm, this algorithm arranges
      the nodes of a graph in a circle (without paying heed to the sizes of the
      nodes or to the edges). Its main purpose is to show how C code
      can access the Lua representation of graphs. See
      Section~\ref{section-algorithms-in-c} of the manual for detais.
  "]],
}


