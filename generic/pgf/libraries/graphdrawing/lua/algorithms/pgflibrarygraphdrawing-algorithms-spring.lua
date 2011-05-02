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



--- Implementation of the popular spring-based algorithm for drawing graphs.
--
-- This is an implementation of a force-based graph drawing algorithm that
-- assumes the nodes are electrically charged particles that push each other
-- away while the edges simulate springs that keep the nodes together.
--
-- The result is a set of repulsive forces between nodes and attractive
-- forces between connected nodes. These forces are applied to the 
-- corresponding nodes which results in a single movement force for each
-- node. This force is then used to move the nodes to a better position. 
--
-- A high number of iterations of this procedure is needed for the 
-- positions of the nodes to stabilize. 
--
-- The code of this implementation is based on the spring layouter
-- written by Johannes Textor for DAGitty (http://dagitty.net).
--
-- @param graph   The graph to draw.
-- @param options Options passed to the algorithm from TikZ.
--
function drawGraphAlgorithm_spring(graph, options)
  -- read options passed to the algorithm from TikZ
  local node_distance = graph:getOption('node distance') or 7
  local iterations = tonumber(graph:getOption('maximum iterations') or 500)
  local max_repulsion = graph:getOption('maximum repulsion') or 6
  local k = graph:getOption('spring constant') or 2
  local c = graph:getOption('IN SEARCH FOR A GOOD NAME') or 0.1 -- Johannes Textor used 0.01 here
  local max_node_movement = graph:getOption('maximum iterative node movement') or 0.5
  local initial_positioning = graph:getOption('positioning') or 'circle'
  local random_seed = tonumber(graph:getOption('random seed') or os.time())

  -- apply the random seed
  math.randomseed(random_seed)

  -- get nodes of the graph in an array
  local nodes = graph.nodes
  
  -- generate a function for initial positioning of the nodes
  local positioning_technique = positioning.technique(initial_positioning, graph)

  -- reset the graph
  for node in table.value_iter(graph.nodes) do
    node.position = Vector:new(2, positioning_technique)
    node.force = Vector:new(2, function (n) return 0 end)
  end
  for edge in table.value_iter(graph.edges) do
    -- default the special attraction of the edge to 1, so
    -- that it is not included in the computation of the
    -- node forces. Users may override this py providing
    -- their own value in TikZ
    edge.attraction = tonumber(edge:getOption('attraction') or 1)
  end

  local node_count = table.count_pairs(graph.nodes)

  -- iteratively improve the energy in the system
  for i = 1, iterations do
    -- update repulsive forces between nodes in the graph
    for u = 1, node_count do
      for v = u + 1, node_count do
        computeRepulsiveForce(graph.nodes[u], graph.nodes[v], k, max_repulsion)
      end
    end

    -- update attractive forces between adjacent nodes
    for edge in table.value_iter(graph.edges) do
      computeAttractiveForce(edge, k, max_repulsion)
    end

    -- update node positions based on the new force
    for node in table.value_iter(graph.nodes) do
      -- create a move vector based on the force
      local move = Vector:new(2, function (n) return c * node.force:get(n) end)

      -- limit the move vector to the maximum allowed node movement
      move:limit(function (k, v) return -max_node_movement, max_node_movement end)

      -- move the node
      node.position:update(function (n, val) return val + move:get(n) end)

      -- reset the force
      node.force:update(function (n, val) return 0 end)
    end
  end

  -- position nodes according to the desired node distance
  for node in table.value_iter(graph.nodes) do
    node.pos.x =  node.position:get(1) * node_distance
    node.pos.y = -node.position:get(2) * node_distance
  end
end



--- Function to compute the repulsive force between two nodes.
--
function computeRepulsiveForce(node1, node2, k, max_repulsion)
  -- compute the distance between the two nodes
  local diff = node2.position:subtract(node1.position)
  local d = diff:norm()

  -- enforce a small distance if the nodes are located 
  -- at the same position
  if d < 0.1 then
    diff:update(function (n, val) return 0.1 * math.random() + 0.1 end)
    d = diff:norm()
  end

  -- update the repulsive force between the two nodes 
  -- unless they are too far way from each other already
  if d < max_repulsion then
    -- compute the repulsive force
    local force = k * k / d

    -- update the forces to be applied to the two nodes
    node2.force:update(function (n, val) return val + force * diff:get(n) / d end)
    node1.force:update(function (n, val) return val - force * diff:get(n) / d end)
  end
end



--- Function to compute the attractive forces of nodes adjacent to a given edge.
--
function computeAttractiveForce(edge, k, max_repulsion)
  -- determine the two nodes of the edge
  local node1 = edge.nodes[1]
  local node2 = edge.nodes[2]

  -- compute the distance between the two nodes
  local diff = node2.position:subtract(node1.position)
  local d = diff:norm()

  -- enforce a small distance if the nodes are located
  -- at the same position
  if d < 0.1 then
    diff:update(function (n, val) return 0.1 * math.random() + 0.1 end)
    d = diff:norm()
  end

  -- limit the distance to the maximum repulsive force
  if d > max_repulsion then
    d = max_repulsion
  end

  -- compute the attractive force between the nodes
  local force = (d * d - k * k) / k

  -- update the attractive force between the nodes, taking
  -- the special attraction of the edge into account
  force = force * math.log(edge.attraction) * 0.5 + 1

  -- update the forces to be applied to both nodes
  node2.force:update(function (n, val) return val - force * diff:get(n) / d end)
  node1.force:update(function (n, val) return val + force * diff:get(n) / d end)
end
