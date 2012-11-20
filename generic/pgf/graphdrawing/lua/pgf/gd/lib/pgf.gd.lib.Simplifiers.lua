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

local Edge            = require "pgf.gd.deprecated.Edge"
local Node            = require "pgf.gd.deprecated.Node"





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

  for i=#initial_nodes,1,-1 do
    local node = initial_nodes[i] 
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
      for _,edge in ipairs(out_edges) do
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
	for i=#edges_to_traverse,1,-1 do
          local neighbour = edges_to_traverse[i]:getNeighbour(node)
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

function Simplifiers:removeLoopsOldModel(algorithm)
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

function Simplifiers:restoreLoopsOldModel(algorithm)
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

function Simplifiers:collapseMultiedgesOldModel(algorithm, collapse_action)
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
          multiedge[neighbour] = Edge.new{ direction = Edge.RIGHT }
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

function Simplifiers:expandMultiedgesOldModel(algorithm)
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

      for _,node in ipairs(edge.nodes) do
        node:addEdge(edge)
      end

      graph:addEdge(edge)
    end
  end

  graph[algorithm].collapsed_edges = nil
end





-- Done

return Simplifiers