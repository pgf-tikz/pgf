-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The Simplifiers class is a singleton object.
-- Its methods allow implement methods for simplifing graphs, for instance 
-- for removing loops or multiedges or computing spanning trees.

local Simplifiers = {}

-- Namespace
local lib     = require "pgf.gd.lib"
lib.Simplifiers = Simplifiers

-- Imports
local AlgorithmLoader = require "pgf.gd.control.AlgorithmLoader"





--
--
-- Spanning Tree Handling
--
--



--- Run a spanning tree algorithm
--
-- This method will use the spanning tree computation method stored in
-- the spanning tree algorithm key to compute a spanning tree of the 
-- algorithm's graph. The spanning tree will be stored in the algorithm 
-- field of the nodes.
--
-- @param parent_algorithm An algorithm object

function Simplifiers:runSpanningTreeAlgorithm(parent_algorithm)

  local spanning_algorithm_class = AlgorithmLoader:subalgorithmClass(
    parent_algorithm.graph:getOption("/graph drawing/spanning tree algorithm"):gsub(' ', ''))

  local spanning_algorithm = spanning_algorithm_class:new(parent_algorithm.graph, parent_algorithm)    
  parent_algorithm.graph:registerAlgorithm(spanning_algorithm)
  
  spanning_algorithm:run()
end




--- Compute a spanning tree of a graph
--
-- The computed spanning tree will be available through the fields
-- [algorithm].children of each node and [algorithm].spanning_tree_root of
-- the graph.
--
-- The algorithm will favor nodes according to their priority. This is determined through an 
-- edge priority function.
--
-- @param graph The graph for which the spanning tree should be computed 
-- @param dfs True if depth first should be used

function Simplifiers:computeSpanningTree (algorithm, dfs)

  local graph = algorithm.graph

  local edge_prioritization_fun = 
    Simplifiers.edge_prioritization_functions [
    graph:getOption('/graph drawing/edge priority method')]

  assert (edge_prioritization_fun, 
   'I do not know the edge priority method "' 
    .. graph:getOption('/graph drawing/edge priority method') ..
    '". Perhaps you misspelled it?')

  local root 

  -- First, is there a root node?
  for _,n in ipairs(graph.nodes) do
    if n:getOption('/graph drawing/root') then
      root = n
      break
    end
  end

  -- Second, should we take the first node?
  if not root and graph:getOption('/graph drawing/root is first node') then
    root = graph.nodrs[1]
  end

  -- Third, use node of minimum level 1 in-degree:
  if not root then
    -- Find first node with in-degree 0:
    for _,n in ipairs(graph.nodes) do
      local indegree_zero = true
      for _,e in ipairs(n.edges) do
	if not (e.direction == "->" and e.nodes[1] == n) then
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
  local stack4 = { top = 0, bottom = 1}
  local stack5 = { top = 0, bottom = 1}

  while    stack1.top >= stack1.bottom 
        or stack2.top >= stack2.bottom
        or stack3.top >= stack3.bottom 
        or stack4.top >= stack4.bottom
        or stack5.top >= stack5.bottom do
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
    elseif stack3.top >= stack3.bottom then
      from, node = pop (stack3)
    elseif stack4.top >= stack4.bottom then
      from, node = pop (stack4)
    else
      from, node = pop (stack5)
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
	local priority = tonumber(e:getOption('/graph drawing/edge priority')) or
                         edge_prioritization_fun(e, node) 
	if priority == 1 then
	  put_if_unmarked (e:getNeighbour(node), stack1)
	elseif priority == 2 then
	  put_if_unmarked (e:getNeighbour(node), stack2)
	elseif priority == 3 then
	  put_if_unmarked (e:getNeighbour(node), stack3)
	elseif priority == 4 then
	  put_if_unmarked (e:getNeighbour(node), stack4)
	elseif priority == 5 then
	  put_if_unmarked (e:getNeighbour(node), stack5)
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
	    new_children[i] = pgf.graphdrawing.VirtualNode:new{ [algorithm] = { children = {} } }
	  end
	end	

	-- Use these children instead:
	n[algorithm].children = new_children
      end
    end

  end

  graph[algorithm].spanning_tree_root = root
end


Simplifiers.edge_prioritization_functions = {
  ['forward first'] = 
    function (e, node)
      if e.direction == "->" and #e.nodes == 2 and not (e.nodes[2] == node) then
	return 2
      elseif e.direction == "--" or e.direction == "<->" then
	return 3
      else
	return 4
      end
    end,
  ['undirected first'] = 
    function (e, node)
      if e.direction == "--" or e.direction == "<->" then
	return 2
      elseif e.direction == "->" and #e.nodes == 2 and not (e.nodes[2] == node) then
	return 3
      else
	return 4
      end
    end,
  ['all the same'] = 
    function (e, node)
      return 3
    end,
}




--- Algorithm to classify edges of a DFS search tree.
--
-- TODO Jannis: document this algorithm as soon as it is completed and bug-free.
-- TT: Replace this algorithm by something else, perhaps?
--
function Simplifiers:classifyEdges(graph)
  local discovered = {}
  local visited = {}
  local recursed = {}
  local completed = {}

  local tree_and_forward_edges = {}
  local cross_edges = {}
  local back_edges = {}

  local stack = {}
  
  local function push(node)
    table.insert(stack, node)
  end

  local function peek()
    return stack[#stack]
  end

  local function pop()
    return table.remove(stack)
  end

  local initial_nodes = graph.nodes

  for node in table.reverse_value_iter(initial_nodes) do
    push(node)
    discovered[node] = true
  end

  while #stack > 0 do
    local node = peek()
    local edges_to_traverse = {}

    visited[node] = true

    if not recursed[node] then
      recursed[node] = true

      local out_edges = node:getOutgoingEdges()
      for edge in table.value_iter(out_edges) do
        local neighbour = edge:getNeighbour(node)

        if not discovered[neighbour] then
          table.insert(tree_and_forward_edges, edge)
          table.insert(edges_to_traverse, edge)
        else
          if not completed[neighbour] then
            if not visited[neighbour] then
              table.insert(tree_and_forward_edges, edge)
              table.insert(edges_to_traverse, edge)
            else
              table.insert(back_edges, edge)
            end
          else
            table.insert(cross_edges, edge)
          end
        end
      end

      if #edges_to_traverse == 0 then
        completed[node] = true
        pop()
      else
        for edge in table.value_iter(table.reverse_values(edges_to_traverse)) do
          local neighbour = edge:getNeighbour(node)
          discovered[neighbour] = true
          push(neighbour)
        end
      end
    else
      completed[node] = true
      pop()
    end
  end

  return tree_and_forward_edges, cross_edges, back_edges
end





--
--
-- Loops and Multiedges
--
--


--- Remove all loops from a graph
--
-- This method will remove all loops from a graph.
--
-- @param algorithm An algorithm object

function Simplifiers:removeLoops(algorithm)
  local graph = algorithm.graph
  local loops = {}

  for _,edge in ipairs(graph.edges) do
    if edge:getHead() == edge:getTail() then
      loops[#loops+1] = edge
    end
  end

  for i=1,#loops do
    graph:deleteEdge(loops[i])
  end
  
  graph[algorithm].loops = loops
end



--- Restore loops that were previously removed.
--
-- @param algorithm An algorithm object

function Simplifiers:restoreLoops(algorithm)
  local graph = algorithm.graph

  for _,edge in ipairs(graph[algorithm].loops) do
    graph:addEdge(edge)
    edge:getTail():addEdge(edge)
  end
  
  graph[algorithm].loops = nil
end




--- Remove all multiedges.
--
-- Every multiedge of the graph will be replaced by a single edge.
--
-- @param algorithm An algorithm object

function Simplifiers:collapseMultiedges(algorithm, collapse_action)
  local graph = algorithm.graph
  local collapsed_edges = {}
  local node_processed = {}

  for _,node in ipairs(graph.nodes) do
    node_processed[node] = true

    local multiedge = {}

    local function handle_edge (edge)
      
      local neighbour = edge:getNeighbour(node)

      if not node_processed[neighbour] then
        if not multiedge[neighbour] then
          multiedge[neighbour] = pgf.graphdrawing.Edge:new{ direction = pgf.graphdrawing.Edge.RIGHT }
          collapsed_edges[multiedge[neighbour]] = {}
        end

	if collapse_action then
	  collapse_action(multiedge[neighbour], edge, graph)
	end

        table.insert(collapsed_edges[multiedge[neighbour]], edge)
      end
    end      
    
    for _,edge in ipairs(node:getIncomingEdges()) do
      handle_edge(edge)
    end
    
    for _,edge in ipairs(node:getOutgoingEdges()) do
      handle_edge(edge)
    end

    for neighbour, multiedge in pairs(multiedge) do

      if #collapsed_edges[multiedge] <= 1 then
        collapsed_edges[multiedge] = nil
      else
        for _,subedge in ipairs(collapsed_edges[multiedge]) do
          graph:deleteEdge(subedge)
        end

        multiedge:addNode(node)
        multiedge:addNode(neighbour)
        
        graph:addEdge(multiedge)
      end
    end
  end

  graph[algorithm].collapsed_edges = collapsed_edges
end


--- Expand multiedges that were previously collapsed
--
-- @param algorithm An algorithm object

function Simplifiers:expandMultiedges(algorithm)
  local graph = algorithm.graph
  for multiedge, subedges in pairs(graph[algorithm].collapsed_edges) do
    assert(#subedges >= 2)

    graph:deleteEdge(multiedge)

    for _,edge in ipairs(subedges) do
      
      -- Copy bend points 
      for _,p in ipairs(multiedge.bend_points) do
	edge.bend_points[#edge.bend_points+1] = p:copy()
      end

      -- Copy options
      for k,v in pairs(multiedge.algorithmically_generated_options) do
	edge.algorithmically_generated_options[k] = v
      end

      for node in table.value_iter(edge.nodes) do
        node:addEdge(edge)
      end

      graph:addEdge(edge)
    end
  end

  graph[algorithm].collapsed_edges = nil
end





-- Done

return Simplifiers