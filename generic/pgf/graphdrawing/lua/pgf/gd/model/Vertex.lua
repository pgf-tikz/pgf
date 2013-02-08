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
-- A |Vertex| instance models a node of graphs. Each |Vertex| object can be an 
-- element of any number of graphs (whereas an |Arc| object can only be an
-- element of a single graph). 
-- 
-- When a vertex is added to a digraph |g|, two tables are created in
-- the vertex' storage: An array of incoming arcs (with respect to
-- |g|) and an array of outgoing arcs (again, with respect to
-- |g|). The fields are managed by the |Digraph| class and should not
-- be modified directly.
--
-- Note that a |Vertex| is an abstraction of \tikzname\ nodes; indeed
-- that objective is to ensure that, in principle, we can use them
-- independently of \TeX. For this reason, you will not find any
-- references to |tex| inside a |Vertex|; this information is only
-- available in the syntactic digraph.
--
-- @field pos A coordinate object that stores the position where the
-- vertex should be placed on the canvas. The main objective of graph drawing
-- algorithms is to update this coordinate.
--
-- @field name An optional string that is used as a textual representation
--        of the node.
--
-- @field hull An array of coordinate that should be interpreted relative
--        to the pos field. They should describe a convex hull of the
--        node corresponding to this vertex.
--
-- @field hull_center A coordinate storing the center of the
-- |hull|. Typically, this will be the origin.
--
-- @field options A table of options that contains user-defined options.
--
-- @field shape A string describing the shape of the node (like |rectangle|
--        or |circle|).
--
-- @field kind A string describing the kind of the node. For instance, a
--        node of type |"dummy"| does not correspond to any real node in
--        the graph but is used by the graph drawing algorithm.
--
-- @field event The |Event| when this vertex was created (may be |nil|
-- if the vertex is not part of the syntactic digraph).
--
local Vertex = {}
Vertex.__index = Vertex


-- Namespace

require("pgf.gd.model").Vertex = Vertex


-- Imports

local Coordinate   = require "pgf.gd.model.Coordinate"
local Storage      = require "pgf.gd.lib.Storage"


--- 
-- Create a new vertex. The |initial| parameter allows you to setup
-- some initial values.
--
-- @usage 
--\begin{codeexample}[code only]
--local v = Vertex.new { name = "hello", pos = Coordinate.new(1,1) }
--\end{codeexample} 
--
-- @param initial Values to override default node settings. The
-- following are permissible:
-- \begin{description}
-- \item[|pos|] Initial position of the node.
-- \item[|name|] The name of the node. It is optional to define this.
-- \item[|hull|] An array of coordinate objects. It will not
-- be copied, but referenced. If not given, an array with the only
-- entry being the origin is used.
-- \item[\texttt{hull\_center}] A coordinate storing the ``center'' of the
-- hull. Typically, this will be the origin, which is also the default
-- which this field is not given.
-- \item[|options|] An options table for the vertex.
-- \item[|shape|] A string describing the shape. If not given, |"none"| is used.
-- \item[|kind|] A kind like |"node"| or |"dummy"|. If not given, |"dummy"| is used.
-- \end{description}
--
-- @field incomings A table indexed by |Digraph| objects. For each
-- digraph, the table entry is an array of all vertices from which
-- there is an |Arc| to this vertex. This field is internal and may
-- not only be accessed by the |Digraph| class.
-- @field outgoings Like |incomings|, but for outgoing arcs.
--
-- @return A newly allocated node.
--
function Vertex.new(values)
  local new = {
    incomings = Storage.new(),
    outgoings = Storage.new()
  }
  for k,v in pairs(values) do
    new[k] = v
  end
  new.hull = new.hull or { Coordinate.new(0,0) }
  new.hull_center = new.hull_center or Coordinate.new(0,0)
  new.shape = new.shape or "none"
  new.kind = new.kind or "dummy"
  new.pos = new.pos or Coordinate.new(0,0)
  return setmetatable (new, Vertex)
end



--
-- Returns a string representation of an arc. This is mainly for debugging
--
-- @return The Arc as string.
--
function Vertex:__tostring()
  return self.name or tostring(self.hull)
end


-- Done

return Vertex