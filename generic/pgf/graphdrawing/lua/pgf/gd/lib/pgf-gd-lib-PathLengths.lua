-- Copyright 2011 by Jannis Pohlmann
-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The PathLengths class is a singleton object.
--
-- It implements algorithms for computing distances between nodes of a graph 
-- (in the sense of path lengths).

local PathLengths = {}

-- Namespace
local lib     = require "pgf.gd.lib"
lib.PathLengths = PathLengths




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

function PathLengths:dijkstra(graph, source)
  local distance = {}
  local levels = {}
  local parent = {}

  local queue = lib.PriorityQueue:new()

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




--- Performs the Floyd-Warshall algorithm to solve the all-source shortes path problem. 
--
-- @param graph  The graph to compute the shortest paths for.
--
-- @return A distance matrix

function PathLengths:floydWarshall(graph)
  local distance = {}
  local infinity = math.huge

  for i in table.value_iter(graph.nodes) do
    distance[i] = {}
    for j in table.value_iter(graph.nodes) do
      distance[i][j] = infinity
    end
  end

  for i in table.value_iter(graph.nodes) do
    for edge in table.value_iter(i.edges) do
      local j = edge:getNeighbour(i)
      distance[i][j] = edge.weight or 1
    end
  end

  for k in table.value_iter(graph.nodes) do
    for i in table.value_iter(graph.nodes) do
      for j in table.value_iter(graph.nodes) do
        distance[i][j] = math.min(distance[i][j], distance[i][k] + distance[k][j])
      end
    end
  end

  return distance
end




--- Computes the pseudo diameter of a graph.
--
-- The diameter of a graph is the maximum of the shortest paths between
-- any pair of nodes in the graph. A pseudo diameter is an approximation
-- of the diameter that is computed by picking a starting node |u| and
-- finding a node |v| that is farthest away from |u| and has the smallest
-- degree of all nodes that have the same distance to |u|. The algorithm
-- continues with |v| as the new starting node and iteratively tries
-- to find an end node that is generates a larger pseudo diameter.
-- It terminates as soon as no such end node can be found.
--
-- @param graph The graph.
--
-- @return The pseudo diameter of the graph.
-- @return The start node of the corresponding approximation of a maximum
--         shortest path.
-- @return The end node of that path.
--
function PathLengths:pseudoDiameter(graph)

  -- find a node with minimum degree
  local start_node = table.combine_values(graph.nodes, function (min, node)
    if node:getDegree() < min:getDegree() then
      return node
    else
      return min
    end
  end, graph.nodes[1])

  assert(start_node)

  local old_diameter = 0
  local diameter = 0
  local end_node = nil

  while true do
    local distance, levels = lib.PathLengths:dijkstra(graph, start_node)

    -- the number of levels is the same as the distance of the nodes
    -- in the last level to the start node
    old_diameter = diameter
    diameter = #levels

    -- abort if the diameter could not be improved
    if diameter == old_diameter then
      end_node = levels[#levels][1]
      break
    end

    -- select the node with the smallest degree from the last level as
    -- the start node for the next iteration
    start_node = table.combine_values(levels[#levels], function (min, node)
      if node:getDegree() < min:getDegree() then
        return node
      else
        return min
      end
    end, levels[#levels][1])

    assert(start_node)
  end

  assert(start_node)
  assert(end_node)

  return diameter, start_node, end_node
end





-- Done

return PathLengths