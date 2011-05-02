-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

pgf.module("pgf.graphdrawing")



--- 
--
-- @param graph   The graph to draw.
--
function drawGraphAlgorithm_simplelayered(graph)
  -- read options passed to the algorithm from TikZ
  graph:setOption('node distance', graph:getOption('node distance') or 58.5)

  for node in table.value_iter(graph.nodes) do
    Sys:logMessage('LAY: ' .. node.name .. ' in: ' .. node:getInDegree() .. ' out: ' .. node:getOutDegree())
    local in_edges = node:getIncomingEdges()
    Sys:logMessage('LAY:   incoming edges:')
    for edge in table.value_iter(in_edges) do
      Sys:logMessage('LAY:   ' .. tostring(edge))
    end
    local out_edges = node:getOutgoingEdges()
    Sys:logMessage('LAY:   outgoing edges:')
    for edge in table.value_iter(out_edges) do
      Sys:logMessage('LAY:   ' .. tostring(edge))
    end
    Sys:logMessage('LAY:')
  end

  -- convert node positions to vectors
  for node in table.value_iter(graph.nodes) do
    local pos = { node.pos.x, node.pos.y }
    node.position = Vector:new(2, function (n) return pos[n] end)
  end

  removeCycles(graph)
  local layers = computeLayering(graph)
  local original_edges, dummy_nodes = convertToProperLayout(graph, layers)
  reduceEdgeCrossings(graph, layers)

  assignCoordinates(graph, layers, original_edges, dummy_nodes)

  -- Reset edges reversed internally
  --for edge in table.value_iter(graph.edges) do
  --  edge.reversed = false
  --end

  -- Scale the output drawing 
  for node in table.value_iter(graph.nodes) do
    node.pos.x =  node.position:get(1) * graph:getOption('node distance')
    node.pos.y = -node.position:get(2) * graph:getOption('node distance')
  end

  for edge in table.value_iter(graph.edges) do
    for point in table.value_iter(edge.bend_points) do
      point:set(1,  point:get(1) * graph:getOption('node distance'))
      point:set(2, -point:get(2) * graph:getOption('node distance'))
    end
  end

  -- Use spring algorithm to draw the graph
  --require('pgflibrarygraphdrawing-algorithms-spring.lua')
  --drawGraphAlgorithm_spring(graph)
end



function removeCycles(graph)
  local acyclic_set = {}
  local deleted = {}

  local function isNotDeletedEdge(edge)
    return not deleted[edge]
  end

  for node in table.value_iter(graph.nodes) do
    local in_edges = node:getIncomingEdges()
    local out_edges = node:getOutgoingEdges()

    in_edges = table.filter_values(in_edges, isNotDeletedEdge)
    out_edges = table.filter_values(out_edges, isNotDeletedEdge)

    if table.count_pairs(out_edges) >= table.count_pairs(in_edges) then
      for edge in table.value_iter(out_edges) do
        acyclic_set[edge] = true
      end
    else
      for edge in table.value_iter(in_edges) do
        acyclic_set[edge] = true
      end
    end

    for edge in table.value_iter(in_edges) do
      deleted[edge] = true
    end
    for edge in table.value_iter(out_edges) do
      deleted[edge] = true
    end
  end

  local function isReversedEdge(edge)
    return not acyclic_set[edge]
  end

  for edge in iter.filter(table.value_iter(graph.edges), isReversedEdge) do
    edge.reversed = true
  end
end



function computeLayering(graph)
  local layers = {}

  for node in traversal.topological_sorting(graph) do
    local in_edges = node:getIncomingEdges()

    if #in_edges == 0 then
      -- we have a sink => place it at the first layer
      layers[1] = layers[1] or {}
      table.insert(layers[1], node)
      node.position:set(2, 1)
    else
      -- we have a regular node, find out the layers of its neighbours
      local neighbour_layers = table.map_values(in_edges, function (edge)
        local neighbour = edge:getNeighbour(node)
        return neighbour.position:get(2)
      end)

      -- compute the maximum layer of the neighbours
      local max_layer = table.combine_values(neighbour_layers, function (max, layer)
        return math.max(max, layer)
      end, 1)

      -- place the node one layer above/below all its neighbours
      layers[max_layer+1] = layers[max_layer+1] or {}
      table.insert(layers[max_layer+1], node)
      node.position:set(2, max_layer+1)
    end
  end

  return layers
end



function convertToProperLayout(graph, layers)
  dumpLayers(layers)
  dumpGraph(graph)

  -- enumerate dummy nodes using a unique (incremented) numeric ID
  local dummy_node_id = 1

  -- keep track of original edges removed
  local original_edges = {}

  -- also keep track of dummy nodes and edges introduced
  local dummy_nodes = {}

  for node in traversal.topological_sorting(graph) do
    local in_edges = node:getIncomingEdges()
    if #in_edges > 0 then
      for edge in table.value_iter(in_edges) do
        local neighbour = edge:getNeighbour(node)
        local dist = node.position:get(2) - neighbour.position:get(2)

        if dist > 1 then
          local dummies = {}

          for i in iter.times(dist-1) do
            local name = 'dummy@' .. dummy_node_id
            dummy_node_id = dummy_node_id + 1

            dummies[i] = Node:new{name = name}

            local pos = { 0, neighbour.position:get(2) + i }
            dummies[i].position = Vector:new(2, function (n) return pos[n] end)

            graph:addNode(dummies[i])

            table.insert(layers[pos[2]], dummies[i])

            table.insert(dummy_nodes, dummies[i])
            table.insert(edge.bend_nodes, dummies[i])
          end

          table.insert(dummies, 1, neighbour)
          table.insert(dummies, #dummies+1, node)

          for i = 2,#dummies do
            local source = dummies[i-1]
            local target = dummies[i]

            local new_edge = Edge:new{
              direction = Edge.RIGHT, 
              reversed = false, 
              -- FIXME: edge.reversed and not edge.reversed did not work
              -- what is correct here?
            }
            new_edge:addNode(source)
            new_edge:addNode(target)

            graph:addEdge(new_edge)
          end
          
          table.insert(original_edges, edge)
        end
      end
    end
  end

  for edge in table.value_iter(original_edges) do
    graph:deleteEdge(edge)
  end

  return original_edges, dummy_nodes --, dummy_edges
end



function reduceEdgeCrossings(graph, layers)
  --dumpLayers(layers)
  --dumpGraph(graph)

  local function compare_nodes(a, b)
    if not a then
      return true
    elseif not b then
      return false
    else
      return a.position:get(1) <= b.position:get(2)
    end
  end

  local next_x = 0
  for node in traversal.depth_first_dag(graph, layers[1]) do
    node.position:set(1, next_x)
    next_x = next_x + 1
  end

  for layer in table.value_iter(layers) do
    table.sort(layer, compare_nodes)
  end

  for i = 2,#layers do
    for node in table.value_iter(layers[i]) do 
      local in_edges = node:getIncomingEdges()

      local positions = table.map_values(in_edges, function (edge)
        local neighbour = edge:getNeighbour(node)
        return neighbour.position:get(1)
      end)

      local sum = table.combine_values(positions, function (sum, pos)
        return sum + pos
      end, 0)

      local avg = sum / #in_edges

      node.position:set(1, avg)
    end

    for l = 1,#layers[i] do
      for m = l+1,#layers[i] do
        if layers[i][l].position:get(1) == layers[i][m].position:get(1) then
          layers[i][m].position:set(1, layers[i][m].position:get(1) + 0.001)
        end
      end
    end

    table.sort(layers[i], compare_nodes)
  end

  for node in table.value_iter(graph.nodes) do
    node.position:set(1, 0)
  end
end



function assignCoordinates(graph, layers, original_edges, dummy_nodes, dummy_edges)
  -- initial positioning from left to right
  for layer in table.value_iter(layers) do
    local layer_x = 0
    for node in table.value_iter(layer) do
      node.position:set(1, layer_x)
      layer_x = layer_x + 1
    end
  end

  for i = 2,#layers do
    for node in table.value_iter(layers[i]) do
      local in_edges = node:getIncomingEdges()

      local positions = table.map_values(in_edges, function (edge)
        local neighbour = edge:getNeighbour(node)
        return neighbour.position:get(1)
      end)

      local sum = table.combine_values(positions, function (sum, pos)
        return sum + pos
      end, 0)

      local avg = sum / #in_edges

      node.position:set(1, avg)
    end

    for l = 1,#layers[i] do
      for m = l+1,#layers[i] do
        local diff = layers[i][m].position:get(1) - layers[i][l].position:get(1)
        if math.abs(diff) < 1 then
          layers[i][m].position:set(1, layers[i][m].position:get(1) + (1 - math.abs(diff)))
        end
      end
    end

    Sys:logMessage('positions at layer ' .. i)
    for node in table.value_iter(layers[i]) do
      Sys:logMessage('  ' .. tostring(node) .. ' = ' .. node.position:get(1))
    end
  end

  -- delete dummy nodes
  for node in table.value_iter(dummy_nodes) do
    graph:deleteNode(node)
  end

  -- add original edge again
  for edge in table.value_iter(original_edges) do
    graph:addEdge(edge)

    for node in table.value_iter(edge.nodes) do
      node:addEdge(edge)
    end

    for bend_node in table.value_iter(edge.bend_nodes) do
      local point = Vector:new(2, function (n) return bend_node.position:get(n) end)
      table.insert(edge.bend_points, point)
    end
  end
end



function dumpGraph(graph)
  Sys:logMessage('LAY: GRAPH:')
  for node in table.value_iter(graph.nodes) do
    Sys:logMessage('LAY:   ' .. tostring(node))
  end
  for edge in table.value_iter(graph.edges) do 
    Sys:logMessage('LAY:   ' .. tostring(edge))
  end
  Sys:logMessage('LAY:')
end



function dumpLayers(layers)
  for index, layer in ipairs(layers) do
    Sys:logMessage('layer ' .. index .. ':')
    for node in table.value_iter(layer) do
      Sys:logMessage('  ' .. tostring(node))
    end
  end
end
