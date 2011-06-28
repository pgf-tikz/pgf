-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file contains a helper class for managing node rankings as used
--- in layered drawing algorithms.

pgf.module("pgf.graphdrawing")



Ranking = {}
Ranking.__index = Ranking



function Ranking:new()
  local ranking = {
    rank_to_nodes = {},
    node_to_rank = {},
    position_in_rank = {},
  }
  setmetatable(ranking, Ranking)
  return ranking
end



function Ranking:copy()
  local copied_ranking = Ranking:new()
  
  -- copy rank to nodes mapping
  for rank, nodes in pairs(self.rank_to_nodes) do
    copied_ranking.rank_to_nodes[rank] = table.custom_copy(self.rank_to_nodes[rank])
  end

  -- copy node to rank mapping
  copied_ranking.node_to_rank = table.custom_copy(self.node_to_rank)

  -- copy node to position in rank mapping
  copied_ranking.position_in_rank = table.custom_copy(self.position_in_rank)

  return copied_ranking
end



function Ranking:reset()
  self.rank_to_nodes = {}
  self.node_to_rank = {}
  self.position_in_rank = {}
end



function Ranking:getRanks()
  return self.rank_to_nodes
end



function Ranking:getRankSize(rank)
  if self.rank_to_nodes[rank] then
    return #self.rank_to_nodes[rank]
  else
    return 0
  end
end



function Ranking:getNodeInfo(node)
  return self:getRank(node), self:getRankPosition(node)
end



function Ranking:getNodes(rank)
  return self.rank_to_nodes[rank]
end



function Ranking:getRank(node)
  return self.node_to_rank[node]
end



function Ranking:setRank(node, new_rank)
  assert(node.__index == Node)
  assert(type(new_rank) == type(0))

  local rank, pos = self:getNodeInfo(node)

  if rank == new_rank then
    return
  end
  
  if rank then
    for n = pos+1, #self.rank_to_nodes[rank] do
      local other_node = self.rank_to_nodes[rank][n]
      self.position_in_rank[other_node] = self.position_in_rank[other_node]-1
    end

    table.remove(self.rank_to_nodes[rank], pos)
    self.node_to_rank[node] = nil
    self.position_in_rank[node] = nil
  end

  if new_rank then
    self.rank_to_nodes[new_rank] = self.rank_to_nodes[new_rank] or {}
    table.insert(self.rank_to_nodes[new_rank], node)
    self.node_to_rank[node] = new_rank
    self.position_in_rank[node] = #self.rank_to_nodes[new_rank]
  end
end



function Ranking:getRankPosition(node)
  return self.position_in_rank[node]
end



function Ranking:setRankPosition(node, new_pos)
  local rank, pos = self:getNodeInfo(node)

  assert((rank and pos) or ((not rank) and (not pos)))

  if pos == new_pos then
    return
  end

  if rank and pos then
    for n = pos+1, #self.rank_to_nodes[rank] do
      local other_node = self.rank_to_nodes[rank][n]
      self.position_in_rank[other_node] = self.position_in_rank[other_node]-1
    end

    table.remove(self.rank_to_nodes[rank], pos)
    self.node_to_rank[node] = nil
    self.position_in_rank[node] = nil
  end

  if new_pos then
    self.rank_to_nodes[rank] = self.rank_to_nodes[rank] or {}

    for n = new_pos+1, #self.rank_to_nodes[rank] do
      local other_node = self.rank_to_nodes[rank][new_pos]
      self.position_in_rank[other_node] = self.position_in_rank[other_node]+1
    end

    table.insert(self.rank_to_nodes[rank], node)
    self.node_to_rank[node] = rank
    self.position_in_rank[node] = new_pos
  end
end



function Ranking:normalizeRanks()
  Sys:log('ranking: normalize ranks')

  -- get the minimum and maximum rank
  local min_rank, max_rank = self:getRankRange()

  Sys:log('  min_rank = ' .. min_rank .. ', max_rank = ' .. max_rank)

  -- reset rank sets
  self.rank_to_nodes = {}

  -- iterate over all nodes and rerank them manually
  for node in table.key_iter(self.position_in_rank) do
    local rank, pos = self:getNodeInfo(node)
    local new_rank = rank - (min_rank - 1)

    Sys:log('  rank_to_nodes[' .. new_rank .. '][' .. pos .. '] = ' .. node.name)

    self.rank_to_nodes[new_rank] = self.rank_to_nodes[new_rank] or {}
    self.rank_to_nodes[new_rank][pos] = node

    self.node_to_rank[node] = new_rank
  end

  -- drop all empty ranks (assuming that no empty intermediate ranks exist)
  table.remove_pairs(self.rank_to_nodes, function (rank, nodes)
    return #nodes == 0
  end)
end



function Ranking:getRankRange()
  -- initialize the minimum and maximum rank with unrealistic values
  local min_rank = math.huge
  local max_rank = -math.huge

  -- iterate over all ranks in the graph to find the min/max non-empty rank
  for rank, nodes in pairs(self.rank_to_nodes) do
    if #nodes > 0 then
      min_rank = math.min(min_rank, rank)
      max_rank = math.max(max_rank, rank)
    end
  end

  return min_rank, max_rank
end



function Ranking:getNumberOfRanks()
  local min_rank, max_rank = self:getRankRange()
  return max_rank - min_rank + 1
end
