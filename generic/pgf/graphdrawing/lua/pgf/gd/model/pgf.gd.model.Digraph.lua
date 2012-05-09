-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$




--- The Digraph class
--
-- A digraph (directed graph) is a directed, simple graph (no
-- multiedges). Formally, it consistes of a set $V$ of vertices
-- together with a set $E \subseteq V \times V$ of edges, which we
-- call \emph{arcs}. Note that in a digraph all arcs are directed.
--
-- The implementation of a digraph is as follows: 
--
--
-- 1. Vertices
--
-- A vertex is a rather "big" object that keeps track of all sorts of
-- information (like which graphs it belongs to, possibly its position
-- on the page, information locally important for an algorithm and so
-- on). A vertex can be part of more than one graph. Vertices are
-- created first and then added or removed from graphs.
--
-- Graphs keep an array of vertices, the ordering is important (they
-- will be ordered according to the order in which they were
-- inserted). You can and should iterate over all vertices of a graph g
-- using the following code:
--
-- for i,v in ipairs(g.vertices) do
--   ...
-- end
--
-- Do not use pairs(g.vertices) because this may cause your graph
-- drawing algorithm to produce different outputs on different runs.
--
-- Never, ever, modify g.vertices directly, always use add and remove.
--
-- 
-- When a vertex v is added to a graph g, the entry v[g] is set to a
-- table that stores information concerning the vertex's "involvement"
-- in the graph. This table has the following fields:
--
--   incoming: A table storing the arcs pointing to the vertex (each
--    arc is stored twice, once at an array position and once at the
--    tail vertex).
--   outgoing: Same as incoming, only for the outgoing arcs.
--
--
-- 2. Arcs
--
-- Normally, you access the list of incoming or outgoing arcs of a
-- vertex using g:incoming(n) or g:outgoing(n). You can thus iterate
-- over all arcs of graph like this:
--
-- for _,v in ipairs(g.vertices) do
--   for _,a in ipairs(g:outgoing(v)) do
--    ...
--   end
-- end
--
-- However, it will often be more convenient and, in case the there
-- are far less arcs than node, also faster to write
-- 
-- for _,a in ipairs(g.arcs) do
--   ...
-- end
--
-- The arcs field is, however, a virtual field. What actually happens
-- is that, normally, when you access g.arcs, you actually get the
-- internal array _arcs, which accumulates all arcs in an array. However,
-- when you delete an arc, _arcs field will be set to nil. The next
-- time the arcs field is accessed, we notice that _arcs is nil an
-- recalculate it.
--
-- All of this means the following: As long as you do not delete arcs
-- from a graph, accessing the arcs field will be easier and faster
-- than the nested loops earlier. When you delete one or more arcs,
-- the next time the arcs field is accessed, it will need time linear
-- in the number of arcs in the graph plus then number of vertices to
-- recalculate the field. Thus, it is recommendable that you bundle
-- together disconnect calls.

local Digraph = {}

local function recalc_arcs (digraph)
  local arcs = {}
  local vertices = digraph.vertices
  local outgoings = digraph.outgoings
  for i=1,#vertices do
    local out = vertices[i].storage[outgoings]
    for j=1,#out do
      arcs[#arcs + 1] = out[j]
    end
  end
  digraph.arcs = arcs
  return arcs    
end

Digraph.__index = 
  function (t, k)
    if k == "arcs" then 
      return recalc_arcs(t)
    else
      return rawget(Digraph,k)
    end
  end



-- Namespace
require("pgf.gd.model").Digraph = Digraph

-- Imports
local Arc     = require "pgf.gd.model.Arc"
local Storage = require "pgf.gd.lib.Storage"






--- Creates a new digraph.
--                
-- A digraph object stores a set of vertices and a set of arcs. The
-- vertices table is both an array (for iteration) as well as a
-- hash-table of node to position mappings. This operation takes time
-- $O(1)$. 
--
-- @param initial A table of initial values. It is permissible that
--                this array contains a "vertices" field. In this
--                case, this field must be an array and its entries
--                must be nodes, which will be inserted. If initial
--                has an arcs field or a storage field, these fields
--                will be ignored.
--                The table must contain a field "syntactic_digraph",
--                which should normally be the syntactic digraph of
--                the graph, but may also be the string "self", in
--                which case it will be set to the newly created
--                (syntactic) digraph.
--
-- The bottom line is that Digraph.new(existing_digraph) will create a
-- new digraph with the same vertex set and the same options as the
-- existing digraph, but without arcs.
-- @return A newly-allocated digraph.
--
function Digraph.new(initial)
  local digraph = {}
  setmetatable(digraph, Digraph)

  if initial then
    for k,v in pairs(initial) do
      digraph [k] = v
    end
  end

  local vertices = digraph.vertices
  digraph.vertices = {}
  digraph.arcs = {}
  digraph.storage = Storage.new() 
  digraph.incomings = {} -- a unique handle for vertices's storage
  digraph.outgoings = {}  -- a unique handle for vertices's storage
  digraph.syntactic_digraph = assert(initial.syntactic_digraph, "no syntactic digraph specified")
  if digraph.syntactic_digraph == "self" then
    digraph.syntactic_digraph = digraph
  end
  
  if vertices then 
    digraph:add(vertices)
  end
  return digraph
end


--- Add vertices to a digraph.
--
-- This operation takes time $O(#array)$.
--
-- @param array An array of to-be-added vertices.
--
function Digraph:add(array)
  local vertices = self.vertices
  local incomings = self.incomings
  local outgoings = self.outgoings
  for i=1,#array do
    local v = array[i]
    if not vertices[v] then
      vertices[v] = true
      vertices[#vertices + 1] = v
      local s = v.storage
      s[incomings] = {}
      s[outgoings] = {}
    end
  end
end


--- Remove vertices from a digraph.
--
-- This operation removes an array of vertices from a graph. The
-- operation takes time linear in the number of vertices, regardless of
-- how many vertices are to be removed. Thus, it will be (much) faster
-- to delete many vertices by first compiling them in an array and to
-- then delete them using one call to this method.
--
-- This operation takes time $O(max{#array, #self.vertices)$.
--
-- @param array The to-be-removed vertices.
--
function Digraph:remove(array)
  
  -- Mark all to-be-deleted nodes
  for i=1,#array do
    local v = array[i]
    assert(vertices[v], "to-be-deleted node is not in graph")
    vertices[v] = false
  end
  
  -- Disconnect them
  for i=1,#array do
    self:disconnect(array[i])
  end
  
  LookupTable.remove(self.vertices, array)
end



--- Test, whether a graph contains a given vertex. 
--
-- This operation takes time $O(1)$.
--
-- @param v The vertex to be tested.
--
function Digraph:contains(v)
  return v and self.vertices[v] == true
end




--- Returns the arc between two nodes, provided it exists. Otherwise,
-- nil is retured.
--
-- This operation takes time $O(1)$.
--
-- @param s The tail vertex
-- @param t The head vertex
--
-- @return The arc object connecting them
--
function Digraph:arc(s, t)
  return assert(s.storage[self.outgoings], "tail vertex not in graph")[t]
end



--- Returns an array containg the outgoing arcs of a vertex. You may
-- only iterate over his array using ipairs, not using pairs.
--
--  This operation takes time $O(1)$.
--
-- @param s The vertex
--
-- @return An array of all outgoing arcs of this vertex (all arcs
-- whose tail is the vertex)
--
function Digraph:outgoing(v)
  return assert(v.storage[self.outgoings], "vertex not in graph")
end



---
-- Sorts the array of outgoing arcs of a vertex. This allows you to
-- later iterate over the outgoing arcs in a specific order.
--
-- This operation takes time $O(#outgoing log #outgoings)$.
--
-- @param s The vertex
-- @param f A comparison function that is passed to table.sort
--
function Digraph:sortOutgoing(v, f)
  table.sort(assert(v.storage[self.outgoings], "vertex not in graph"), f)
end


---
-- Reorders the array of outgoing arcs of a vertex. The parameter array
-- \emph{must} contain the same set of vertices as the outgoing array,
-- but possibly in a different order.
--
-- This operation takes time $O(#outgoing)$.
--
-- @param s The vertex
-- @param a An array containing the outgoing verticesin some order.
--
function Digraph:orderOutgoing(v, vertices)
  local outgoing = assert (v.storage[self.outgoings], "vertex not in graph")
  assert (#outgoing == #vertices)

  -- Create back hash
  local lookup = {}
  for i=1,#vertices do
    lookup[vertices[i]] = i
  end

  -- Compute ordering of the arcs
  local reordered = {}
  for _,arc in ipairs(outgoing) do
    reordered [lookup[arc.head]] = arc 
  end

  -- Copy back
  for i=1,#outgoing do
    outgoing[i] = assert(reordered[i], "illegal vertex order")
  end
end



--- As outgoing.
--
function Digraph:incoming(v)
  return assert(v.storage[self.incomings], "vertex not in graph")
end


---
-- As sortOutgoing
--
function Digraph:sortIncoming(v, f)
  table.sort(assert(v.storage[self.incomings], "vertex not in graph"), f)
end


---
-- As reorderOutgoing
--
function Digraph:orderIncoming(v, a)
  local incoming = assert (v.storage[self.incomings], "vertex not in graph")
  assert (#incoming == #vertices)

  -- Create back hash
  local lookup = {}
  for i=1,#vertices do
    lookup[vertices[i]] = i
  end

  -- Compute ordering of the arcs
  local reordered = {}
  for _,arc in ipairs(incoming) do
    reordered [lookup[arc.head]] = arc 
  end

  -- Copy back
  for i=1,#incoming do
    incoming[i] = assert(reordered[i], "illegal vertex order")
  end
end





--- Connects two nodes by an arc and returns the arc. If they are
-- already connected, the existing arc is returned. 
--
-- This operation takes time $O(1)$.
--
-- @param s The tail vertex
-- @param t The head vertex (may be identical to s in case of a
--          loop)
--
-- @return The arc object connecting them (either newly created or
--         already existing)
--
function Digraph:connect(s, t, object)
  assert (s and t and self.vertices[s] and self.vertices[t], "trying connect nodes not in graph")

  local s_outgoings = s.storage[self.outgoings]
  local arc = s_outgoings[t]

  if not arc then
    -- Ok, create and insert new arc object
    arc = {
      tail = s,
      head = t,
      storage = Storage.new(),
      syntactic_digraph = self.syntactic_digraph
    }
    setmetatable(arc, Arc)

    -- Insert into outgoings:
    s_outgoings [#s_outgoings + 1] = arc
    s_outgoings [t] = arc

    local t_incomings = t.storage[self.incomings]
    -- Insert into incomings:
    t_incomings [#t_incomings + 1] = arc
    t_incomings [s] = arc

    -- Insert into arcs field, if it exists:
    local arcs = rawget(self, "arcs")
    if arcs then
      arcs[#arcs + 1] = arc
    end
  end

  return arc
end




--- Disconnect either a single vertex from all its neighbors (remove all
-- incoming and outgoing arcs of this vertex) or, in case two nodes
-- are given as parameter, remove the arc between them, if it exsits. 
--
-- This operation takes time $O(|I_s| + |I_t|)$, where I_x is the set
-- of vertices incident to x, to remove the single arc between s and
-- t. For a single vertex x, it takes time $O(\sum_{y: there is some
-- arc between x and y or y and x} |I_y|)$.
--
-- @param s The single vertex or the tail vertex
-- @param t The head vertex
--
function Digraph:disconnect(v, t)
  if t then
    -- Case 2: Remove a single arc.
    local s_outgoings = assert(v.storage[self.outgoings], "tail node not in graph")
    local t_incomings = assert(t.storage[self.incomings], "head node not in graph")

    if s_outgoings[t] then
      -- Remove:
      s_outgoings[t] = nil
      for i=1,#s_outgoings do
	if s_outgoings[i].head == t then
	  table.remove (s_outgoings, i)
	  break
	end
      end
      t_incomings[v] = nil
      for i=1,#t_incomings do
	if t_incomings[i].tail == v then
	  table.remove (t_incomings, i)
	  break
	end
      end
      self.arcs = nil -- invalidate arcs field
    end
  else
    -- Case 1: Remove all arcs incident to v:
    local v_storage = v_storage
    local self_incomings = self.incomings
    local self_outgoings = self.outgoings
    
    -- Step 1: Delete all incomings arcs:
    local incomings = assert(v_storage[self_incomings], "node not in graph")
    local vertices = self.vertices

    for i=1,#incomings do
      local s = incomings[i].tail
      if s ~= v and vertices[s] then -- skip self-loop and to-be-deleted nodes
	-- Remove this arc from s:
	local s_outgoings = s.storage[self_outgoings]
	s_outgoings[v] = nil
	for i=1,#s_outgoings do
	  if s_outgoings[i].head == v then
	    table.remove (s_outgoings, i)
	    break
	  end
	end
      end
    end

    -- Step 2: Delete all outgoings arcs:
    local outgoings = v_storage[self_outgoings]
    for i=1,#outgoings do
      local t = outgoings[i].head
      if t ~= v and vertices[t] then
	local t_incomings = t.storage[self_incomings]
	t_incomings[v] = nil
	for i=1,#t_incomings do
	  if t_incomings[i].tail == v then
	    table.remove (t_incomings, i)
	    break
	  end
	end
      end
    end

    if #incomings > 0 or #outgoings > 0 then
      self.arcs = nil -- invalidate arcs field
    end

    -- Step 3: Reset incomings and outgoings fields
    v_storage[self_incomings] = {}
    v_storage[self_outgoings] = {}
  end
end




--- Reconnect: An arc is changed so that instead of connecting a.tail
-- and a.head, it now connects a new head and tail. The difference to
-- first disconnecting and then reconnecting is that all fields of the
-- arc (other than head and tail, of course), will be "moved
-- along". Also, all fields of the storage will be
-- copied. Reconnecting and arc in the same way as before has no
-- effect.
--
-- If there is already an arc at the new position, field of the
-- to-be-reconnected arc overwrite fields of the original arc. This is
-- especially dangerous with a syntactic digraph, so do not reconnect
-- arcs of the syntactic digraph (which you should not do anyway).
--
-- The arc object may no longer be valid after a reconnect, but the
-- operation returns the new arc object.
--
-- This operation needs the time of a disconnect (if necessary)
--
-- @param arc The original arc object
-- @param tail The new tail vertex
-- @param head The new head vertex
--
-- @return The new arc object connecting them (either newly created or
--         already existing)
--
function Digraph:reconnect(arc, tail, head)
  assert (arc and tail and head, "connect with nil parameters")
  
  if arc.head == head and arc.tail == tail then
    -- Nothing to be done
    return arc
  else
    local new_arc = self:connect(tail, head)
    
    for k,v in pairs(arc) do
      if k ~= "head" and k ~= "tail" and k ~= "storage" then
	new_arc[k] = v
      end
    end

    for k,v in pairs(arc.storage) do
      new_arc.storage[k] = v
    end

    -- Remove old arc:
    self:diconnect(arc.tail, arc.head)

    return new_arc
  end
end





--- Returns a string representation of this graph including all nodes and edges.
--
-- @return Digraph as string.
--
function Digraph:__tostring()
  local vstrings = {}
  local astrings = {}
  for i,v in ipairs(self.vertices) do
    vstrings[i] = "    " .. tostring(v) .. "[x=" .. math.floor(v.pos.x) .. "pt,y=" .. math.floor(v.pos.y) .. "pt]"
    local out_arcs = v.storage[self.outgoings]
    if #out_arcs > 0 then
      local t = {}
      for j,a in ipairs(out_arcs) do
	t[j] = tostring(a.head) 
      end
      astrings[#astrings + 1] = "  " .. tostring(v) .. " -> { " .. table.concat(t,", ") .. " }"
    end
  end
  return "graph [id=" .. tostring(self.vertices) .. "] {\n  {\n" ..
    table.concat(vstrings, ",\n") .. "\n  }; \n" .. 
    table.concat(astrings, ";\n") .. "\n}";
end




-- Done

return Digraph