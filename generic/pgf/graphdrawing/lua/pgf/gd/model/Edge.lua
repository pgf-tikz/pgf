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
-- An |Edge| is a ``syntactic'' connection between two
-- vertices that represents a connection present in the syntactic
-- digraph. Unlike an |Arc|, |Edge| objects are not controlled by the
-- |Digraph| class. Also unlike |Arc| objects, there can be several
-- edges betwen the same vertices, namely whenever several such edges
-- are present in the syntactic digraph.
--
-- In detail, the relationship between arcs and edges is as follows:
-- If there is an |Edge| between two vertices $u$ and $v$ in the
-- syntactic digraph, there will be an |Arc| from $u$ to $v$ and the
-- array |syntactic_edges| of this |Arc| object will contain the
-- |Edge| object. In particular, if there are several edges between
-- the same vertices, all of these edges will be part of the array in
-- a single |Arc| object.
--
-- Edges, like arcs, are always directed from a |tail| vertex to a
-- |head| vertex; this is true even for undirected vertices. The
-- |tail| vertex will always be the vertex that came first in the
-- syntactic specification of the edge, the |head| vertex is the
-- second one. Whether
-- an edge is directed or not depends on the |direction| of the edge, which
-- may be one of the following:
--
-- \begin{enumerate}
-- \item |"->"|
-- \item |"--"|
-- \item |"<-"|
-- \item |"<->"|
-- \item |"-!-"|
-- \end{enumerate}
-- 
--
-- @field head The head vertex of this edge.
--
-- @field tail The tail vertex of this edge.
--
-- @field event The creation |Event| of this edge.
--
-- @field options A table of options that contains user-defined options.
--
-- @field direction One of the directions named above.
--
-- @field path An array of |Coordinate| objects and |strings| that
-- describe the path of the edge. The coordinates are interpreted
-- relative to the position of the |tail| vertex and the path starts
-- at this vertex. The following strings are allowed in
-- this array:
--
-- \begin{itemize}
-- \item |"moveto"| The line's path should stop at the current
-- position and then start anew at the next coordinate in the array.
-- \item |"lineto"| The line should continue from the current position
-- to the next coordinate in the array. Since this is the default
-- operation if none is given, this string may also be omitted.
-- \item |"curveto"| The line should continue form the current
-- position with a Bézier curve that is specified bz the next three
-- |Coordinate| objects (in the usual manner).
-- \item |"closepath"| The line's path should be ``closed'' in the sense
-- that the current subpath that was started with the most recent
-- moveto operation should now form a closed curve.
-- \end{itemize}
--
-- @field generated_options This is an options array that is generated
-- by the algorithm. When the edge is rendered later on, this array
-- will be passed back to the display layer. The syntax is the same as
-- for the |declare_parameter_sequence| function, see
-- |InterfaceToAlgorithms|. 

local Edge = {}
Edge.__index = Edge


-- Namespace

require("pgf.gd.model").Edge = Edge


-- Imports

local Storage      = require "pgf.gd.lib.Storage"


--- 
-- Create a new edge. The |initial| parameter allows you to setup
-- some initial values.
--
-- @usage 
--\begin{codeexample}[code only]
--local v = Edge.new { tail = v1, head = v2 }
--\end{codeexample} 
--
-- @param initial Values to override defaults. --
-- @return A new edge object.
--
function Edge.new(values)
  local new = {}
  for k,v in pairs(values) do
    new[k] = v
  end
  new.generated_options = new.generated_options or {}
  new.path              = new.path or {}
  return setmetatable(new, Edge)
end



--
-- Returns a string representation of an edge. This is mainly for debugging.
--
-- @return The Edge as a string.
--
function Edge:__tostring()
  return tostring(self.tail) .. self.direction .. tostring(self.head)
end


-- Done

return Edge