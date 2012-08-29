-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The SpanningTreeComputation class is a singleton object.
--
-- Its methods provide methods for computing spanning trees.

local SpanningTreeComputation = {}


-- Namespace
require("pgf.gd.lib").SpanningTreeComputation = SpanningTreeComputation


-- Imports
local lib     = require "pgf.gd.lib"

local Vertex   = require "pgf.gd.model.Vertex"
local Digraph  = require "pgf.gd.model.Digraph"

local Options  = require "pgf.gd.control.Options"





---
-- Compute a spanning tree of a graph
--
-- The algorithm will favor nodes according to their priority. This is
-- determined through an edge priority function.
--
-- @param ugraph An undirected graph for which the spanning tree
-- should be computed  
-- @param dfs True if depth first should be used, false if breadth
-- first should be used.
--
-- @return A new graph that is a spanning tree

function SpanningTreeComputation.computeSpanningTree (ugraph, dfs, events)

  local tree = Digraph.new (ugraph) -- copy vertices
  
  local edge_priorities = ugraph.options['/graph drawing/edge priorities']

  local root = lib.find(ugraph.vertices, function (v) return v.options['/graph drawing/root'] end) or ugraph.vertices[1]

  -- Traverse tree, giving preference to directed edges and, that
  -- failing, to undirected and bidirected edges, and, that failing,
  -- all other edges.
  local marked = {}

  local stacks = { -- 10 stacks for 10 priorities, with 1 being the highest
    { { parent = nil, node = root}, top = 1, bottom = 1 }, 
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1}
  }
  
  local function stack_is_non_empty (s) return s.top >= s.bottom end
  
  while lib.find(stacks, stack_is_non_empty) do
    local parent, node
    
    for _,stack in ipairs(stacks) do
      if stack_is_non_empty(stack) then
	-- Pop
	parent = stack[stack.top].parent
	node = stack[stack.top].node
	
	stack[stack.top] = nil
	stack.top = stack.top - 1

	break
      end
    end
    
    if not marked[node] then
      
      -- The node is good!
      marked[node] = true
      
      if parent then
	tree:connect(parent,node)
      end
      
      local arcs = ugraph:outgoing(node)
      
      for j=1,#arcs do
	local arc = arcs[dfs and j or #arcs - j + 1]
	local head = arc.head

	if not marked[head] then
	  local priority = arc:spanPriority()
	  local stack = assert(stacks[priority], "illegal edge priority")
	  if dfs then
	    stack.top = stack.top + 1
	    stack[stack.top] = { parent = node, node = head}
	  else
	    stack.bottom = stack.bottom - 1
	    stack[stack.bottom] = { parent = node, node = head}
	  end	  
	end
      end
    end
  end

  -- Now, copy vertex list
  local copy = {}
  for i,v in ipairs(tree.vertices) do
    copy[i] = v
  end
  
  -- Now, setup child lists
  for _,v in ipairs(copy) do

    -- Children as they come from the spanning tree computation
    tree:sortOutgoing(v, function (a,b) return a:eventIndex() < b:eventIndex() end)
    local outgoings = tree:outgoing(v)
    
    -- Compute children as they come in the event list:
    local children = {}
    
    local i = (v.event_index or 0)+1
    while i <= #events and events[i].kind == "edge" do
      i = i + 1
    end
    
    if events[i] and events[i].kind == "begin" and events[i].parameters == "descendants" then
      -- Ok, the node is followed by a descendants group
      -- Now scan for nodes that are not inside a descendants group
      local stop = events[i].end_index
      local j = i+1
      while j <= stop do
	if events[j].kind == "node" then
	  children[#children+1] = events[j].parameters
	elseif events[j].kind == "begin" and events[j].parameters == "descendants" then
	  j = events[j].end_index
	end
	j = j + 1
      end

      -- Test, whether outgoings and children contain the same nodes:
      local function same_elements()
	local hash = {}
	for v,c in ipairs(outgoings) do
	  hash[c.head] = true
	end
	local count = 0
	for _,c in pairs(children) do
	  if c ~= "" then
	    count = count + 1
	    if not hash[c] or count > #outgoings then
	      return false
	    end
	  end
	end
	return count == #outgoings
      end

      if same_elements() and #outgoings > 0 then
	
	-- increase number of children, if necessary
	local needed = math.max(#children, Options.lookup('/graph drawing/minimum number of children', v, ugraph))
	for i=1,#children do
	  if children[i] ~= "" then
	    local d = children[i].options['/graph drawing/desired child index']
	    needed = d and math.max(needed, d) or needed
	  end
	end

	local new_children = {}
	for i=1,#children do
	  if children[i] ~= "" then
	    local d = children[i].options['/graph drawing/desired child index']
	    if d then
	      local target = d
	      
	      while new_children[target] do
		target = 1 + (target % #children)
	      end
	      new_children[target] = children[i]
	    end
	  end
	end
	for i=1,#children do
	  if children[i] ~= "" then
	    local d = children[i].options['/graph drawing/desired child index']
	    if not d then
	      local target = i

	      while new_children[target] do
		target = 1 + (target % #children)
	      end
	      new_children[target] = children[i]
	    end
	  end
	end
	for i=1,needed do
	  if not new_children[i] then
	    local new_child = Vertex.new{ kind = "dummy" }
	    new_children[i] = new_child
	    tree:add {new_child}
	    tree:connect(v,new_child)
	  end
	end

	tree:orderOutgoing(v,new_children)
      end
    end
  end
  
  tree.storage.root = root

  return tree
end



-- Done

return SpanningTreeComputation