-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


return 
[[


Documentation of: SugiyamaLayout 
--------------------------------

Summary: The OGDF implementation of the Sugiyama algorithm.


This layout represents a customizable
implementation of Sugiyama's layout algorithm.
The implementation used in |SugiyamaLayout| is based on the
following publications:

\begin{itemize}
\item Emden R. Gansner, Eleftherios Koutsofios, Stephen
  C. North, Kiem-Phong Vo: A technique for drawing directed
  graphs. \emph{IEEE Trans. Software Eng.} 19(3):214--230, 1993. 
\item Georg Sander: \emph{Layout of compound directed graphs.}
  Technical Report, Universität des Saarlandes, 1996. 
\end{itemize}


Example:

\tikz \graph [SugiyamaLayout] { a -- {b,c,d} -- e -- a };


Example:

\tikz \graph [SugiyamaLayout, grow=right] {
  a -- {b,c,d} -- e -- a
};



Documentation of: SugiyamaLayout.runs
-------------------------------------

Summary: Determines, how many times the crossing minimization is
repeated. 

Each repetition (except for the first) starts with
randomly permuted nodes on each layer. Deterministic behaviour can
be achieved by setting |SugiyamaLayout.runs| to 1.


Documentation of: SugiyamaLayout.transpose
------------------------------------------

Determines whether the transpose step is performed
after each 2-layer crossing minimization; this step tries to
reduce the number of crossings by switching neighbored nodes on
a layer.


Documentation of: SugiyamaLayout.fails
--------------------------------------

The number of times that the number of crossings may
not decrease after a complete top-down bottom-up traversal,
before a run is terminated.



]]