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
-- for _,v in ipairs(g.vertices) do
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
--   index: The index of the node inside the vertices array of g.
--   incoming: A table storing the arcs pointing to the vertex (each
--    arc is stored twice, once at an array position and once at the
--    source vertex).
--   outgoing: Same as incoming, only for the outgoing arcs.

local Digraph = {}
Digraph.__index = Digraph


-- Namespace
require("pgf.gd.model").Diagraph = Diagraph

-- Imports
local Arc = require "pgf.gd.model.Arc"




--- Creates a new digraph.
--
-- A digraph object stores a set of vertices and a set of arcs. The
-- vertices table is both an array (for iteration) as well as a
-- hash-table of node to position mappings. This operation takes time
-- $O(1)$. 
--
-- @param initial_vertices An array containing some initial vertices. 
--
-- @return A newly-allocated digraph.
--
function Graph:new(initial_vertices)
  local vertices = {}
  local digraph = {
    vertices = vertices
  }
  setmetatable(digraph, Digraph)
  if initial_vertices then 
    digraph:addMany(initial_vertices)
  end
  return digraph
end


--- Adds a vertex to a digraph.
--
-- Adding a vertex to a graph that already exists has no effect. 
--
-- This operation takes time $O(1)$.
--
-- @param v The vertex to be added.
--
function Digraph:add(v)
  if not v[self] then
    local vertices = self.vertices

    -- Insert into vertices array/hash
    local i = #vertices + 1
    vertices[i] = v
    v[self] = { index = i, incoming = {}, outgoing = {} }
  end
end


--- Adds many vertices to a digraph.
--
-- There is no real advantage over just adding the vertices one by
--one; but this method is here for symmetry with removeMany
--
-- This operation takes time $O(|L|)$, where $L$ is the input list.
--
-- @param v The vertex to be added.
--
function Digraph:addMany(list)
  local vertices = self.vertices
  local i = #vertices + 1
  for j=1,#list do
    local v = list[j]
    if not v[self] then
      vertices[i] = v
      v[self] = { index = i, incoming = {}, outgoing = {} }
      i = i + 1
    end
  end
end




--- Test, whether a graph contains a given vertex. 
--
-- This operation takes time $O(1)$.
--
-- @param v The vertex to be tested.
--
function Digraph:contains(v)
  return v[self] ~= nil
end




--- Returns the arc between two nodes, provided it exists. Otherwise,
-- nil is retured.
--
--  This operation takes time $O(1)$.
--
-- @param s The source vertex
-- @param t The target vertex
--
-- @return The arc object connecting them
--
function Digraph:arc(s, t)
  return assert(s[self], "source vertex not in graph").outgoing[t]
end



--- Returns an array containg the outgoing arcs of a node. You may
-- only iterate overt his array using ipairs, not using pairs.
--
--  This operation takes time $O(1)$.
--
-- @param s The vertex
--
-- @return An array of all outgoing arcs of this vertex (all arcs
-- whose source is the vertex)
--
function Digraph:outgoing(v)
  return assert(v[self], "vertex not in graph").outgoing
end



--- As outgoing.
--
function Digraph:incoming(v)
  return assert(v[self], "vertex not in graph").incoming
end




--- Returns an array of all arcs in the graph. This operation is
-- relatively expensive (it takes time $O(|V| + |E|)$ where $E$ is the
-- set of arcs).
--
-- You can use this command to easily iterate over all arcs of a
-- graph:
--
-- for _,a in ipairs(g:arcs()) do
--   ...
-- end
--
-- Note, however, that you should not call this command repeatedly,
-- because it is expensive. Store the result in a local variable. You
-- should only call it after the set of arcs has been modified.
--
-- This operation takes time $O(|V| + |E|)$.
--
-- @return An array contain each arc exactly once

function Digraph:arcs()
  local result = {}
  local vertices = self.vertices
  for i=1,#vertices do
    local out = vertices[i][self].outgoing
    for j=1,#out do
      result[#result + 1] = out[j]
    end
  end
  return result
end




--- Connects two nodes by an arc and returns the arc. If they are
-- already connected, the existing arc is returned. 
--
-- This operation takes time $O(1)$.
--
-- @param s The source vertex
-- @param t The target vertex (may be identical to s in case of a
--          loop)
--
-- @return The arc object connecting them (either newly created or
--         already existing)
--
function Digraph:connect(s, t)
  local s_outgoing = assert(s[self], "source node not in graph").outgoing
  local arc = s_outgoing[t]

  if not arc then
    -- Ok, create and insert new arc object
    arc = { s = s, t = t }
    setmetatable(arc, Arc)

    -- Insert into outgoing:
    local num = #s_outgoing + 1
    s_outgoing [num] = arc
    s_outgoing [t]   = arc

    local t_incoming = assert(t[self], "target node not in graph").incoming
    -- Insert into incoming:
    num = #t_incoming + 1
    t_incoming [num] = arc
    t_incoming [s]   = arc
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
-- @param s The single vertex or the source vertex
-- @param t The target vertex
--
function Digraph:disconnect(v, t)
  if t then
    -- Case 2: Remove a single arc.
    local s_outgoing = assert(v[self], "source node not in graph").outgoing
    local t_incoming = assert(t[self], "target node not in graph").incoming

    if s_outgoing[t] then
      -- Remove:
      s_outgoing[t] = nil
      for i=1,#s_outgoing do
	if s_outgoing[i] == t then
	  table.remove (s_outgoing, i)
	  break
	end
      end
      t_incoming[s] = nil
      for i=1,#t_incoming do
	if t_incoming[i] == s then
	  table.remove (t_incoming, i)
	  break
	end
      end
    end
  else
    -- Case 1: Remove all arcs incident to v:
    local info = assert(v[self], "node not in graph")
    
    -- Step 1: Delete all incoming arcs:
    local incoming = info.incoming
    local vertices = self.vertices

    for i=1,#incoming do
      local s = incoming[i].s
      local s_info = s[self]
      if s ~= v and vertices[s_info.index] then -- skip self-loop and to-be-deleted nodes
	-- Remove this arc from s:
	local s_outgoing = s_info.outgoing
	s_outgoing[v] = nil
	for i=1,#s_outgoing do
	  if s_outgoing[i] == v then
	    table.remove (s_outgoing, i)
	    break
	  end
	end
      end
    end

    -- Step 2: Delete all outgoing arcs:
    local outgoing = info.outgoing
    for i=1,#outgoing do
      local t = outgoing[i].t
      local t_info = t[self]
      if t ~= v and vertices[t_info.index] then
	local t_incoming = t[self].incoming
	t_incoming[v] = nil
	for i=1,#t_incoming do
	  if t_incoming[i] == v then
	    table.remove (t_incoming, i)
	    break
	  end
	end
      end
    end
  end
end





--- Remove a vertex from a digraph.
--
-- Removing a vertex from a graph in which it is no element is legal
-- and has no effect. 
--
-- This operation takes time $O(|V|)$ if the vertex is in the graph,
-- so it is pretty expensive. To remove many vertices, use removeMany
-- instead, which will be much faster than repeatedly calling remove.
--
-- @param v The vertex to be removed.
--
function Digraph:remove(v)
  if v[self] then
    self:disconnect(v)
    table.remove (self.vertices, v[self].index)
    v[self] = nil
  end
end



--- Remove many vertices from a digraph
--
-- This method allows you to remove a whole list of vertices from the
-- graph. The main difference to calling remove repeatedly is that the
-- runtime will be linear in the number of vertices regardless of how
-- many vertices are deleted (plus the time needed to delete the arcs
-- to nodes that are not deleted).
--
-- This operation will take time $O(|V|)$ plus the time needed to
-- disconnect all deleted nodes.
--
-- @param delete_us An array of nodes that should be deleted.
--
function Digraph:removeMany(delete_us)
  local vertices = self.vertices
  
  -- Mark all to-be-deleted nodes
  for i=1,#delete_us do
    vertices[delete_us[i][self].index] = false
  end
  
  -- Disconnect them
  for i=1,#delete_us do
    self:disconnect(delete_us[i])
  end
  
  -- Now relabel everything
  local target = 1
  for i=1,#vertices do
    local v = vertices[i]
    if v then
      if i > target then
	-- Move from i to target:
	vertices[target] = v
	v[self].index = target
      end
      target = target + 1
    end
  end
  
  for j=#vertices,target,-1 do
    vertices[j] = nil
  end
end




--- Creates private tables for the graph and its vertices.
--
-- "Private tables" are tables that are available in each node and arc
-- of a graph (and also at the graph itself), indexed through a
-- "private" key, normally the key of a special table. The idea is
-- that, say, an algorithm will work on a graph and wishes to store
-- some information at the vertices. For instance, a depth-first
-- search will often which to store information like "this vertex is
-- marked" at a vertex. One could store this information simply in a
-- field like v.marked. However, a different algorithm might also use
-- this field, leading to confusion. To avoid this, an algorithm can
-- request that it should be provided with private tables at each node
-- (and also at the graph object itself, for convenience).
-- 
-- You can also request private tables for all arcs, but this is done
-- using a separate function for efficiency since many algorithms will
-- only need pivate tables at the vertices.
--
-- If a vertex already has a private table, it will not be
-- modified. Thus, you can call this method repeatedly, namely whenever
-- new nodes have been added.
--
-- The method takes time $O(|V|)$.
--
-- @param A private key (must be a table).

function Digraph:privateVertexTables(private)
  assert(private.type == "table", "private keys must be tables")

  self[private] = self[private] or {}

  -- Add an algorithm field to all vertices
  local vertices=self.vertices
  for i=1,#vertices do
    local v = vertices[i]
    v[private] = v[private] or {}
  end
end


--- Creates private tables for the arcs of a graph
--
-- Like privateVertexTables, only for arcs rather then vertices. As
-- for privateVertexTables, the graph object itself also gets a private
-- table.
--
-- This method takes time $O(|V| + |E|)$, where $E$ is the set of
-- arcs.
--
-- @param A private key (must be a table).

function Digraph:privateArcTables(private)
  assert(private.type == "table", "private keys must be tables")

  self[private] = self[private] or {}

  -- Add an algorithm field to all arcs
  local vertices = self.vertices
  for i=1,#vertices do
    local out = vertices[i][self].outgoing
    for j=1,#out do
      local a = out[j]
      a[private] = a[private] or {}
    end
  end
end



--- Returns a string representation of this graph including all nodes and edges.
--
-- @return Graph as string.
--
function Digraph:__tostring()
  local vstrings = {}
  for i,v in ipairs(self.vertices) do
    vstrings[i] = tostring(v)
  end
  local astrings = {}
  for i,a in ipairs(self:arcs()) do
    astrings[i] = tostring(a)
  end
  return "graph [id=" .. tostring(self.vertices) .. "] {" ..
    table.concat(vstrings, ", ") .. "; " .. 
    table.concat(astrings, ", ") .. "}";
end




-- Done

return Diraph