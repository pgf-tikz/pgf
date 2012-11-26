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
-- An arc is a light-weight object representing an arc from a vertex
-- in a graph to another vertex. You may not create an |Arc| by
-- yourself, which is why there is no |new| method, arc creation is
-- done by the Digraph class. 
--
-- Every arc belongs to exactly one graph. If you want the same arc in
-- another graph, you need to newly connect two vertices in the other graph. 
--
-- You may read the |head| and |tail| fields, but you may not write
-- them. In order to store data in an arc, use the |storage| field.
--
-- Between any two vertices of a graph there can be only one arc, so
-- all digraphs are always simple graphs. However, in the
-- specification of a graph (the syntactic digraph), there might
-- be multiple edges between two vertices. This means, in particular,
-- that an arc has no |options| field. Rather, it has several
-- |optionsXxxx| functions, that will search for options in all of the
-- synactic edges that ``belong'' to an edge.
--
-- Similarly, even though an arc has a |path| field, setting this
-- field does not immediately set the paths of the syntactic
-- edges. Indeed, you will normally want to setup and modify the
-- |path| field of an arc during your algorithm and only at the very
-- end, ``write it back'' to the multiple syntactic edges underlying
-- the graph. For this purpose, use the method |sync|.
--
-- @field tail The tail vertex of the arc.
-- @field head The head vertex of the arc. May be the same as the tail
-- in case of a loop.
-- @field storage A storage.
-- @field path If nonempty, the path of the arc. See the description
-- above.
-- @field syntactic_edges This field is an array containing syntactic
-- edges (``real'' edges in the syntactic digraph) that underly this
-- arc. 
--
local Arc = {}
Arc.__index = Arc


-- Namespace

require("pgf.gd.model").Arc = Arc


-- Imports

local lib = require "pgf.gd.lib"


---
-- Get an array of options of the syntactic edges corresponding to an arc.
--
-- An arc in a digraph is typically (but not always) present because
-- there are one or more edges in the syntactic digraph between the
-- tail and the head of the arc or between the head and the tail.
--
-- Since for every arc there can be several edges present in the
-- syntactic digraph, an option like |length| may have
-- been given multiple times for the edges corresponding to the arc.
--
-- If your algorithm gets confused by multiple edges, try saying
-- |a:options(your_option)|. This will always give the ``most
-- sensible'' choice of the option if there are multiple edges
-- corresponding to the same arc. 
--
-- @param option A string option like |"length"|.
--
-- @return A table with the following contents: 
-- \begin{enumerate}
-- \item It is an array of all values the option has for edges
-- corresponding to |self| in the syntactic digraph. Suppose, for
-- instance, you write the following:
--\begin{codeexample}[code only]
--graph {
--  tail -- [length=1] head,  % multi edge 1
--  tail -- [length=3] head,  % mulit edge 2
--  head -- [length=8] tail,  % multi edge 3
--  tail --            head,  % multi edge 4
--  head -- [length=7] tail,  % multi edge 5
--  tail -- [length=2] head,  % multi edge 6
--}
--\end{codeexample}
-- Suppose, furthermore, that |length| has been setup as an edge
-- option. Now suppose that |a| is the arc from the vertex |tail| to
-- the vertex |head|. Calling |a:optionsArray('length')| will
-- yield the array part |{1,3,2,8,7}|. The reason for the ordering is
-- as follows: First come all values |length| had for syntactic edges
-- going from |self.tail| to |self.head| in the order they appear in the graph
-- description. Then come all values the options has for syntactic
-- edges going from |self.head| to |self.tail|. The reason for this
-- slightly strange behaviour is that many algorithms do not really
-- care whether someone writes |a --[length=1] b| or
-- |b --[length=1] a|; in both cases they would ``just'' like to know
-- that the length is~|1|.
--
-- \item There is field called |aligned|, which is an array storing
-- the actual syntactic edge objects whose values can be found in the
-- array part of the returned table. However, |aligned| contains only
-- the syntactic edges pointing ``in the same direction'' as the arc,
-- that is, the tail and head of the syntactic edge are the same as
-- those of the arc. In the above example, this array would contain
-- the edges with the comment numbers |1|, |2|, and |6|.
--
-- Using the length of this array and the fact that the ``aligned''
-- values come first in the table, you can easily iterate over the
-- |option|'s values of only those edges that are aligned with the arc:
--
--\begin{codeexample}[code only]
--local a = g:arc(tail.head)   -- some arc
--local opt = a:optionsArray('length')
--local sum = 0
--for i=1,#opt.aligned do
--  sum = sum + opt[i]
--end
--\end{codeexample}
--
--\item There is a field called |anti_aligned|, which is an array
-- containing exactly the edges in the array part of the table not
-- aligned with the arc. The numbering start at |1| as usual, so the
-- $i$th entry of this table corresponds to the entry at position $i +
-- \verb!#opt.aligned!$ of the table.
--
--\end{enumerate}
--
function Arc:optionsArray(option)
  
  local storage = self.storage
  local t = storage[option]
  if t then
    return t
  end

  -- Accumulate the edges for which the option is set:
  local tail = self.tail
  local head = self.head
  local s_graph = self.syntactic_digraph

  local arc = s_graph:arc(tail, head)
  local aligned = {}
  if arc then
    for _,m in ipairs(arc.syntactic_edges) do
      if m.options[option] ~= nil then
	aligned[#aligned + 1] = m
      end
    end
    table.sort(aligned, function (a,b) return a.event.index < b.event.index end)
  end
  
  local arc = head ~= tail and s_graph:arc(head, tail)
  local anti_aligned = {}
  if arc then
    for _,m in ipairs(arc.syntactic_edges) do
      if m.options[option] ~= nil then
	anti_aligned[#anti_aligned + 1] = m
      end
    end
    table.sort(anti_aligned, function (a,b) return a.event.index < b.event.index end)
  end
  
  -- Now merge them together
  local t = { aligned = aligned, anti_aligned = anti_aligned }
  for i=1,#aligned do
    t[i] = aligned[i].options[option]
  end
  for i=1,#anti_aligned do
    t[#t+1] = anti_aligned[i].options[option]
  end
  storage[option] = t
  
  return t
end



---
-- Returns the first option, that is, the first entry of
-- |Arc:optionsArray(option)|. However, if the |only_aligned|
-- parameter is set to true and there is no option with any aligned
-- synactic edge, |nil| is returned.
--
-- @param option An option
-- @param only_aligned If true, only aligned syntactic edges will be
-- considered. 
-- @return The first entry of the |optionsArray|
function Arc:options(option, only_aligned)
  if only_aligned then
    local opt = self:optionsArray(option)
    if #opt.aligned > 0 then
      return opt[1]
    end
  else
    return self:optionsArray(option)[1]
  end
end




---
-- Get an accumulated value of an option of the syntactic edges
-- corresponding to an arc.
--
-- @param option The option of interest
-- @param accumulator A function taking two values. When there are
-- more than one syntactic edges corresponding to |self| for which the
-- |option| is set, this function will be called repeatedly for the
-- different values. The first time it will be called for the first
-- two values. Next, it will be called for the result of this call and
-- the third value, and so on.
-- @param only_aligned A boolean. If true, only the aligned syntactic
-- edges will be considered.
--
-- @return If the option is not set for any (aligned) syntactic edges
-- corresponding to |self|, |nil| is returned. If there is exectly one
-- edge, the value of this edge is returned. Otherwise, the result of
-- repeatedly applying the |accumulator| function as described
-- above.
--
-- The result is cached, repeated calls will not invoke the
-- |accumulator| function again.
--
-- @usage Here is typical usage:
--\begin{codeexample}[code only]
--local total_length = a:optionsAccumulated('length', function (a,b) return a+b end) or 0
--\end{codeexample}
--
function Arc:optionsAccumulated(option, accumulator, only_aligned)
  local opt = self:options(option)
  if only_aligned then
    local aligned = opt.aligned
    local v = aligned[accumulator]
    if v == nil then
      v = opt[1]
      for i=2,#aligned do
	v = accumulator(v, opt[i])
      end
      align[accumulator] = v
    end
    return v
  else
    local v = opt[accumulator]
    if v == nil then
      v = opt[1]
      for i=2,#opt do
	v = accumulator(v, opt[i])
      end
      opt[accumulator] = v
    end
    return v
  end
end





---
-- Compute the point cloud.
--
-- @return This method will return the ``point cloud'' of an arc,
-- which is an array of all points that must be rotated and shifted
-- along with the endpoints of an edge.
--
function Arc:pointCloud ()
  if self.cached_point_cloud then
    return self.cached_point_cloud -- cached
  end
  local cloud = {}
  local a = self.syntactic_digraph:arc(self.tail,self.head)
  if a then
    for _,e in ipairs(a.syntactic_edges) do
      for _,p in ipairs(e.path) do
	if type(p) == "table" then
	  cloud[#cloud + 1] = p
	end
      end
    end
  end
  self.cached_point_cloud = cloud
  return cloud
end  



---
-- Compute an event index for the arc.
--
-- @return The lowest event index of any edge involved
-- in the arc (or nil, if there is no syntactic edge).
--
function Arc:eventIndex ()
  if self.cached_event_index then
    return self.cached_event_index
  end
  local head = self.head
  local tail = self.tail
  local e = math.huge
  local a = self.syntactic_digraph:arc(tail,head)
  if a then
    for _,m in ipairs(a.syntactic_edges) do
      e = math.min(e, m.event.index)
    end
  end
  local a = head ~= tail and self.syntactic_digraph:arc(head,tail)
  if a then
    for _,m in ipairs(a.syntactic_edges) do
      e = math.min(e, m.event.index)
    end
  end
  self.cached_event_index = e
  return e
end  




---
-- The span collector
--
-- This method returns the top (that is, smallest) priority of any
-- edge involved in the arc.
--
-- The priority of an edge is computed as follows:
--
-- \begin{enumerate}
-- \item If the option |"span priority"| is set, this number
-- will be used.
--
-- \item If the edge has the same head as the arc, we lookup the key\\
-- |"span priority " .. edge.direction|. If set, we use
-- this value.
--
-- \item If the edge has a different head from the arc (the arc is
-- ``reversed'' with respect to the syntactic edge), we lookup the key
-- |"span priority reversed " .. edge.direction|. If set,
-- we use this value.
--
-- \item Otherwise, we use priority 5.
-- \end{enumerate}
--
-- @return The priority of the arc, as described above.
--
function Arc:spanPriority()
  if self.cached_span_priority then
    return self.cached_span_priority
  end
  
  local head = self.head
  local tail = self.tail
  local min
  local g = self.syntactic_digraph

  local a = g:arc(tail,head)
  if a then
    for _,m in ipairs(a.syntactic_edges) do
      local p =
	m.options["span priority"] or
	lib.lookup_option("span priority " .. m.direction, m, g)

      min = math.min(p or 5, min or math.huge)
    end
  end

  local a = head ~= tail and g:arc(head,tail)
  if a then
    for _,m in ipairs(a.syntactic_edges) do
      local p =
	m.options["span priority"] or
	lib.lookup_option("span priority reversed " .. m.direction, m, g)
      
      min = math.min(p or 5, min or math.huge)
    end
  end
  
  self.cached_span_priority = min or 5
  
  return min or 5
end






---
-- Sync an |Arc| with its syntactic edges. Currently, this means that
-- if the |path| field of the arc is not empty, it will be copied to
-- all syntactic edges underlying the arc. 
--
-- You use this method like this:
--\begin{codeexample}[code only]
--...
--local arc = g:connect(s,t)
--arc.path = { Coordinate.new(x,y), Coordinate.new(x1,y1) }
--...
--arc:sync()
--\end{codeexample}
--
-- Note that this function will automatically be called for all arcs
-- of the |ugraph|, the |digraph|, and the |spanning_tree| of an
-- algorithm by the rendering pipeline.
--
function Arc:sync()
  if self.path then
    local path = self.path
    local head = self.head
    local tail = self.tail
    local a = self.syntactic_digraph:arc(tail,head)
    if a then
      for _,m in ipairs(a.syntactic_edges) do
	local copy = {}
	for i=1,#path do
	  local p = path[i]
	  if type(p) == "table" then
	    copy [i] = p:clone()
	  else
	    copy [i] = p
	  end
	end
	m.path = copy
      end
    end
    local a = head ~= tail and self.syntactic_digraph:arc(head,tail)
    if a then
      for _,m in ipairs(a.syntactic_edges) do
	local copy = {}
	for i=1,#path do
	  local p = path[i]
	  if type(p) == "table" then
	    copy [i] = p:clone()
	  else
	    copy [i] = p
	  end
	end
	m.path = copy
      end
    end
  end
end



-- Returns a string representation of an arc. This is mainly for debugging
--
-- @return The Arc as string.
--
function Arc:__tostring()
  return tostring(self.tail) .. "->" .. tostring(self.head)
end


-- Done

return Arc
