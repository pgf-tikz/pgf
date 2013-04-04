-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- Direct is a class that collects algorithms for computing new
-- versions of a graph where arcs point in certain directions.

local Direct = {}

-- Namespace
require("pgf.gd.lib").Direct = Direct

-- Imports
local Digraph = require "pgf.gd.model.Digraph"


--- Compute a digraph from a syntactic digraph.
--
-- This function takes a syntactic digraph and compute a new digraph
-- where all arrow point in the "semantic direction" of the syntactic
-- arrows. For instance, while "a <- b" will cause an arc from a to be
-- to be added to the syntactic digraph, calling this function will
-- return a digraph in which there is an arc from b to a rather than
-- the other way round. In detail, "a <- b" is tranlated as just
-- described, "a -> b" yields an arc from a to b as expected, "a <-> b"
-- and "a -- b" yield arcs in both directions and, finally, "a -!- b"
-- yields no arc at all.
--
-- @param syntactic_digraph A syntacitic digraph, usually the "input"
-- graph as specified syntactically be the user.
--
-- @return A new "semantic" digraph object.

function Direct.digraphFromSyntacticDigraph(syntactic_digraph)
  local digraph = Digraph.new(syntactic_digraph) -- copy

  -- Now go over all arcs of the syntactic_digraph and turn them into
  -- arcs with the correct direction in the digraph:
  for _,a in ipairs(syntactic_digraph.arcs) do
    for _,m in ipairs(a.syntactic_edges) do
      local direction = m.direction
      if direction == "->" then
	digraph:connect(a.tail, a.head)
      elseif direction == "<-" then
	digraph:connect(a.head, a.tail)
      elseif direction == "--" or direction == "<->" then
	digraph:connect(a.tail, a.head)
	digraph:connect(a.head, a.tail)
      end
      -- Case -!-: No edges...
    end
  end

  return digraph
end


--- Turn an arbitrary graph into a directed graph
--
-- Takes a digraph as input and returns its underlying undirected
-- graph, coded as a digraph. This means that between any two vertices
-- if there is an arc in one direction, there is also one in the other.
--
-- @param digraph A directed graph
--
-- @return The underlying undirected graph of digraph.

function Direct.ugraphFromDigraph(digraph)
  local ugraph = Digraph.new(digraph)

  -- Now go over all arcs of the syntactic_digraph and turn them into
  -- arcs with the correct direction in the digraph:
  for _,a in ipairs(digraph.arcs) do
    ugraph:connect(a.head,a.tail)
    ugraph:connect(a.tail,a.head)
  end

  return ugraph
end




-- Done

return Direct