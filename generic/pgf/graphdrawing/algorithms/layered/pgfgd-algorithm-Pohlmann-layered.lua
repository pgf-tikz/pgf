-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

pgf.module("pgf.graphdrawing")



PohlmannLayered = {}
PohlmannLayered.__index = PohlmannLayered



--- Implementation of a layered drawing algorithm for directed graphs.
-- 
-- This implementation is based on the paper 
--
--   "A Technique for Drawing Directed Graphs"
--   Gansner, Koutsofios, North, Vo, 1993
--
-- Modifications compared to the original algorithm are explained in the manual.
--
function drawGraphAlgorithm_Pohlmann_layered(graph)
  local algorithm = PohlmannLayered:new(graph)

  algorithm:initialize()
  algorithm:run()

  ---- fall back to Hu2006 spring electrical for now, just to see the effects
  ---- of the preprocessing steps
  --require('../force/pgfgd-algorithm-Hu2006-spring-electrical.lua')
  --graph:setOption('/graph drawing/spring electrical layout/iterations', 500)
  --graph:setOption('/graph drawing/spring electrical layout/cooling factor', 0.95)
  --graph:setOption('/graph drawing/spring electrical layout/random seed', 42)
  --graph:setOption('/graph drawing/spring electrical layout/initial step dimension', 28.5)
  --graph:setOption('/graph drawing/spring electrical layout/convergence tolerance', 0.01)
  --graph:setOption('/graph drawing/spring electrical layout/spring constant', 0.2)
  --graph:setOption('/graph drawing/spring electrical layout/natural spring dimension', 28.5)
  --graph:setOption('/graph drawing/spring electrical layout/coarsen', true)
  --graph:setOption('/graph drawing/spring electrical layout/coarsening/downsize ratio', 0.25)
  --graph:setOption('/graph drawing/spring electrical layout/coarsening/minimum graph size', 2)
  --graph:setOption('/graph drawing/spring electrical layout/coarsening/collapse independent edges', true)
  --drawGraphAlgorithm_Hu2006_spring_electrical(graph)

  orientation.adjust(graph)
end



function PohlmannLayered:new(graph)
  local algorithm = {
    level_distance = tonumber(graph:getOption('/graph drawing/layered drawing/level distance')),
    sibling_distance = tonumber(graph:getOption('/graph drawing/layered drawing/sibling distance')),

    graph = graph,
  }
  setmetatable(algorithm, PohlmannLayered)

  -- validate input parameters

  return algorithm
end



function PohlmannLayered:initialize()
  -- initialize edge parameters
  for edge in table.value_iter(self.graph.edges) do
    edge.weight = tonumber(edge:getOption('/graph drawing/layered drawing/weight'))
    edge.minimum_levels = tonumber(edge:getOption('/graph drawing/layered drawing/minimum levels'))
  end
end



function PohlmannLayered:run()
  self:preprocess()

  local layers = self:assignLayers()
  local original_edges, dummy_nodes = self:insertDummyNodes(layers)
  self:reduceEdgeCrossings(layers)
  self:assignCoordinates(layers)
  self:removeDummyNodes(layers, original_edges, dummy_nodes)
  -- self:makeSplines()
  
  self:postprocess()
end



function PohlmannLayered:preprocess()
  -- merge nonempty sets into supernodes
  --
  -- ignore self-loops
  --
  -- merge multiple edges into one edge each, whose weight is the sum of the 
  --   individual edge weights
  --
  -- ignore leaf nodes that are not part of the user-defined sets (their ranks 
  --   are trivially determined)
  --
  -- ensure that supernodes S_min and S_max are assigned first and last ranks
  --   reverse in-edges of S_min
  --   reverse out-edges of S_max
  --
  -- ensure the supernodes S_min and S_max are are the only nodes in these ranks
  --   for all nodes with indegree of 0, insert temporary edge (S_min, v) with delta=0
  --   for all nodes with outdegree of 0, insert temporary edge (v, S_max) with delta=0
  
  local tree_or_forward_edges, cross_edges, back_edges = algorithms.classify_edges(self.graph)

  for edge in table.value_iter(back_edges) do
    Sys:log('reverse edge ' .. edge.nodes[1].name .. ' -> ' .. edge.nodes[2].name)
    edge.reversed = true
  end
end



function PohlmannLayered:postprocess()
  for edge in table.value_iter(self.graph.edges) do
    edge.reversed = false
  end
end



--- Layer assignment using longest path layering.
--
-- Originally proposed by Mehlhorn in 1984, this algorithm visits the
-- nodes in a topological order. Sinks are placed in layer 0, all
-- other nodes are placed in the layer M, where M is the length of
-- the longest path from a sink to the node.
--
-- The layer assignment algorithm runs in linear time O(V+E).
--
function PohlmannLayered:assignLayers()
  local layers = {}

  for node in traversal.topological_sorting(self.graph) do
    local in_edges = node:getIncomingEdges()

    if #in_edges == 0 then
      -- we have a sink, move it to the first layer
      layers[1] = layers[1] or {}
      table.insert(layers[1], node)

      -- remember the layer of this node
      node.pos:set{y = 1}
    else
      -- we have a regular node, find out the maximum layer of its neighbours
      local max_layer = table.combine_values(in_edges, function (max_layer, edge)
        return math.max(max_layer, edge:getNeighbour(node).pos:y()) 
      end, 1)

      -- move the node to the next layer compared to all its neighbours
      layers[max_layer+1] = layers[max_layer+1] or {}
      table.insert(layers[max_layer+1], node)

      -- remember the layer of this node
      node.pos:set{y = max_layer+1}
    end
  end

  return layers
end



function PohlmannLayered:insertDummyNodes(layers)
  -- enumerate dummy nodes using a globally unique numeric ID
  local dummy_id = 1

  -- keep track of the original edges removed
  local original_edges = {}

  -- keep track of dummy nodes introduced
  local dummy_nodes = {}

  for node in traversal.topological_sorting(self.graph) do
    local in_edges = node:getIncomingEdges()

    for edge in table.value_iter (in_edges) do
      local neighbour = edge:getNeighbour(node)
      local dist = node.pos:y() - neighbour.pos:y()

      if dist > 1 then
        local dummies = {}

        for i in iter.times(dist-1) do
          local layer = neighbour.pos:y() + i

          local dummy = Node:new{
            pos = Vector:new({ 0, layer }),
            name = 'dummy@' .. neighbour.name .. '@to@' .. node.name .. '@at@' .. layer,
          }
          
          dummy_id = dummy_id + 1

          self.graph:addNode(dummy)

          table.insert(layers[dummy.pos:y()], dummy)

          table.insert(dummy_nodes, dummy)
          table.insert(edge.bend_nodes, dummy)

          table.insert(dummies, dummy)
        end

        table.insert(dummies, 1, neighbour)
        table.insert(dummies, #dummies+1, node)

        for i = 2, #dummies do
          local source = dummies[i-1]
          local target = dummies[i]

          local dummy_edge = Edge:new{direction = Edge.RIGHT, reversed = false}

          dummy_edge:addNode(source)
          dummy_edge:addNode(target)

          self.graph:addEdge(dummy_edge)
        end

        table.insert(original_edges, edge)
      end
    end
  end

  for edge in table.value_iter(original_edges) do
    self.graph:deleteEdge(edge)
  end

  dump_graph(self.graph, 'GRAPH WITH DUMMY NODES')

  return original_edges, dummy_nodes
end



function PohlmannLayered:removeDummyNodes(layers, original_edges, dummy_nodes)
  -- delete dummy nodes
  for node in table.value_iter(dummy_nodes) do
    self.graph:deleteNode(node)
  end

  -- add original edge again
  for edge in table.value_iter(original_edges) do
    -- add edge to the graph
    self.graph:addEdge(edge)

    -- add edge to the nodes
    for node in table.value_iter(edge.nodes) do
      node:addEdge(edge)
    end

    -- convert bend nodes to bend points for TikZ
    for bend_node in table.value_iter(edge.bend_nodes) do
      local point = Vector:new(bend_node.pos.elements)
      table.insert(edge.bend_points, point)
    end

    if edge.reversed then
      edge.bend_points = table.reverse_values(edge.bend_points, edge.bend_points)
    end

    -- clear the list of bend nodes
    edge.bend_nodes = {}
  end

  dump_graph(self.graph, 'FINAL GRAPH')
end



function PohlmannLayered:reduceEdgeCrossings(layers)
  local x = 0
  for sink in table.value_iter(layers[1]) do
    sink.pos:set{x = x}
    x = x + 2
  end

  dump_coordinates(layers, 'COORDINATES AFTER PLACING SINKS')

  for n = 2, #layers do 
    local positions = {}

    for node in table.value_iter(layers[n]) do 
      local in_edges = node:getIncomingEdges()

      local sum_x = table.combine_values(in_edges, function (sum, edge)
        return sum + edge:getNeighbour(node).pos:x()
      end, 0)

      local avg_x = sum_x / #in_edges

      Sys:log('node ' .. node.name .. ' avg_x ' .. sum_x)

      while positions[avg_x] do
        Sys:log('  move to ' .. avg_x .. ' instead')
        avg_x = avg_x + 1 / #layers[n-1]
      end

      node.pos:set{x = avg_x}
      positions[node.pos:x()] = true
    end
  end

  dump_coordinates(layers, 'COORDINATES AFTER LAYER SWEEP')
end



function PohlmannLayered:assignCoordinates(layers)
  -- assign y coordinates
  for node in table.value_iter(self.graph.nodes) do
    node.pos:set{y = - (node.pos:y()-1) * self.level_distance}
  end

  -- assign x coordinates
  local x = 0
  for node in table.value_iter(self.graph.nodes) do
    node.pos:set{x = node.pos:x() * self.sibling_distance}
    --node.pos:set{x = x * self.sibling_distance}
    --x = x + 1
  end
end



function PohlmannLayered:makeSplines()
end



function dump_graph(graph, name)
  Sys:log(name .. ':')
  for node in table.value_iter(graph.nodes) do
    Sys:log('  node ' .. node.name .. ' layer ' .. node.pos:y())
  end
  for edge in table.value_iter(graph.edges) do
    Sys:log('  edge ' .. edge.nodes[1].name .. ' ' .. edge.direction .. ' ' .. edge.nodes[2].name)
  end
end



function dump_coordinates(layers, name)
  Sys:log(name .. ':')
  for n = 1, #layers do 
    for node in table.value_iter(layers[n]) do
      Sys:log('  node ' .. node.name .. ' layer ' .. node.pos:y() .. ' at ' .. tostring(node.pos))
    end
  end
end
