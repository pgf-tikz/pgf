-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file contains a number of standard graph algorithms such as Dijkstra.

pgf.module("pgf.graphdrawing")



algorithms = {}



--- Performs the Dijkstra algorithm to solve the single-source shortes path problem.
--
-- The algorithm computes the shortest paths from \meta{source} to all nodes 
-- in the graph. It also generates a table with distance level sets, each of 
-- which  contain all nodes that have the same corresponding distance to 
-- \meta{source}. Finally, a mapping of nodes to their parents along the
-- shortest paths is generated to allow the reconstruction of the paths
-- that were chosen by the Dijkstra algorithm.
--
-- @param graph  The graph to compute the shortest paths for.
-- @param source The node to compute the distances to.
--
-- @return A mapping of nodes to their distance to \meta{source}. 
-- @return An array of distance level sets. The set at index |i| contains
--         all nodes that have a distance of |i| to \meta{source}.
-- @return A mapping of nodes to their parents to allow the reconstruction
--         of the shortest paths chosen by the Dijkstra algorithm.
--
function algorithms.dijkstra(graph, source)
  local distance = {}
  local levels = {}
  local parent = {}

  local queue = PriorityQueue:new()

  -- reset the distance of all nodes and insert them into the priority queue
  for node in table.value_iter(graph.nodes) do
    if node == source then
      distance[node] = 0
      parent[node] = nil
      queue:enqueue(node, distance[node])
    else
      distance[node] = #graph.nodes + 1 -- this is about infinity ;)
      queue:enqueue(node, distance[node])
    end
  end

  while not queue:isEmpty() do
    local u = queue:dequeue()

    assert(distance[u] < #graph.nodes + 1, 'the graph is not connected, Dijkstra will not work')

    if distance[u] > 0 then
      levels[distance[u]] = levels[distance[u]] or {}
      table.insert(levels[distance[u]], u)
    end

    for edge in table.value_iter(u.edges) do
      local v = edge:getNeighbour(u)
      local alternative = distance[u] + 1
      if alternative < distance[v] then
        distance[v] = alternative

        parent[v] = u

        -- update the priority of v
        queue:updatePriority(v, distance[v])
      end
    end
  end

  return distance, levels, parent
end



function algorithms.floyd_warshall(graph)
  local distance = {}
  local infinity = #graph.nodes + 1

  for i in table.value_iter(graph.nodes) do
    for edge in table.value_iter(i.edges) do
      local j = edge:getNeighbour(i)

      distance[i] = distance[i] or {}
      distance[i][j] = edge.weight or 1
    end
  end

  for k = 1, #graph.nodes do
    for i = 1, #graph.nodes do
      for j = i + 1, #graph.nodes do
        local d_ij = (distance[i] and distance[i][j]) and distance[i][j] or infinity
        local d_ik = (distance[i] and distance[i][k]) and distance[i][k] or infinity
        local d_kj = (distance[k] and distance[k][j]) and distance[k][j] or infinity

        distance[i] = distance[i] or {}
        distance[i][j] = math.min(d_ij, d_ik + d_kj)
      end
    end
  end

  return distance
end
