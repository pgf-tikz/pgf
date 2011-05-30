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

  -- fall back to Hu2006 spring electrical for now, just to see the effects
  -- of the preprocessing steps
  require('../force/pgfgd-algorithm-Hu2006-spring-electrical.lua')
  graph:setOption('/graph drawing/spring electrical layout/iterations', 500)
  graph:setOption('/graph drawing/spring electrical layout/cooling factor', 0.95)
  graph:setOption('/graph drawing/spring electrical layout/random seed', 42)
  graph:setOption('/graph drawing/spring electrical layout/initial step dimension', 28.5)
  graph:setOption('/graph drawing/spring electrical layout/convergence tolerance', 0.01)
  graph:setOption('/graph drawing/spring electrical layout/spring constant', 0.2)
  graph:setOption('/graph drawing/spring electrical layout/natural spring dimension', 28.5)
  graph:setOption('/graph drawing/spring electrical layout/coarsen', true)
  graph:setOption('/graph drawing/spring electrical layout/coarsening/downsize ratio', 0.25)
  graph:setOption('/graph drawing/spring electrical layout/coarsening/minimum graph size', 2)
  graph:setOption('/graph drawing/spring electrical layout/coarsening/collapse independent edges', true)
  drawGraphAlgorithm_Hu2006_spring_electrical(graph)

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

  self:rankNodes()
  self:reduceEdgeCrossings()
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

  local tree = self:constructFeasibleTree(self.graph)
  Sys:log(' ')
  dump_tree (tree, 'feasible tree')
  Sys:log(' ')
end



function GansnerKNVLayered:constructFeasibleTree(graph)
  local tree = Graph:new()
  local rank = {}

  return tree
end



function GansnerKNVLayered:reduceEdgeCrossings()
end



function GansnerKNVLayered:computeCoordinates()
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
