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



ModularLayered = {}
ModularLayered.__index = ModularLayered



function drawGraphAlgorithm_modular_layered(graph)
  ModularLayered:new(graph):run()
  orientation.adjust(graph)
end



function ModularLayered:new(graph)
  local algorithm = {
    -- read graph input parameters
    level_distance = tonumber(graph:getOption('/graph drawing/layered drawing/level distance')),
    sibling_distance = tonumber(graph:getOption('/graph drawing/layered drawing/sibling distance')),

    -- read sub-algorithm parameters
    cycle_removal_algorithm = tostring(graph:getOption('/graph drawing/layered drawing/cycle removal')),
    node_ranking_algorithm = tostring(graph:getOption('/graph drawing/layered drawing/node ranking')),
    crossing_minimization_algorithm = tostring(graph:getOption('/graph drawing/layered drawing/crossing minimization')),
    node_positioning_algorithm = tostring(graph:getOption('/graph drawing/layered drawing/node positioning')),
    edge_routing_algorithm = tostring(graph:getOption('/graph drawing/layered drawing/edge routing')),

    -- remember the graph for use in the algorithm
    graph = graph,
  }
  setmetatable(algorithm, ModularLayered)
  
  -- validate input parameters
  assert(algorithm.level_distance >= 0, 'the level distance needs to be greater than or equal to 0')
  assert(algorithm.sibling_distance >= 0, 'the sibling distance needs to be greater than or equal to 0')

  return algorithm
end



function ModularLayered:run()
  self:preprocess()

  self:removeCycles()
  
  self:rankNodes()
  
  self:insertDummyNodes()
  
  self:reduceEdgeCrossings()
  self:positionNodes()
  
  self:removeDummyNodes()

  self:routeEdges()

  self:restoreCycles()

  self:postprocess()
end



function ModularLayered:preprocess()
  -- initialize edge parameters
  for edge in table.value_iter(self.graph.edges) do
    -- read edge parameters
    edge.weight = tonumber(edge:getOption('/graph drawing/layered drawing/weight'))
    edge.minimum_levels = tonumber(edge:getOption('/graph drawing/layered drawing/minimum levels'))

    -- validate edge parameters
    assert(edge.minimum_levels >= 0, 'the edge ' .. tostring(edge) .. ' needs to have a minimum levels value greater than or equal to 0')
  end
end



function ModularLayered:insertDummyNodes()
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



function ModularLayered:removeDummyNodes()
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



function ModularLayered:removeCycles()
  local name, class = self:loadSubAlgorithm('cycle-removal', self.cycle_removal_algorithm)
  
  assert(class, 'the cycle removal algorithm "' .. self.cycle_removal_algorithm .. '" could not be found')

  local algorithm = class:new(self.graph)
  algorithm:run()
end



function ModularLayered:rankNodes()
  local name, class = self:loadSubAlgorithm('node-ranking', self.node_ranking_algorithm)
  
  assert(class, 'the node ranking algorithm "' .. self.node_ranking_algorithm .. '" could not be found')

  local algorithm = class:new(self.graph)
  self.ranking = algorithm:run()
  
  assert(self.ranking and self.ranking.__index == Ranking, 'the node ranking algorithm "' .. tostring(name) .. '" did not return a ranking')
end



function ModularLayered:reduceEdgeCrossings()
  local name, class = self:loadSubAlgorithm('crossing-minimization', self.crossing_minimization_algorithm)

  assert(class, 'the crossing minimzation algorithm "' .. self.crossing_minimization_algorithm .. '" could not be found')

  local algorithm = class:new(self.graph, self.ranking)
  self.ranking = algorithm:run()
  
  assert(self.ranking and self.ranking.__index == Ranking, 'the crossing minimization algorithm "' .. tostring(name) .. '" did not return a ranking')
end



function ModularLayered:positionNodes()
  local name, class = self:loadSubAlgorithm('node-positioning', self.node_positioning_algorithm)

  assert(class, 'the node positioning algorithm "' .. self.node_positioning_algorithm .. '" could not be found')

  local algorithm = class:new(self.graph, self.ranking)
  algorithm:run()
end



function ModularLayered:routeEdges()
  local name, class = self:loadSubAlgorithm('edge-routing', self.edge_routing_algorithm)

  assert(class, 'the edge routing algorithm "' .. self.edge_routing_algorithm .. '" could not be found')

  local algorithm = class:new(self.graph)
  algorithm:run()
end



function ModularLayered:restoreCycles()
  for edge in table.value_iter(self.graph.edges) do
    edge.reversed = false
  end
end



function ModularLayered:postprocess()
end



function ModularLayered:loadSubAlgorithm(step, name)
  -- make sure the first character of the class name is uppercase
  classname = name:gsub('^(%a)', string.upper, 1)

  -- make sure there are no spaces in the file name
  escaped_name = name:gsub(' ', '-')

  local classname = Interface:convertFilenameToClassname(step .. '-' .. classname)
  local filename = 'pgfgd-algorithm-modular-layered-' 
                   .. Interface:convertClassnameToFilename(step) 
                   .. '-' .. escaped_name .. '.lua'

  Sys:log('load class = ' .. classname .. ', file = ' .. filename)

  pgf.load(filename, 'tex', false)

  return classname, pgf.graphdrawing[classname]
end
