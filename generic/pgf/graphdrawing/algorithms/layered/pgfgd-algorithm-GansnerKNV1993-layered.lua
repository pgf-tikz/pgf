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



GansnerKNV1993Layered = {}
GansnerKNV1993Layered.__index = GansnerKNV1993Layered



--- Implementation of a layered layout algorithm for directed graphs.
-- 
-- This implementation is based on the paper 
--
--   "A Technique for Drawing Directed Graphs"
--   Gansner, Koutsofios, North, Vo, 1993
--
-- and the reference code in Graphviz/dot (http://www.graphviz.org).
--
-- Modifications compared to the original algorithm are explained in the manual.
--
function graph_drawing_algorithm_GansnerKNV1993_layered(graph)
  local algorithm = GansnerKNV1993Layered:new(graph)

  algorithm:initialize()
  algorithm:run()
end



function GansnerKNV1993Layered:new(graph)
  local algorithm = {
    -- read graph input parameters
    level_distance = tonumber(graph:getOption('/graph drawing/level distance')),
    sibling_distance = tonumber(graph:getOption('/graph drawing/sibling distance')),

    -- remember the graph for use in the algorithm
    graph = graph,
  }
  setmetatable(algorithm, GansnerKNV1993Layered)

  -- validate input parameters
  assert(algorithm.level_distance >= 0, 'the level distance needs to be greater than or equal to 0')
  assert(algorithm.sibling_distance >= 0, 'the sibling distance needs to be greater than or equal to 0')

  return algorithm
end



function GansnerKNV1993Layered:initialize()
  -- initialize edge parameters
  for edge in table.value_iter(self.graph.edges) do
    -- read edge parameters
    edge.weight = tonumber(edge:getOption('/graph drawing/layered layout/weight'))
    edge.minimum_levels = tonumber(edge:getOption('/graph drawing/layered layout/minimum levels'))

    -- validate edge parameters
    assert(edge.minimum_levels >= 0, 'the edge ' .. tostring(edge) .. ' needs to have a minimum levels value greater than or equal to 0')
  end
end



function GansnerKNV1993Layered:run()
  self:preprocess()

  -- rank nodes, that is, assign a layer to each node
  self:rankNodes()

  -- insert dummy (or "virtual") nodes for intermediate ranks on
  -- edges that have a length greater than 1
  self:insertDummyNodes()

  -- reduce edge crossings by ordering vertices at each rank in a smart way
  self:reduceEdgeCrossings()

  -- compute the final x and y coordinates (the former using the 
  -- network simplex algorithm)
  self:computeCoordinates()

  -- remove the dummy (or "virtual") nodes to restore the original graph
  self:removeDummyNodes()

  -- route edges so that they look good
  self:makeSplines()

  self:postprocess()
end



function GansnerKNV1993Layered:preprocess()
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
  
  -- classify edges as tree/forward, cross and back edges using a DFS traversal
  local tree_or_forward_edges, cross_edges, back_edges = algorithms.classify_edges(self.graph)

  -- reverse the back edges in order to make the graph acyclic
  for edge in table.value_iter(back_edges) do
    Sys:log('reverse back edge ' .. tostring(edge))
    edge.reversed = true
  end
end



function GansnerKNV1993Layered:postprocess()
  -- restore all reversed back edges so that, in the final graph, all
  -- edges appear with the direction specified by the user
  for edge in table.value_iter(self.graph.edges) do
    edge.reversed = false
  end
end



function GansnerKNV1993Layered:rankNodes()
  local simplex = NetworkSimplex:new(self.graph, NetworkSimplex.BALANCE_TOP_BOTTOM)
  simplex:run()
  self.ranking = simplex.ranking
end



function GansnerKNV1993Layered:reduceEdgeCrossings()
  self:dumpRanking('', 'ranking after creating dummy nodes')

  self:computeInitialRankOrdering()

  local best_ranking = self.ranking:copy()
  local best_crossings = self:countRankCrossings(best_ranking)

  for iteration in iter.times(24) do
    local direction = (iteration % 2 == 0) and 'down' or 'up'

    Sys:log('reduce edge crossings, iteration ' .. iteration .. ', sweep direction ' .. direction)

    self:orderByWeightedMedian(direction)
    self:transpose(direction)

    local current_crossings = self:countRankCrossings(self.ranking)

    Sys:log('  crossings of best ranking: ' .. best_crossings)
    Sys:log('  crossings of current ranking: ' .. current_crossings)

    if current_crossings < best_crossings then
      Sys:log('  adapt current ranking')
      best_ranking = self.ranking:copy()
      best_crossings = current_crossings
    end
  end

  self.ranking = best_ranking:copy()

  self:dumpRanking('  ', 'ranking after reducing edge crossings')
end



function GansnerKNV1993Layered:computeInitialRankOrdering()
  Sys:log('compute initial rank ordering:')

  local best_ranking = self.ranking:copy()
  local best_crossings = self:countRankCrossings(best_ranking)

  for direction in table.value_iter({'down', 'up'}) do
    Sys:log('  direction = ' .. direction)

    local function init(search)
      for node in table.reverse_value_iter(self.graph.nodes) do
        if direction == 'down' then
          if node:getInDegree() == 0 then
            search:push(node)
            search:setDiscovered(node)
          end
        else
          if node:getOutDegree() == 0 then
            search:push(node)
            search:setDiscovered(node)
          end
        end
      end
    end

    local function visit(search, node)
      search:setVisited(node, true)

      Sys:log('  visit ' .. node.name)

      Sys:log('    append to rank ' .. self.ranking:getRank(node))
      Sys:log('      at pos ' .. self.ranking:getRankSize(self.ranking:getRank(node)))

      local rank = self.ranking:getRank(node)
      local pos = self.ranking:getRankSize(rank)
      self.ranking:setRankPosition(node, pos)

      if direction == 'down' then
        for edge in table.reverse_value_iter(node:getOutgoingEdges()) do
          local neighbour = edge:getNeighbour(node)
          if not search:getDiscovered(neighbour) then
            search:push(neighbour)
            search:setDiscovered(neighbour)
          end
        end
      else
        for edge in table.reverse_value_iter(node:getIncomingEdges()) do
          local neighbour = edge:getNeighbour(node)
          if not search:getDiscovered(neighbour) then
            search:push(neighbour)
            search:setDiscovered(neighbour)
          end
        end
      end
    end

    DepthFirstSearch:new(init, visit):run()

    local crossings = self:countRankCrossings(self.ranking)

    Sys:log('     crossings of best ranking: ' .. best_crossings)
    Sys:log('  crossings of current ranking: ' .. crossings)

    if crossings < best_crossings then
      best_ranking = self.ranking:copy()
      best_crossings = crossings
    end
  end

  self.ranking = best_ranking:copy()

  self:dumpRanking('  ', 'ranking after initial ordering')
end



function GansnerKNV1993Layered:orderByWeightedMedian(direction)
  Sys:log('  order by weighted median (' .. direction .. ')')

  local median = {}

  local function dump_rank_ordering(rank)
    local nodes = self.ranking:getNodes(rank)
  end

  local function get_index(n, node) return median[node] end
  local function is_fixed(n, node) return median[node] < 0 end

  --local function sync_positions(nodes)
  --  for n = 1, #nodes do
  --    self.ranking.position_in_rank[nodes[n]] = n
  --  end
  --end

  self:dumpRanking('    ', 'ranks before applying the median')

  if direction == 'down' then
    local ranks = self.ranking:getRanks()

    for rank_index = 2, #ranks do
      Sys:log('    medians for rank ' .. ranks[rank_index] .. ':')
      median = {}
      local nodes = self.ranking:getNodes(ranks[rank_index])
      for node in table.value_iter(nodes) do
        median[node] = self:computeMedianPosition(node, ranks[rank_index-1])
        Sys:log('      ' .. node.name .. ': ' .. median[node])
      end

      self.ranking:reorderRank(ranks[rank_index], get_index, is_fixed)
    end
  else
    local ranks = self.ranking:getRanks()

    for rank_index = 1, #ranks-1 do
      Sys:log('    medians for rank ' .. ranks[rank_index] .. ':')
      median = {}
      local nodes = self.ranking:getNodes(ranks[rank_index])
      for node in table.value_iter(nodes) do
        median[node] = self:computeMedianPosition(node, ranks[rank_index+1])
        Sys:log('      ' .. node.name .. ': ' .. median[node])
      end

      self.ranking:reorderRank(ranks[rank_index], get_index, is_fixed)
    end
  end

  self:dumpRanking('    ', 'ranks after applying the median')
end



function GansnerKNV1993Layered:computeMedianPosition(node, prev_rank)
  --Sys:log('  compute median position of ' .. node.name .. ' (prev_rank = ' .. prev_rank .. '):')

  local in_edges = table.filter_values(node.edges, function (edge)
    local neighbour = edge:getNeighbour(node)
    return self.ranking:getRank(neighbour) == prev_rank
  end)

  local positions = table.map_values(in_edges, function (edge)
    local neighbour = edge:getNeighbour(node)
    return self.ranking:getRankPosition(neighbour)
  end)

  table.sort(positions)

  --Sys:log('    positions = ' .. table.concat(positions, ', '))

  local median = math.ceil(#positions / 2)

  --Sys:log('    median = ' .. median)

  local position = -1

  if #positions > 0 then
    if #positions % 2 == 1 then
      position = positions[median]
    elseif #positions == 2 then
      return (positions[1] + positions[2]) / 2
    else
      local left = positions[median-1] - positions[1]
      local right = positions[#positions] - positions[median]
      --Sys:log('    left = ' .. left .. ', right = ' .. right)
      position = (positions[median-1] * right + positions[median] * left) / (left + right)
    end
  end

  --Sys:log('    position = ' .. position)

  return position
end



function GansnerKNV1993Layered:transpose(sweep_direction)
  Sys:log('  transpose (sweep direction ' .. sweep_direction .. ')')

  local function transpose_rank(rank)
    Sys:log('    transpose rank ' .. rank)

    local improved = false

    local nodes = self.ranking:getNodes(rank)

    for i = 1, #nodes-1 do
      local v = nodes[i]
      local w = nodes[i+1]

      local cn_vw = self:countNodeCrossings(self.ranking, v, w, sweep_direction)
      local cn_wv = self:countNodeCrossings(self.ranking, w, v, sweep_direction)

      Sys:log('      crossings if ' .. v.name .. ' is left of ' .. w.name .. ': ' .. cn_vw)
      Sys:log('      crossings if ' .. w.name .. ' is left of ' .. v.name .. ': ' .. cn_wv)

      if cn_vw > cn_wv then
        improved = true

        Sys:log('        switch so that ' .. w.name .. ' is left of ' .. v.name)

        self:switchNodePositions(v, w)

        self:dumpRanking('    ', 'ranks after switching positions')
      end
    end

    return improved
  end

  local ranks = self.ranking:getRanks()

  local improved = false
  repeat
    if sweep_direction == 'down' then
      for rank_index = 1, #ranks-1 do
        improved = transpose_rank(ranks[rank_index])
      end
    else
      for rank_index = #ranks-1, 1, -1 do
        improved = transpose_rank(ranks[rank_index])
      end
    end
  until not improved
end



function GansnerKNV1993Layered:countNodeCrossings(ranking, left_node, right_node, sweep_direction)
  --Sys:log('        count crossings of (' .. left_node.name .. ', ' .. right_node.name .. ') (sweep direction ' .. sweep_direction .. ')')

  local left_edges = {}
  local right_edges = {}

  if sweep_direction == 'down' then
    left_edges = left_node:getIncomingEdges()
    right_edges = right_node:getIncomingEdges()
  else
    left_edges = left_node:getOutgoingEdges()
    right_edges = right_node:getOutgoingEdges()
  end
  
  local crossings = 0

  for left_edge in table.value_iter(left_edges) do
    local left_neighbour = left_edge:getNeighbour(left_node)

    for right_edge in table.value_iter(right_edges) do
      local right_neighbour = right_edge:getNeighbour(right_node)

      local left_position = ranking:getRankPosition(left_neighbour)
      local right_position = ranking:getRankPosition(right_neighbour)

      --Sys:log('          check crossing with (' .. left_neighbour.name .. ' at ' .. left_position .. ', ' .. right_neighbour.name .. ' at ' .. right_position .. ')')

      local neighbour_diff = right_position - left_position

      if neighbour_diff < 0 then
        --Sys:log('            edges cross, crossings += 1')
        crossings = crossings + 1
      end
    end
  end

  --Sys:log('    ' .. crossings .. ' crossings')

  return crossings
end



function GansnerKNV1993Layered:switchNodePositions(left_node, right_node)
  Sys:log('          switch positions of ' .. left_node.name .. ' and ' .. right_node.name)

  assert(self.ranking:getRank(left_node) == self.ranking:getRank(right_node))
  assert(self.ranking:getRankPosition(left_node) < self.ranking:getRankPosition(right_node))

  local left_position = self.ranking:getRankPosition(left_node)
  local right_position = self.ranking:getRankPosition(right_node)

  self.ranking:switchPositions(left_node, right_node)

  local nodes = self.ranking:getNodes(self.ranking:getRank(left_node))

  ---- verify that all nodes have valid rank positions after switching the two nodes
  --for n = 1, #nodes do
  --  assert(self.ranking:getRankPosition(nodes[n]) == n)
  --end
end



function GansnerKNV1993Layered:countRankCrossings(ranking)
  --Sys:log('  count ranking crossings:')

  local crossings = 0

  local ranks = ranking:getRanks()
  
  for rank_index = 2, #ranks do
    local nodes = ranking:getNodes(ranks[rank_index])
    for i = 1, #nodes-1 do
      for j = i+1, #nodes do
        local v = nodes[i]
        local w = nodes[j]

        local cn_vw = self:countNodeCrossings(ranking, v, w, 'down')

        crossings = crossings + cn_vw
      end
    end
  end

  return crossings
end



function GansnerKNV1993Layered:insertDummyNodes()
  -- enumerate dummy nodes using a globally unique numeric ID
  local dummy_id = 1

  -- keep track of the original edges removed
  self.original_edges = {}

  -- keep track of dummy nodes introduced
  self.dummy_nodes = {}

  for node in traversal.topological_sorting(self.graph) do
    local in_edges = node:getIncomingEdges()

    for edge in table.value_iter (in_edges) do
      local neighbour = edge:getNeighbour(node)
      local dist = self.ranking:getRank(node) - self.ranking:getRank(neighbour)

      if dist > 1 then
        local dummies = {}

        for i in iter.times(dist-1) do
          local rank = self.ranking:getRank(neighbour) + i

          local dummy = Node:new{
            pos = Vector:new({ 0, 0 }),
            name = 'dummy@' .. neighbour.name .. '@to@' .. node.name .. '@at@' .. rank,
            is_dummy = true,
          }
          
          dummy_id = dummy_id + 1

          self.graph:addNode(dummy)

          self.ranking:setRank(dummy, rank)

          table.insert(self.dummy_nodes, dummy)
          table.insert(edge.bend_nodes, dummy)

          table.insert(dummies, dummy)
        end

        table.insert(dummies, 1, neighbour)
        table.insert(dummies, #dummies+1, node)

        for i = 2, #dummies do
          local source = dummies[i-1]
          local target = dummies[i]

          local dummy_edge = Edge:new{
            direction = Edge.RIGHT, 
            reversed = false,
            weight = edge.weight, -- TODO or should we divide the weight of the original edge by the number of virtual edges?
          }

          dummy_edge:addNode(source)
          dummy_edge:addNode(target)

          self.graph:addEdge(dummy_edge)
        end

        table.insert(self.original_edges, edge)
      end
    end
  end

  for edge in table.value_iter(self.original_edges) do
    self.graph:deleteEdge(edge)
  end
end



function GansnerKNV1993Layered:removeDummyNodes()
  -- delete dummy nodes
  for node in table.value_iter(self.dummy_nodes) do
    self.graph:deleteNode(node)
  end

  -- add original edge again
  for edge in table.value_iter(self.original_edges) do
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
end



function GansnerKNV1993Layered:computeCoordinates()
  local auxiliary_graph = self:constructAuxiliaryGraph()

  local simplex = NetworkSimplex:new(auxiliary_graph, NetworkSimplex.BALANCE_LEFT_RIGHT)
  simplex:run()
  local x_ranking = simplex.ranking

  local ranks = self.ranking:getRanks()
  for rank in table.value_iter(ranks) do
    local x = 0
    local nodes = self.ranking:getNodes(rank)
    for node in table.value_iter(nodes) do
      Sys:log('position ' .. node.name .. ' at:')
      node.pos:set{
        x = x_ranking:getRank(node.aux_node),
        y = -rank * self.level_distance
      }
      Sys:log('  ' .. tostring(node.pos))
      x = x + 1
    end
  end
end



function GansnerKNV1993Layered:constructAuxiliaryGraph()
  local aux_graph = Graph:new()

  local edge_node = {}

  for node in table.value_iter(self.graph.nodes) do
    local copy = Node:new{
      name = node.name,
      orig_node = node,
    }
    node.aux_node = copy
    aux_graph:addNode(copy)
  end

  for edge in table.reverse_value_iter(self.graph.edges) do
    local node = Node:new{
      name = '{' .. tostring(edge) .. '}',
    }

    --table.insert(aux_graph.nodes, 1, node)
    aux_graph:addNode(node)

    node.orig_edge = edge
    edge_node[edge] = node

    local head = edge:getHead()
    local tail = edge:getTail()

    local tail_edge = Edge:new{
      direction = Edge.RIGHT,
      minimum_levels = 0,
      weight = edge.weight * self:getOmega(edge),
    }
    tail_edge:addNode(node)
    tail_edge:addNode(tail.aux_node)
    aux_graph:addEdge(tail_edge)

    local head_edge = Edge:new{
      direction = Edge.RIGHT,
      minimum_levels = 0,
      weight = edge.weight * self:getOmega(edge),
    }
    head_edge:addNode(node)
    head_edge:addNode(head.aux_node)
    aux_graph:addEdge(head_edge)
  end

  local ranks = self.ranking:getRanks()
  for rank in table.value_iter(ranks) do
    local nodes = self.ranking:getNodes(rank)
    for n = 1, #nodes-1 do
      local v = nodes[n]
      local w = nodes[n+1]

      local separator_edge = Edge:new{
        direction = Edge.RIGHT,
        minimum_levels = math.ceil(self:getDesiredHorizontalDistance(v, w)),
        weight = 0,
      }
      separator_edge:addNode(v.aux_node)
      separator_edge:addNode(w.aux_node)
      aux_graph:addEdge(separator_edge)
    end
  end

  return aux_graph
end



function GansnerKNV1993Layered:getOmega(edge)
  local node1 = edge.nodes[1]
  local node2 = edge.nodes[2]

  if node1.is_dummy and node2.is_dummy then
    return 8
  elseif node1.is_dummy or node2.is_dummy then
    return 2
  else
    return 1
  end
end



function GansnerKNV1993Layered:getDesiredHorizontalDistance(v, w)
  function xsize(node) 
    return node.is_dummy and 0 or node:getTexWidth() 
  end
  --return ((xsize(v) + xsize(w)) / 2) + self.sibling_distance
  return math.max(self.sibling_distance, ((xsize(v) + xsize(w)) / 2))
  --return self.sibling_distance
end



function GansnerKNV1993Layered:makeSplines()
end



function GansnerKNV1993Layered:dumpRanking(prefix, title)
  local ranks = self.ranking:getRanks()
  Sys:log(prefix .. title)
  for rank in table.value_iter(ranks) do
    local nodes = self.ranking:getNodes(rank)
    local str = prefix .. '  rank ' .. rank .. ':'
    local str = table.combine_values(nodes, function (str, node)
      return str .. ' ' .. node.name .. ' (' .. self.ranking:getRankPosition(node) .. ')'
    end, str)
    Sys:log(str)
  end
end



