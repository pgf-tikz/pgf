-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local key           = require 'pgf.gd.doc'.key
local documentation = require 'pgf.gd.doc'.documentation
local summary       = require 'pgf.gd.doc'.summary
local example       = require 'pgf.gd.doc'.example


--------------------------------------------------------------------------------
key           "SugiyamaLayout"
summary       "The OGDF implementation of the Sugiyama algorithm."

documentation 
[[
This layout represents a customizable implementation of Sugiyama's
layout algorithm. The implementation used in |SugiyamaLayout| is based
on the following publications:
    
\begin{itemize}
\item Emden R. Gansner, Eleftherios Koutsofios, Stephen
  C. North, Kiem-Phong Vo: A technique for drawing directed
  graphs. \emph{IEEE Trans. Software Eng.} 19(3):214--230, 1993. 
\item Georg Sander: \emph{Layout of compound directed graphs.}
  Technical Report, Universität des Saarlandes, 1996. 
\end{itemize}
]]

example
[[
\tikz \graph [SugiyamaLayout] { a -- {b,c,d} -- e -- a };
]]

example     
[[
\tikz \graph [SugiyamaLayout, grow=right] {
  a -- {b,c,d} -- e -- a
};
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "SugiyamaLayout.runs"
summary       "Determines, how many times the crossing minimization is repeated."
documentation 
[[
Each repetition (except for the first) starts with
randomly permuted nodes on each layer. Deterministic behaviour can
be achieved by setting |SugiyamaLayout.runs| to 1.
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "SugiyamaLayout.transpose"
documentation
[[
Determines whether the transpose step is performed
after each 2-layer crossing minimization; this step tries to
reduce the number of crossings by switching neighbored nodes on
a layer.
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "SugiyamaLayout.fails"
documentation
[[
The number of times that the number of crossings may
not decrease after a complete top-down bottom-up traversal,
before a run is terminated.
]]
--------------------------------------------------------------------------------

