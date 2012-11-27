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
-- Events are used to communicate ``interesting'' events from the
-- parser to the graph drawing algorithms.
--
-- As a syntactic description of some graph is being parsed, vertices,
-- arcs, and a digraph object representing this graph get
-- constructed. However, even though syntactic annotations such as
-- options for the vertices and arcs are attached to them and can be
-- accessed through the graph objects, some syntactic inforamtion is
-- neither represented in the digraph object nor in the vertices and
-- the arcs. A typical example is a ``missing'' node in a tree: Since
-- it is missing, there is neither a vertex object nor arc objects
-- representing it. It is also not a global option of the graph.
--
-- For these reasons, in addition to the digraph object itself,
-- additional information can be passed by a parser to graph drawing
-- algorithms through the means of events. Each |Event| consists of a
-- |kind| field, which is just some string, and a |parameters| field,
-- which stores additional, kind-specific information. As a graph is
-- being parsed, a string of events is accumulated and is later on
-- available through the |events| field of the graph drawing scope.
--
-- The following events are created during the parsing process by the
-- standard parsers of \tikzname:
--
-- \begin{itemize}
-- \item[|node|] When a node of the input graph has been parsed and
-- a |Vertex| object has been created for it, an event with kind
-- |node| is created. The |parameter| of this event is the
-- just-created vertex.
--
-- The same kind of event is used to indicate ``missing'' nodes. In
-- this case, the |parameters| field is |nil|.
-- \item[|edge|] When an edge of the input graph has been parsed, an
-- event is created of kind |edge|. The |parameters| field will store
-- an array with two entries: The first is the |Arc| object whose
-- |syntactic_edges| field stores the |edge|. The second is the index
-- of the edge inside the |syntactic_edges| field.
-- \item[|begin|]
-- Signals the beginning of a group, which will be ended with a
-- corresponding |end| event later on. The |parameters| field will
-- indicate the kind of group. Currently, only the string
-- |"descendants"| is used as |parameters|, indicating the start of
-- several nodes that are descendants of a given node. This
-- information can be used by algorithms for reconstructing the
-- input structure of trees.
-- \item[|end|] Signals the end of a group begun by a |begin| event
-- earlier on.
-- \end{itemize}
-- 
-- @field kind A string representing the kind of the events. 
-- @field parameters Kind-specific parameters.
-- @field index A number that stores the events logical position in
-- the sequence of events. The number need not be an integer array
-- index. 
--
local Event = {}
Event.__index = Event


-- Namespace
require("pgf.gd.lib").Event = Event



---
-- Create a new event object
--
-- @param initial Initial fields of the new event.
--
-- @return The new object

function Event.new(values)
  local new = {}
  for k,v in pairs(values) do
    new[k] = v
  end
  return setmetatable(new, Event)
end



-- done

return Event