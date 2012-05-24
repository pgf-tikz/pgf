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
-- An arc is a light-weight object. It just has three fields,
-- by default: |head| and |tail| and a |storage|.
--
-- You may not create an |Arc| by yourself, which is why there is no |new|
-- method, arc creation is done by the Digraph class.
--
-- Every arc belongs to exactly one graph. If you want the same arc in
-- another graph, you need to newly connect two vertices in the other graph. 
--
-- You may read the |head| and |tail| fields, but you may not write
-- them. In order to store data in an arc, use the |storage| field,
-- which is a storage.
--
-- Between any two vertices of a graph there can be only one arc, so
-- all digraphs are always simple graphs. However, in the
-- specification of a graph (the syntactic digraph), there might
-- be multiple edges between two vertices. To solve this problem, a
-- rather involved process is used:
--
-- Firstly, arcs in the syntactic digraph have a field called
-- |syntactic_edges|, which is an array of edges.
--
-- Secondly, you may setup special functions for reading and writing
-- what I call "collected values". The idea is that an arc of a graph
-- may correspond to zero, one, or many edges in the syntactic
-- digraph. Now suppose you wish to read, say, an option like the
-- "weight" of the arc. In this case, one or more edges may have this
-- option set. Instead of having to somehow finding and iterating over
-- these edges, you can install a "collector" for the field
-- "weight" of the arc. In this case, when you write a.weight, where "a"
-- is an arc, the first time you write this the edges corresponding to
-- a in the syntactic digraph are traversed and their accumulated
-- weight is returned. The second time you access the field, the value
-- will have been stored directly in the arc's weight field. Thus,
-- you can access this field transparently and with the highest
-- possible speed.
--
-- The other way round, suppose you wish to write something like a
-- path entry of an arc. Such a path contains a sequence of
-- coordinates. This path needs to be copied to all edges
-- corresponding to the arc; but we must sometimes reverse the path in
-- case the arc points in a direction different from the edge's
-- direction.
--
-- For this problem, you can install a "distributor" for the
-- path key. It has the following effect: You can write (and read) the
-- path like any normal field of the arc. However, when you signal
-- that you are done with the field using the "done" method, the
-- following happens: In all arcs where this field is currently set,
-- the edges of the graph corresponding to the field are traversed and
-- functions are called to (in this case) copy the path's coordinates
-- to the individual edges.
--
local Arc = {}


-- Namespace

require("pgf.gd.model").Arc = Arc


-- Imports

local Options = require "pgf.gd.control.Options"


local Arc_collectors = {}
local Arc_distributors = {}



local function collect_syntactic_edges (arc)

  local tail = arc.tail
  local head = arc.head
  
  local a1 = arc.syntactic_digraph:arc(tail, head)
  local a2 = head ~= tail and arc.syntactic_digraph:arc(head, tail)
  
  local array = {}
  
  if a1 then
    for _,m in ipairs(a1.storage.syntactic_edges) do
      array[#array + 1] = m
    end
  end
  if a2 then
    for _,m in ipairs(a2.storage.syntactic_edges) do
      array[#array + 1] = m
    end
  end
  table.sort(array, function (a,b) return a.event_index < b.event_index end)

  return array
end



--- The Arc index function
--
-- This function called whenever you access a field of an arc table
-- that has not (yet) be read. The function tests whether your
-- requested field has a collector installed. If so, the collector is 
-- invoked to get and setup the value.

function Arc.__index(arc, key)
  local c = Arc_collectors[key]
  if c then
    local value = c(collect_syntactic_edges(arc), arc, key)
    rawset(arc,key,value)
    return value
  end
end


--- The Arc new_index function
--
-- This function called whenever you write something to a field of an
-- arc table that is not (yet) initialised. The function tests whether your
-- requested field has a reader installed. If so, the reader is
-- invoked to get and setup the value.

function Arc.__newindex(arc, key, value)
  local d = assert(Arc_distributors[key], "attempting to write to key of an arc without a distributor")
  rawset(arc, key, value)
  d.affected_arcs[arc] = true
end


---
-- Install a collector
--
-- @param key A key
-- @param collector A collector function
--
-- The collector function will be called with an arc and the key as
-- parameters. It should return a value that is to be installed in the
-- arc at the key's field.

function Arc.collector(key, collector)
  assert (not Arc_collectors[key], "arc collector already installed")
  Arc_collectors[key] = collector
end


---
-- Install a distributor
--
-- @param key A key
-- @param d A distributor function
--
-- The distributor function will be called when the "done" method is
-- called for the key. It will then be called once for each affected
-- arcs. The parameters will the value of the key for this arc, an
-- array of affected syntactic edges, and the affected arc.

function Arc.distributor(key, distributor)
  assert (not Arc_distributors[key], "arc distributor already installed")
  Arc_collectors[key] = { distributor = distributor, affected_arcs = {} }
end




---
-- Invoke a distributor
--
-- @param key A key
--
-- The distributor is now called for the given key. After this call,
-- the key will be nil for all affected arcs.

function Arc.done(key)
  local d = assert (Arc_distributors[key], "no distributor installed")
  local affected = d.affected_arcs
  
  -- Invoke distributor
  for arc in pairs(affected) do
    d.distributor(arc[key], collect_syntactic_edges(arc), arc)
    rawset(arc, key, nil)
  end
  
  Arc_collectors[key] = nil
end





---
-- Collectors for options
--
-- These functions are used like this:
--
-- Arc.optionSumCollector("/graph drawing/weight")
-- ...
-- local some_arc = my_graph:arc(s,t)
-- if some_arc["/graph drawing/weight"] > 5 then
-- ...
-- end
--
-- Naturally, you can also abbreviate this:
--
-- local weight = "/graph drawing/weight"
-- Arc.optionSumCollector(weight)
-- ...
-- local some_arc = my_graph:arc(s,t)
-- if some_arc[weight] > 5 then
-- ...
-- end
--
-- They have the following effects:
--
-- Arc.optionCollector: Computes the value of the first occurrence of the option
-- in the options table of any of the edges corresponding to the arc.
--
-- Arc.optionSyntacticCollector: Computes the value of the first occurrence of the option
-- in the options table of any of the edges corresponding to the arc.
--
-- Arc.optionLastCollector: Returns the first occurrence of the option
-- in the options table of an edge corresponding to the arc, where the
-- edge points in the "syntactic correct" direction.
--
-- Arc.optionSumCollector: Sum up all non-nil values of this option at
-- the edges.
--
-- Arc.optionMinCollector: Return the minimum value of the non-nil
-- values of this option at the edges.
--
-- Arc.optionMaxCollector: As before, but for the maximum.
--
-- Arc.optionAvgCollector: As before, but for the average.

function Arc.optionCollector(option)
  Arc.collector (
    option,
    function (a)
      for i=1,#a do
	local o = a[i].options[option]
	if o ~= nil then
	  return o
	end
      end
    end
  )
end

function Arc.optionSyntacticCollector(option)
  Arc.collector (
    option,
    function (array, arc)
      for i=1,#array do
	local da = array[i]
	if da.head == arc.head then
	  local o = da.options[option]
	  if o ~= nil then
	    return o
	  end
	end
      end
    end
  )
end

function Arc.optionLastCollector(option)
  Arc.collector (
    option,
    function (a)
      for i=#a,1,-1 do
	local o = a[i].options[option]
	if o ~= nil then
	  return o
	end
      end
    end
  )
end
      
function Arc.optionArithmeticCollector(option, v, fun)
  Arc.collector (
    option,
    function (a)
      local r = v
      for i=1,#a do
	local o = a[i].options[option]
	if o ~= nil then
	  r = fun(r,o)
	end
      end
      return r
    end
  )
end

function Arc.optionSumCollector(option)
  Arc.optionArithmeticCollector(option, 0, function (a,b) return a+b end)
end

function Arc.optionMaxCollector(option)
  Arc.optionArithmeticCollector(option, -math.huge, math.max)
end

function Arc.optionMinCollector(option)
  Arc.optionArithmeticCollector(option, math.huge, math.min)
end

function Arc.optionAvgCollector(option)
  Arc.collector (
    option,
    function (a)
      local num = 0
      local v = 0
      for i=1,#a do
	local o = a[i].options[option]
	if o ~= nil then
	  v = v + o
	  num = num + 1
	end
      end
      if num > 0 then
	return v/num
      end
    end
  )
end



---
-- The point cloud collector
--
-- This collector will return the "point cloud" of an arc, which is
-- the set of all points that must be rotated and shifted along with
-- the endpoints of an edge.

Arc.collector(
  "point_cloud",
  function (array, arc)
    local cloud = {}
    for _,e in ipairs(array) do
      if e.head == arc.head then
	-- Only syntactically correct edges
	for _,p in ipairs(e.path) do
	  cloud[#cloud + 1] = p
	end
      end
    end
    return cloud
  end
)


---
-- The event index collector
--
-- This collector return the lowest event index of any edge involved
-- in the arc (or nil, if there is no syntactic edge).

Arc.collector(
  "event_index",
  function (array)
    if array[1] then
      return array[1].event_index
    end
  end
)



---
-- The span priority collector
--
-- This collector returns the top (that is, smallest) priority of any
-- edge involved in the arc.
--
-- The priority of an edge is computed as follows:
--
-- 1) If the option "/graph drawing/span priority" is set, this number
-- will be used.
--
-- 2) If the edge has the same head as the arc, we lookup the key
-- "/graph drawing/span priority " .. edge.direction. If set, we use
-- this value.
--
-- 3) If the edge has a different head from the arc (the arc is
-- "reversed" with respect to the syntactic edge), we lookup the key
-- "/graph drawing/span priority reversed " .. edge.direction. If set,
-- we use this value.
--
-- 4) Otherwise, we use priority 5.

Arc.collector(
  "span_priority",
  function (array, arc)
    local min 
    local g = arc.syntactic_digraph
    for _,e in ipairs(array) do
      local p = e.options["/graph drawing/span priority"]
      if not p then
	if e.head == arc.head then
	  p = Options.lookup("/graph drawing/span priority " .. e.direction, e, g)
	else
	  p = Options.lookup("/graph drawing/span priority reversed " .. e.direction, e, g)
	end
      end
      min = math.min(p or 5, min or math.huge)
    end
    return min or 5
  end
)


---
-- Installs a path distributor
--
-- You use this method like this:
--
-- ...
-- local path = {}
-- Arc.pathDistributor(path)
-- ...
-- local arc = g:connect(s,t)
-- arc.path = { Coordinate.new(x,y), Coordinate.new(x1,y1) }
-- ...
-- local arc = g:connect(s1,t2)
-- arc.path = { Coordinate.new(x,y), Coordinate.new(x1,y1) }
-- ...
-- Arc.done(path) -- Cause path fields to be set in edges
-- corresponding to the arcs.
--
-- @param key Distributor key

function Arc.pathDistributor(key)
  Arc.distributor(
    key,
    function (array, path, arc)
      for _,m in ipairs(array) do
	local copy = {}
	if m.head == arc.head then
	  for i=1,#path do
	    copy [i] = path[i]:clone()
	  end
	else
	  for i=#path,1,-1 do
	    copy [i] = path[i]:clone()
	  end
	end
	m.path = copy
      end
    end
  )
end




-- Returns a string representation of an arc. This is mainly for debugging
--
-- @return The Arc as string.
--
function Arc:__tostring()
  return tostring(self.tail) .. "->" .. tostring(self.head);
end


-- Done

return Arc