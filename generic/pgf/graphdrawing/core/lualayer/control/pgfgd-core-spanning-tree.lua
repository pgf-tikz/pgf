-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file defines an edge class, used in the graph representation.

pgf.module("pgf.graphdrawing")



--- Compute a spanning tree of a graph
--
-- The computed spanning tree will be available through the fields
-- algorithm.children of each node and algorithm.spanning_tree_root of
-- the graph.
--
-- @param graph The graph for which the spanning tree should be computed 

function compute_spanning_tree (algorithm)
  local graph = algorithm.graph

  -- Should we do dfs or bfs? Check option
  local dfs = graph:getOption('/graph drawing/spanning tree method') == "depth first search"

  local root 

  -- First, is there a root node?
  for _,n in ipairs(graph.nodes) do
    if n:getOption('/graph drawing/root') then
      root = n
      break
    end
  end

  if not root then
    -- Find first node with in-degree 0:
    for _,n in ipairs(graph.nodes) do
      local indegree_zero = true
      for _,e in ipairs(n.edges) do
	if not (e.direction == Edge.RIGHT and e.nodes[1] == n) then
	  indegree_zero = false
	  break
	end
      end
      if indegree_zero then
	root = n
	break
      end
    end
  end
  root = root or graph.nodes[1]

  -- Traverse tree, giving preference to directed edges and, that
  -- failing, to undirected and bidirected edges, and, that failing,
  -- all other edges.
  local marked = {}

  local stack1 = { { nil, root}, top = 1, bottom = 1 }
  local stack2 = { top = 0, bottom = 1}
  local stack3 = { top = 0, bottom = 1}

  while stack1.top >= stack1.bottom or stack2.top >= stack2.bottom or stack3.top >= stack3.bottom do
    local from, node

    local function pop (stack)
      local f, n = stack[stack.top][1], stack[stack.top][2]
      stack[stack.top] = nil
      stack.top = stack.top - 1
      return f, n
    end

    if stack1.top >= stack1.bottom then
      from, node = pop (stack1)
    elseif stack2.top >= stack2.bottom then
      from, node = pop (stack2)
    else
      from, node = pop (stack3)
    end
    
    if not marked[node] then
      
      -- The edge is good!
      marked[node] = true
      if from then
	from[algorithm].children = from[algorithm].children or {}
	table.insert(from[algorithm].children, node) 
      end
      
      local function put_if_unmarked(n, stack)
	if not marked[n] then
	  if dfs then
	    stack.top = stack.top + 1
	    stack[stack.top] = {node, n}
	  else
	    stack.bottom = stack.bottom - 1
	    stack[stack.bottom] = {node, n}
	  end
	end
      end
      
      for j=1,#node.edges do
	local i = j
	if dfs then i = #node.edges - j + 1 end
	
	local e = node.edges[i]
	if e.direction == Edge.RIGHT and #e.nodes == 2 and not (e.nodes[2] == node) then
	  put_if_unmarked (e.nodes[2], stack1)
	elseif e.direction == Edge.UNDIRECTED or e.direction == Edge.BOTH then
	  put_if_unmarked (e:getNeighbour(node), stack2)
	else
	  put_if_unmarked (e:getNeighbour(node), stack3)
	end
      end
    end
  end
  
  
  -- Now, setup child lists
  for _,n in ipairs(graph.nodes) do

    -- Children as they come from the spanning tree computation
    local sp_children = n[algorithm].children or {}
    table.sort (sp_children, function (a,b) return a.event_index < b.event_index end)
    n[algorithm].children = sp_children
    
    -- Compute children as they come in the event list:
    local children = {}
    
    local events = graph.events
    local i = n.event_index+1
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

      -- Test, whether sp_children and children contain the same nodes:
      local function same_elements()
	local hash = {}
	for _,c in pairs(sp_children) do
	  hash[c] = true
	end
	local count = 0
	for _,c in pairs(children) do
	  if c ~= "" then
	    count = count + 1
	    if not hash[c] or count > #sp_children then
	      return false
	    end
	  end
	end
	return count == #sp_children
      end

      if same_elements() then
	
	-- increase number of children, if necessary
	local needed = math.max(#children, tonumber(n:getOption('/graph drawing/minimum number of children', graph)))
	for i=1,#children do
	  if children[i] ~= "" then
	    local d = children[i]:getOption('/graph drawing/desired child index')
	    needed = d and math.max(needed, tonumber(d)) or needed
	  end
	end

	local new_children = {}
	for i=1,#children do
	  if children[i] ~= "" then
	    local d = children[i]:getOption('/graph drawing/desired child index')
	    if d then
	      local target = tonumber(d)
	      
	      while new_children[target] do
		target = 1 + (target % #children)
	      end
	      new_children[target] = children[i]
	    end
	  end
	end
	for i=1,#children do
	  if children[i] ~= "" then
	    local d = children[i]:getOption('/graph drawing/desired child index')
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
	    new_children[i] = VirtualNode:new{ [algorithm] = { children = {} } }
	  end
	end	

	-- Use these children instead:
	n[algorithm].children = new_children
      end
    end

  end

  graph[algorithm].spanning_tree_root = root
end