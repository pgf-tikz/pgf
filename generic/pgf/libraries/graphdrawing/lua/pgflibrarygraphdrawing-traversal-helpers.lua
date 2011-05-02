-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

--- This file implements a number of graph traversal functions including
--- depth-first and breadth-first search, traversal using a topological sorting
--- and a few others.

pgf.module("pgf.graphdrawing")

traversal = {}



--- Iterator for traversing a directed graph using a topological sorting.
--
-- A topological sorting of a directed graph is a linear ordering of its
-- nodes such that, for every edge (u,v), u comes before v.
--
-- Important note: if performed on a graph with at least one cycle a
-- topological sorting is impossible. Thus, the nodes returned from the
-- iterator are not guaranteed to satisfy the "u comes before v" 
-- criterion. The iterator may even terminate early or loop forever.
--
-- @param graph A directed acyclic graph.
--
-- @return An iterator for traversing the graph in a topological order.
--
function traversal.topological_sorting(graph)
  -- track visited edges 
  local deleted_edges = {}

  -- returns true if an edge has not been visited yet
  local function isNotDeletedEdge(edge)
    return not deleted_edges[edge]
  end

  -- collect all sources (nodes with no incoming edges) of the graph
  local sources = table.filter_values(graph.nodes, function (node)
    return node:getInDegree() == 0
  end)

  -- return the iterator function
  return function () 
    while #sources > 0 do
      -- fetch the next sink from the queue
      local source = table.remove(sources, 1)

      -- get its outgoing edges
      local out_edges = source:getOutgoingEdges()
      
      -- iterate over all outgoing edges we haven't visited yet
      for edge in iter.filter(table.value_iter(out_edges), isNotDeletedEdge) do
        -- mark the edge as visited
        deleted_edges[edge] = true

        -- get the node at the other end of the edge
        local neighbour = edge:getNeighbour(source)

        -- get a list of all incoming edges of the neighbour that have
        -- not been visited yet
        local in_edges = neighbour:getIncomingEdges()
        in_edges = table.filter_values(in_edges, isNotDeletedEdge)

        -- if there are no such edges then we have a new source
        if #in_edges == 0 then
          table.insert(sources, neighbour)
        end
      end

      -- return the current source
      return source
    end

    -- the iterator terminates if there are no sources left
    return nil
  end
end



--- TODO add documentation
function traversal.depth_first_dag(graph, initial_nodes)
  local visited = {}
  local stack = {}
  local explored = {}

  local function edgeNotExplored(edge)
    return not explored[edge]
  end

  if not initial_nodes or #initial_nodes == 0 then
    -- collect all sinks (nodes with no incoming edges) of the graph
    inital_nodes = table.filter_values(graph.nodes, function (node)
      return node:getInDegree() == 0
    end)
  end

  for node in table.value_iter(initial_nodes) do
    table.insert(stack, node)
    visited[node] = true
  end

  return function ()
    while #stack > 0 do
      local node = table.remove(stack)
      Sys:logMessage('VISIT: ' .. tostring(node))

      local out_edges = node:getOutgoingEdges()
      for edge in iter.filter(table.value_iter(out_edges), edgeNotExplored) do
        explored[edge] = true

        local neighbour = edge:getNeighbour(node)
        
        if not visited[neighbour] then
          table.insert(stack, neighbour)
          visited[neighbour] = true
        end
      end

      return node
    end
    return nil
  end
end
