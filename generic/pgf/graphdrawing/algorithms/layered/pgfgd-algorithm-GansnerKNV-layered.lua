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



GansnerKNVLayered = {}
GansnerKNVLayered.__index = GansnerKNVLayered



--- Implementation of a layered drawing algorithm for directed graphs.
-- 
-- This implementation is based on the paper 
--
--   "A Technique for Drawing Directed Graphs"
--   Gansner, Koutsofios, North, Vo, 1993
--
-- Modifications compared to the original algorithm are explained in the manual.
--
function drawGraphAlgorithm_GansnerKNV_layered(graph)
  local algorithm = GansnerKNVLayered:new(graph)

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



function GansnerKNVLayered:new(graph)
  local algorithm = {
    level_distance = tonumber(graph:getOption('/graph drawing/layered drawing/level distance')),
    sibling_distance = tonumber(graph:getOption('/graph drawing/layered drawing/sibling distance')),

    graph = graph,
  }
  setmetatable(algorithm, GansnerKNVLayered)

  -- validate input parameters

  return algorithm
end



function GansnerKNVLayered:initialize()
  -- initialize edge parameters
  for edge in table.value_iter(self.graph.edges) do
    edge.weight = tonumber(edge:getOption('/graph drawing/layered drawing/weight'))
    edge.minimum_levels = tonumber(edge:getOption('/graph drawing/layered drawing/minimum levels'))
  end
end



function GansnerKNVLayered:run()
  self:preprocess()

  local ranks = self:rankNodes()
  self:reduceEdgeCrossings(ranks)
  self:computeCoordinates()
  self:makeSplines()

  self:postprocess()
end



function GansnerKNVLayered:preprocess()
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



function GansnerKNVLayered:postprocess()
end



function GansnerKNVLayered:rankNodes()
  -- ignore self-loops
  local tree, ranks = self:constructFeasibleTree(self.graph)

  return ranks
end



function GansnerKNVLayered:constructFeasibleTree(graph)
  local tree = Graph:new()
  local ranks = self:computeInitialRanking(graph)



  return tree, ranks
end



function GansnerKNVLayered:computeInitialRanking(graph)
  -- queue for nodes to rank next
  local queue = {}

  -- two-dimensional mapping from ranks to lists of corresponding nodes
  local ranks = {}

  -- number mapping that counts the number of ranked incoming 
  -- neighbours of each node
  local ranked_neighbours = {}

  -- convenience functions for managing the queue
  function enqueue(node) table.insert(queue, node) end
  function dequeue() return table.remove(queue, 1) end

  -- function to move unranked nodes to the queue if they have no
  -- unscanned incoming edges
  function update_queue(node)
    -- check all nodes yet to be ranked
    for edge in table.value_iter(node:getOutgoingEdges()) do
      local neighbour = edge:getNeighbour(node)

      -- increment the number of ranked incoming neighbours of the neighbour node
      ranked_neighbours[neighbour] = (ranked_neighbours[neighbour] or 0) + 1

      -- check whether all incoming edges have been scanned
      if ranked_neighbours[neighbour] >= neighbour:getInDegree() then
        -- we have no unscanned incoming edges, queue the node now
        enqueue(neighbour)
      end
    end
  end

  -- invalidate the ranks of all nodes
  for node in table.value_iter(graph.nodes) do
    node.rank = -1
  end

  -- add all sinks to the queue
  for node in table.value_iter(graph.nodes) do
    if node:getInDegree() == 0 then
      enqueue(node)
      ranked_neighbours[node] = 0
    end
  end

  -- run long as there are nodes to be ranked
  while #queue > 0 do
    -- fetch the next unranked node from the queue
    local node = dequeue()
    -- get a list of its incoming edges
    local in_edges = node:getIncomingEdges()

    -- determine the minimum possible rank for the node
    local rank = table.combine_values(in_edges, function (rank, edge)
      local neighbour = edge:getNeighbour(node)
      if neighbour.rank then
        -- the minimum possible rank is the maximum of all neighbour ranks plus
        -- the corresponding edge lengths
        rank = math.max(rank, neighbour.rank + edge.minimum_levels)
      end
      return rank
    end, 0)

    -- rank the node
    node.rank = rank

    -- add the node to the two-dimensional rank mapping
    ranks[node.rank] = ranks[node.rank] or {}
    table.insert(ranks[node.rank], node)

    -- queue neighbours of nodes for which all incoming edges have
    -- been scanned
    --
    -- note that we don't need to mark the node's outgoing edges 
    -- as scanned prior to this, because this is equivalent to checking
    -- whether the node has already been ranked or not
    update_queue(node)
  end

  -- return the two-dimensional rank mapping
  return ranks
end



function GansnerKNVLayered:reduceEdgeCrossings()
end



function GansnerKNVLayered:computeCoordinates()
  -- TODO this is a temporary algorithm used for debugging
  
  local rank_x = {}

  for node in table.value_iter(self.graph.nodes) do
    if rank_x[node.rank] then
      rank_x[node.rank] = rank_x[node.rank] + 1
    else
      rank_x[node.rank] = 0
    end

    node.pos:set{
      x = rank_x[node.rank] * self.sibling_distance,
      y = - node.rank * self.level_distance,
    }
  end
end



function GansnerKNVLayered:makeSplines()
end



function dump_tree(tree, name)
  Sys:log(name .. ':')
  for node in table.value_iter(tree.nodes) do
    Sys:log('  node ' .. node.name)
  end
  for edge in table.value_iter(tree.edges) do
    Sys:log('  edge ' .. edge.nodes[1] .. ' ' .. edge.direction .. ' ' .. edge.nodes[2])
  end
end
