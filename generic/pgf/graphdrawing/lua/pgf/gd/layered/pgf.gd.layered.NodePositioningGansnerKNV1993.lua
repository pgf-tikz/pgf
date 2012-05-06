-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- An sub of Modular for positioning nodes

NodePositioningGansnerKNV1993 = {}
NodePositioningGansnerKNV1993.__index = NodePositioningGansnerKNV1993


-- Namespace
require("pgf.gd.layered").NodePositioningGansnerKNV1993 = NodePositioningGansnerKNV1993


-- Imports

local NodeDistances = require "pgf.gd.lib.NodeDistances"

local Graph = require "pgf.gd.model.Graph"
local Edge  = require "pgf.gd.model.Edge"
local Node  = require "pgf.gd.model.Node"

local NetworkSimplex = require "pgf.gd.layered.NetworkSimplex"






function NodePositioningGansnerKNV1993.new(main_algorithm, graph, ranking)
  local algorithm = {
    main_algorithm = main_algorithm,
    graph = graph,
    ranking = ranking,
  }
  setmetatable(algorithm, NodePositioningGansnerKNV1993)
  return algorithm
end


function NodePositioningGansnerKNV1993:run()
  local auxiliary_graph = self:constructAuxiliaryGraph()

  local simplex = NetworkSimplex.new(auxiliary_graph, NetworkSimplex.BALANCE_LEFT_RIGHT)
  simplex:run()
  local x_ranking = simplex.ranking

  local ranks = self.ranking:getRanks()
  for rank in table.value_iter(ranks) do
    local nodes = self.ranking:getNodes(rank)
    for node in table.value_iter(nodes) do
      node.pos.x = x_ranking:getRank(node.aux_node)
      node[self.main_algorithm] = node[self.main_algorithm] or {}
      node[self.main_algorithm].y = rank
    end
  end
  
  NodeDistances:arrangeLayersByBaselines(self.main_algorithm, self.graph)
end




function NodePositioningGansnerKNV1993:constructAuxiliaryGraph()

  local aux_graph = Graph.new()

  local edge_node = {}

  for node in table.value_iter(self.graph.nodes) do
    local copy = Node.new{
      name = node.name,
      orig_node = node,
    }
    node.aux_node = copy
    aux_graph:addNode(copy)
  end

  for edge in table.reverse_value_iter(self.graph.edges) do
    local node = Node.new{
      name = '{' .. tostring(edge) .. '}',
    }

    aux_graph:addNode(node)

    node.orig_edge = edge
    edge_node[edge] = node

    local head = edge:getHead()
    local tail = edge:getTail()

    local tail_edge = Edge.new{
      direction = Edge.RIGHT,
      minimum_levels = 0,
      weight = edge.weight * self:getOmega(edge),
    }
    tail_edge:addNode(node)
    tail_edge:addNode(tail.aux_node)
    aux_graph:addEdge(tail_edge)

    local head_edge = Edge.new{
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

      local separator_edge = Edge.new{
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



function NodePositioningGansnerKNV1993:getOmega(edge)
  local node1 = edge.nodes[1]
  local node2 = edge.nodes[2]

  if (node1.kind == "dummy") and (node2.kind == "dummy") then
    return 8
  elseif (node1.kind == "dummy") or (node2.kind == "dummy") then
    return 2
  else
    return 1
  end
end



function NodePositioningGansnerKNV1993:getDesiredHorizontalDistance(v, w)
  return NodeDistances:idealSiblingDistance(self.main_algorithm, self.graph.orig_digraph, v.orig_vertex,w.orig_vertex)
end


-- done

return NodePositioningGansnerKNV1993