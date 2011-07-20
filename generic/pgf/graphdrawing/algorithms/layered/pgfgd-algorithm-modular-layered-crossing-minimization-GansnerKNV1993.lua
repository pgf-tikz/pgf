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



CrossingMinimizationGansnerKNV1993 = {}
CrossingMinimizationGansnerKNV1993.__index = CrossingMinimizationGansnerKNV1993



function CrossingMinimizationGansnerKNV1993:new(graph, ranking)
  local algorithm = {
    graph = graph,
    ranking = ranking,
  }
  setmetatable(algorithm, CrossingMinimizationGansnerKNV1993)
  return algorithm
end



function CrossingMinimizationGansnerKNV1993:run()
  --self:dumpRanking('  ', 'ranking before reducing edge crossings')

  self:computeInitialRankOrdering()

  local best_ranking = self.ranking:copy()
  local best_crossings = self:countRankCrossings(best_ranking)

  for iteration in iter.times(24) do
    local direction = (iteration % 2 == 0) and 'down' or 'up'

    --Sys:log('reduce edge crossings, iteration ' .. iteration .. ', sweep direction ' .. direction)

    self:orderByWeightedMedian(direction)
    self:transpose(direction)

    local current_crossings = self:countRankCrossings(self.ranking)

    --Sys:log('  crossings of best ranking: ' .. best_crossings)
    --Sys:log('  crossings of current ranking: ' .. current_crossings)

    if current_crossings < best_crossings then
      --Sys:log('  adapt current ranking')
      best_ranking = self.ranking:copy()
      best_crossings = current_crossings
    end
  end

  self.ranking = best_ranking:copy()

  --self:dumpRanking('  ', 'ranking after reducing edge crossings')

  return self.ranking
end



function CrossingMinimizationGansnerKNV1993:computeInitialRankOrdering()
  --Sys:log('compute initial rank ordering:')

  local best_ranking = self.ranking:copy()
  local best_crossings = self:countRankCrossings(best_ranking)

  for direction in table.value_iter({'down', 'up'}) do
    --Sys:log('  direction = ' .. direction)

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

      --Sys:log('  visit ' .. node.name)

      --Sys:log('    append to rank ' .. self.ranking:getRank(node))
      --Sys:log('      at pos ' .. self.ranking:getRankSize(self.ranking:getRank(node)))

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

    --Sys:log('     crossings of best ranking: ' .. best_crossings)
    --Sys:log('  crossings of current ranking: ' .. crossings)

    if crossings < best_crossings then
      best_ranking = self.ranking:copy()
      best_crossings = crossings
    end
  end

  self.ranking = best_ranking:copy()

  --self:dumpRanking('  ', 'ranking after initial ordering')
end



function CrossingMinimizationGansnerKNV1993:countRankCrossings(ranking)
  --Sys:log('  count ranking crossings:')

  local crossings = 0

  local ranks = ranking:getRanks()
  
  for rank_index = 2, #ranks do
    local nodes = ranking:getNodes(ranks[rank_index])
    for i = 1, #nodes-1 do
      for j = i+1, #nodes do
        local v = nodes[i]
        local w = nodes[j]

        -- TODO Jannis: We are REQUIRED to only check edges that lead to nodes
        -- on the next or previous rank, depending on the sweep direction!!!!
        local cn_vw = self:countNodeCrossings(ranking, v, w, 'down')

        crossings = crossings + cn_vw
      end
    end
  end

  return crossings
end



function CrossingMinimizationGansnerKNV1993:countNodeCrossings(ranking, left_node, right_node, sweep_direction)
  --Sys:log('        count crossings of (' .. left_node.name .. ', ' .. right_node.name .. ') (sweep direction ' .. sweep_direction .. ')')

  local ranks = ranking:getRanks()
  local rank_index = table.find_index(ranks, function (rank)
    return rank == ranking:getRank(left_node)
  end)
  local other_rank_index = (sweep_direction == 'down') and rank_index-1 or rank_index+1

  assert(ranking:getRank(left_node) == ranking:getRank(right_node))
  assert(rank_index >= 1 and rank_index <= #ranks)

  -- 0 crossings if we're at the top or bottom and are sweeping down or up
  if other_rank_index < 1 or other_rank_index > #ranks then
    return 0
  end

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

  local function left_neighbour_on_other_rank(edge)
    local neighbour = edge:getNeighbour(left_node)
    return ranking:getRank(neighbour) == ranking:getRanks()[other_rank_index]
  end

  local function right_neighbour_on_other_rank(edge)
    local neighbour = edge:getNeighbour(right_node)
    return ranking:getRank(neighbour) == ranking:getRanks()[other_rank_index]
  end

  for left_edge in iter.filter(table.value_iter(left_edges), left_neighbour_on_other_rank) do
    local left_neighbour = left_edge:getNeighbour(left_node)

    for right_edge in iter.filter(table.value_iter(right_edges), right_neighbour_on_other_rank) do
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



function CrossingMinimizationGansnerKNV1993:orderByWeightedMedian(direction)
  --Sys:log('  order by weighted median (' .. direction .. ')')

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

  --self:dumpRanking('    ', 'ranks before applying the median')

  if direction == 'down' then
    local ranks = self.ranking:getRanks()

    for rank_index = 2, #ranks do
      --Sys:log('    medians for rank ' .. ranks[rank_index] .. ':')
      median = {}
      local nodes = self.ranking:getNodes(ranks[rank_index])
      for node in table.value_iter(nodes) do
        median[node] = self:computeMedianPosition(node, ranks[rank_index-1])
        --Sys:log('      ' .. node.name .. ': ' .. median[node])
      end

      self.ranking:reorderRank(ranks[rank_index], get_index, is_fixed)
    end
  else
    local ranks = self.ranking:getRanks()

    for rank_index = 1, #ranks-1 do
      --Sys:log('    medians for rank ' .. ranks[rank_index] .. ':')
      median = {}
      local nodes = self.ranking:getNodes(ranks[rank_index])
      for node in table.value_iter(nodes) do
        median[node] = self:computeMedianPosition(node, ranks[rank_index+1])
        --Sys:log('      ' .. node.name .. ': ' .. median[node])
      end

      self.ranking:reorderRank(ranks[rank_index], get_index, is_fixed)
    end
  end

  --self:dumpRanking('    ', 'ranks after applying the median')
end



function CrossingMinimizationGansnerKNV1993:computeMedianPosition(node, prev_rank)
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



function CrossingMinimizationGansnerKNV1993:transpose(sweep_direction)
  --Sys:log('  transpose (sweep direction ' .. sweep_direction .. ')')

  local function transpose_rank(rank)
    --Sys:log('    transpose rank ' .. rank)

    local improved = false

    local nodes = self.ranking:getNodes(rank)

    for i = 1, #nodes-1 do
      local v = nodes[i]
      local w = nodes[i+1]

      local cn_vw = self:countNodeCrossings(self.ranking, v, w, sweep_direction)
      local cn_wv = self:countNodeCrossings(self.ranking, w, v, sweep_direction)

      --Sys:log('      crossings if ' .. v.name .. ' is left of ' .. w.name .. ': ' .. cn_vw)
      --Sys:log('      crossings if ' .. w.name .. ' is left of ' .. v.name .. ': ' .. cn_wv)

      if cn_vw > cn_wv then
        improved = true

        --Sys:log('        switch so that ' .. w.name .. ' is left of ' .. v.name)

        self:switchNodePositions(v, w)

        --self:dumpRanking('    ', 'ranks after switching positions')
      end
    end

    return improved
  end

  local ranks = self.ranking:getRanks()

  local improved = false
  repeat
    local improved = false

    --Sys:log('sweep ' .. sweep_direction)

    if sweep_direction == 'down' then
      for rank_index = 1, #ranks-1 do
        improved = transpose_rank(ranks[rank_index]) or improved
      end
    else
      for rank_index = #ranks-1, 1, -1 do
        improved = transpose_rank(ranks[rank_index]) or improved
      end
    end
  until not improved
end



function CrossingMinimizationGansnerKNV1993:switchNodePositions(left_node, right_node)
  --Sys:log('          switch positions of ' .. left_node.name .. ' and ' .. right_node.name)

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



function CrossingMinimizationGansnerKNV1993:dumpRanking(prefix, title)
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
