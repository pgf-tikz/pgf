-- Copyright 2011 by Jannis Pohlmann, 2012 by Till Tantau
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- An implementation of a modular version of the Sugiyama method

local Sugiyama = pgf.gd.new_algorithm_class {
  works_only_on_connected_graphs = true,
  works_only_for_loop_free_graphs = true,
  growth_direction = 90,
  old_graph_model = true,
}

-- Namespace
require("pgf.gd.layered").Sugiyama = Sugiyama


-- Imports

local lib     = require "pgf.gd.lib"

local Ranking = require "pgf.gd.layered.Ranking"

local Edge    = require "pgf.gd.model.Edge"
local Node    = require "pgf.gd.model.Node"




function Sugiyama:run()
  if #self.graph.nodes <= 1 then
     return
  end

  local options = self.digraph.options
  
  local cycle_removal_algorithm         = options['/graph drawing/layered layout/cycle removal']
  local node_ranking_algorithm          = options['/graph drawing/layered layout/node ranking']
  local crossing_minimization_algorithm = options['/graph drawing/layered layout/crossing minimization']
  local node_positioning_algorithm      = options['/graph drawing/layered layout/node positioning']
  local edge_routing_algorithm          = options['/graph drawing/layered layout/edge routing']
  
  self:preprocess()

  -- Helper function for collapsing multiedges
  local function collapse (m,e)
    m.weight         = (m.weight or 0) + e.weight
    m.minimum_levels = math.max((m.minimum_levels or 0), e.minimum_levels)
  end

  -- Rank using cluster

  -- Create a subalgorithm object. Needed so that removed loops
  -- are not stored on top of removed loops from main call.
  local cluster_subalgorithm = { graph = self.graph } 
  self.graph:registerAlgorithm(cluster_subalgorithm)

  self:mergeClusters()
  
  lib.Simplifiers:removeLoopsOldModel(cluster_subalgorithm)
  lib.Simplifiers:collapseMultiedgesOldModel(cluster_subalgorithm, collapse)

  require(cycle_removal_algorithm).new(self, self.graph):run()
  self.ranking = require(node_ranking_algorithm).new(self, self.graph):run()
  self:restoreCycles()

  lib.Simplifiers:expandMultiedgesOldModel(cluster_subalgorithm)
  lib.Simplifiers:restoreLoopsOldModel(cluster_subalgorithm)

  self:expandClusters()
  
  -- Now do actual computation
  lib.Simplifiers:collapseMultiedgesOldModel(cluster_subalgorithm, collapse)
  require(cycle_removal_algorithm).new(self, self.graph):run()
  self:insertDummyNodes()
  
  -- Main algorithm
  require(crossing_minimization_algorithm).new(self, self.graph, self.ranking):run()
  require(node_positioning_algorithm).new(self, self.graph, self.ranking):run()
  
  -- Cleanup
  self:removeDummyNodes()
  lib.Simplifiers:expandMultiedgesOldModel(cluster_subalgorithm)
  require(edge_routing_algorithm).new(self, self.graph):run()
  self:restoreCycles()
end



function Sugiyama:preprocess()
  -- initialize edge parameters
  for edge in table.value_iter(self.graph.edges) do
    -- read edge parameters
    edge.weight = edge:getOption('/graph drawing/layered layout/weight')
    edge.minimum_levels = edge:getOption('/graph drawing/layered layout/minimum levels')

    -- validate edge parameters
    assert(edge.minimum_levels >= 0, 'the edge ' .. tostring(edge) .. ' needs to have a minimum levels value greater than or equal to 0')
  end
end



function Sugiyama:insertDummyNodes()
  -- enumerate dummy nodes using a globally unique numeric ID
  local dummy_id = 1

  -- keep track of the original edges removed
  self.original_edges = {}

  -- keep track of dummy nodes introduced
  self.dummy_nodes = {}

  for node in lib.Iterators:topologicallySorted(self.graph) do
    local in_edges = node:getIncomingEdges()

    for edge in table.value_iter (in_edges) do
      local neighbour = edge:getNeighbour(node)
      local dist = self.ranking:getRank(node) - self.ranking:getRank(neighbour)

      if dist > 1 then
        local dummies = {}

        for i=1,dist-1 do
          local rank = self.ranking:getRank(neighbour) + i

          local dummy = Node.new{
            pos = lib.Vector.new(),
            name = 'dummy@' .. neighbour.name .. '@to@' .. node.name .. '@at@' .. rank,
	    kind = "dummy",
	    orig_vertex = pgf.gd.model.Vertex.new{}
          }

          dummy_id = dummy_id + 1

          self.graph:addNode(dummy)
	  self.ugraph:add {dummy.orig_vertex}

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

          local dummy_edge = Edge.new{
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



function Sugiyama:removeDummyNodes()
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
      local point = bend_node.pos:copy()
      table.insert(edge.bend_points, point)
    end

    if edge.reversed then
      edge.bend_points = table.reverse_values(edge.bend_points, edge.bend_points)
    end

    -- clear the list of bend nodes
    edge.bend_nodes = {}
  end
end



function Sugiyama:mergeClusters()

  self.cluster_nodes = {}
  self.cluster_node = {}
  self.cluster_edges = {}
  self.cluster_original_edges = {}
  self.original_nodes = {}

  for cluster in table.value_iter(self.graph.clusters) do

    local cluster_node = cluster.nodes[1]
    table.insert(self.cluster_nodes, cluster_node)

    for n = 2, #cluster.nodes do
      local other_node = cluster.nodes[n]
      self.cluster_node[other_node] = cluster_node
      table.insert(self.original_nodes, other_node)
    end
  end

  for edge in table.value_iter(self.graph.edges) do
    local tail = edge:getTail()
    local head = edge:getHead()

    if self.cluster_node[tail] or self.cluster_node[head] then
      local cluster_edge = Edge.new{
        direction = Edge.RIGHT,
        weight = edge.weight,
        minimum_levels = edge.minimum_levels,
      }

      if self.cluster_node[tail] then
        cluster_edge:addNode(self.cluster_node[tail])
      else
        cluster_edge:addNode(tail)
      end

      if self.cluster_node[head] then
        cluster_edge:addNode(self.cluster_node[head])
      else
        cluster_edge:addNode(head)
      end

      table.insert(self.cluster_edges, cluster_edge)
      table.insert(self.cluster_original_edges, edge)
    end
  end

  for n = 1, #self.cluster_nodes-1 do
    local first_node = self.cluster_nodes[n]
    local second_node = self.cluster_nodes[n+1]

    local edge = Edge.new{
      direction = Edge.RIGHT,
      weight = 1,
      minimum_levels = 1,
    }

    edge:addNode(first_node)
    edge:addNode(second_node)

    table.insert(self.cluster_edges, edge)
  end

  for node in table.value_iter(self.original_nodes) do
    self.graph:deleteNode(node)
  end
  for edge in table.value_iter(self.cluster_edges) do
    self.graph:addEdge(edge)
  end
  for edge in table.value_iter(self.cluster_original_edges) do
    self.graph:deleteEdge(edge)
  end
end



function Sugiyama:expandClusters()

  for node in table.value_iter(self.original_nodes) do
    self.ranking:setRank(node, self.ranking:getRank(self.cluster_node[node]))
    self.graph:addNode(node)
  end

  for edge in table.value_iter(self.cluster_original_edges) do
    for node in table.value_iter(edge.nodes) do
      node:addEdge(edge)
    end
    self.graph:addEdge(edge)
  end

  for edge in table.value_iter(self.cluster_edges) do
    self.graph:deleteEdge(edge)
  end
end


function Sugiyama:restoreCycles()
  for edge in table.value_iter(self.graph.edges) do
    edge.reversed = false
  end
end





-- done

return Sugiyama