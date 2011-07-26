-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License.
--
-- See the file doc/generic/pgf/licenses/LICENSE for more details.

-- @release $Header$

--- TODO Jannis: Add documentation for the file.

pgf.module("pgf.graphdrawing")



manipulation = {}



function manipulation.remove_loops(graph)
  local loops = {}

  for edge in table.value_iter(graph.edges) do
    if edge:isLoop() then
      table.insert(loops, edge)
    end
  end

  for edge in table.value_iter(loops) do
    graph:deleteEdge(edge)
  end

  return loops
end



function manipulation.restore_loops(graph, loops)
  for edge in table.value_iter(loops) do
    graph:addEdge(edge)
    edge:getTail():addEdge(edge)
  end
end



function manipulation.merge_multiedges(graph)
  local individual_edges = {}

  Sys:log('merge multiedges:')

  local node_processed = {}

  for node in table.value_iter(graph.nodes) do
    Sys:log('  neighbour edges of ' .. node.name)

    node_processed[node] = true

    local multiedge = {}
    
    for edge in table.value_iter(node:getIncomingEdges()) do
      local neighbour = edge:getNeighbour(node)
      if not node_processed[neighbour] then
        if not multiedge[neighbour] then
          multiedge[neighbour] = Edge:new{
            direction = Edge.RIGHT,
            weight = 0,
            minimum_levels = 0,
          }

          individual_edges[multiedge[neighbour]] = {}
        end

        multiedge[neighbour].weight = multiedge[neighbour].weight + edge.weight
        multiedge[neighbour].minimum_levels = math.max(multiedge[neighbour].minimum_levels, edge.minimum_levels)

        table.insert(individual_edges[multiedge[neighbour]], edge)
      end
    end

    for edge in table.value_iter(node:getOutgoingEdges()) do
      local neighbour = edge:getNeighbour(node)
      if not node_processed[neighbour] then
        if not multiedge[neighbour] then
          multiedge[neighbour] = Edge:new{
            direction = Edge.RIGHT,
            weight = 0,
            minimum_levels = 0,
          }

          individual_edges[multiedge[neighbour]] = {}
        end

        multiedge[neighbour].weight = multiedge[neighbour].weight + edge.weight
        multiedge[neighbour].minimum_levels = math.max(multiedge[neighbour].minimum_levels, edge.minimum_levels)

        table.insert(individual_edges[multiedge[neighbour]], edge)
      end
    end

    for neighbour, multiedge in pairs(multiedge) do
      Sys:log('    with neighbour ' .. neighbour.name)

      for subedge in table.value_iter(individual_edges[multiedge]) do
        Sys:log('      ' .. tostring(subedge))
      end

      if #individual_edges[multiedge] <= 1 then
        individual_edges[multiedge] = nil
      else
        multiedge.weight = multiedge.weight / #individual_edges[multiedge]

        for subedge in table.value_iter(individual_edges[multiedge]) do
          graph:deleteEdge(subedge)
        end

        multiedge:addNode(node)
        multiedge:addNode(neighbour)
        
        graph:addEdge(multiedge)
      end
    end
  end

  return individual_edges
end



function manipulation.restore_multiedges(graph, individual_edges)
  for multiedge, subedges in pairs(individual_edges) do
    assert(#subedges >= 2)

    Sys:log('restore multiedges of ' .. multiedge:getTail().name .. ' and ' .. multiedge:getHead().name)

    graph:deleteEdge(multiedge)

    for edge in table.value_iter(subedges) do
      for node in table.value_iter(edge.nodes) do
        node:addEdge(edge)
      end

      graph:addEdge(edge)
    end
  end
end
