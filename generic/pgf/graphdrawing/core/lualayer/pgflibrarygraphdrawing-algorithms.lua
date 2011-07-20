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



-- Algorithm to classify edges of a DFS search tree.
--
-- TODO Jannis: document this algorithm as soon as it is completed and bug-free.
--
function algorithms.classify_edges(graph)
  --Sys:log('classify edges:')

  --local stacked = {}
  --local marked = {}
  --local back_edges = {}

  --for node in table.value_iter(graph.nodes) do
  --  marked[node] = false
  --  stacked[node] = false
  --end

  --local function classify_starting_at(node)
  --  Sys:log('  visit ' .. node.name)

  --  if marked[node] then
  --    return
  --  else
  --    marked[node] = true
  --    stacked[node] = true

  --    for edge in table.value_iter(node:getOutgoingEdges()) do
  --      local neighbour = edge:getNeighbour(node)

  --      if stacked[neighbour] then
  --        Sys:log('    reverse ' .. tostring(edge))
  --        edge.reversed = true
  --      else
  --        if not marked[neighbour] then
  --          classify_starting_at(neighbour)
  --        end
  --      end
  --    end

  --    stacked[node] = false
  --  end
  --end

  --for node in table.value_iter(graph.nodes) do
  --  classify_starting_at(node)
  --end

  --return {}, {}, back_edges

  --Sys:log('classify edges:')

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
  --local initial_nodes = table.filter_values(graph.nodes, function (node)
  --  return node:getInDegree() == 0
  --end)

  for node in table.reverse_value_iter(initial_nodes) do
    push(node)
    discovered[node] = true
  end

  while #stack > 0 do
    local node = peek()
    local edges_to_traverse = {}

    --Sys:log('  visit ' .. node.name)
    visited[node] = true

    if not recursed[node] then
      recursed[node] = true

      local out_edges = node:getOutgoingEdges()
      for edge in table.value_iter(out_edges) do
        local neighbour = edge:getNeighbour(node)

        if not discovered[neighbour] then
          --Sys:log('    discovered ' .. neighbour.name)
          --Sys:log('      edge ' .. node.name .. ' => ' .. neighbour.name .. ' is a forward or tree edge')
          table.insert(tree_and_forward_edges, edge)
          table.insert(edges_to_traverse, edge)
        else
          if not completed[neighbour] then
            if not visited[neighbour] then
              --Sys:log('    ' .. neighbour.name .. ' was neither visited nor completed yet')
              --Sys:log('      edge ' .. node.name .. ' -> ' .. neighbour.name .. ' is a forward or tree edge')
              table.insert(tree_and_forward_edges, edge)
              table.insert(edges_to_traverse, edge)
            else
              --Sys:log('    ' .. neighbour.name .. ' visited but not completed')
              --Sys:log('      edge ' .. node.name .. ' => ' .. neighbour.name .. ' is a back edge')
              table.insert(back_edges, edge)
            end
          else
            --Sys:log('    ' .. neighbour.name .. ' visited and completed')
            --Sys:log('      edge ' .. node.name .. ' => ' .. neighbour.name .. ' is a cross edge')
            table.insert(cross_edges, edge)
          end
        end
      end

      if #edges_to_traverse == 0 then
        --Sys:log('    no edges to traverse, node ' .. node.name .. ' is completed')
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
      --Sys:log('    leaving node ' .. node.name .. ', it is completed')
      completed[node] = true
      pop()
    end
  end

  return tree_and_forward_edges, cross_edges, back_edges
end
