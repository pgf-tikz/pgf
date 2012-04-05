-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- Implementation of a spring spring graph drawing algorithm.
-- 
-- This implementation is based on the paper 
--
--   "Efficient and High Quality Force-Directed Graph Drawing"
--   Yifan Hu, 2006
--
-- Modifications compared to the original algorithm are explained in 
-- the manual.


graph_drawing_algorithm {
  name = 'SpringHu2006',
  properties = {
    split_into_connected_components = true
  },
  graph_parameters = {
    iterations = {'spring layout/iterations', tonumber},
    cooling_factor = {'spring layout/cooling factor', tonumber},
    initial_step_length = {'spring layout/initial step dimension', tonumber},
    convergence_tolerance = {'spring layout/convergence tolerance', tonumber},

    natural_spring_length = {'spring layout/natural spring dimension', tonumber},
   
    coarsen = {'spring layout/coarsen', toboolean},
    downsize_ratio = {'spring layout/coarsening/downsize ratio', tonumber},
    minimum_graph_size = {'spring layout/coarsening/minimum graph size', tonumber},
  }
}

function SpringHu2006:constructor()
  self.downsize_ratio = math.max(0, math.min(1, tonumber(self.downsize_ratio)))
  
  self.graph_size = #self.graph.nodes
  self.graph_density = (2 * #self.graph.edges) / (#self.graph.nodes * (#self.graph.nodes - 1))
  
  -- validate input parameters
  assert(self.iterations >= 0, 'iterations (value: ' .. self.iterations .. ') need to be greater than 0')
  assert(self.cooling_factor >= 0 and self.cooling_factor <= 1, 'the cooling factor (value: ' .. self.cooling_factor .. ') needs to be between 0 and 1')
  assert(self.initial_step_length >= 0, 'the initial step dimension (value: ' .. self.initial_step_length .. ') needs to be greater than or equal to 0')
  assert(self.convergence_tolerance >= 0, 'the convergence tolerance (value: ' .. self.convergence_tolerance .. ') needs to be greater than or equal to 0')
  assert(self.natural_spring_length >= 0, 'the natural spring dimension (value: ' .. self.natural_spring_length .. ') needs to be greater than or equal to 0')
  assert(self.downsize_ratio >= 0 and self.downsize_ratio <= 1, 'the downsize ratio (value: ' .. self.downsize_ratio .. ') needs to be between 0 and 1')
  assert(self.minimum_graph_size >= 2, 'the minimum graph size of coarse graphs (value: ' .. self.minimum_graph_size .. ') needs to be greater than or equal to 2')
  
  -- initialize node weights
  for node in table.value_iter(self.graph.nodes) do
    node.weight = 1
  end

  -- initialize edge weights
  for edge in table.value_iter(self.graph.edges) do
    edge.weight = 1
  end
end



function SpringHu2006:run()
  -- initialize the coarse graph data structure. note that the algorithm
  -- is the same regardless whether coarsening is used, except that the 
  -- number of coarsening steps without coarsening is 0
  local coarse_graph = CoarseGraph:new(self.graph)

  -- check if the multilevel approach should be used
  if self.coarsen then
    -- coarsen the graph repeatedly until only minimum_graph_size nodes 
    -- are left or until the size of the coarse graph was not reduced by 
    -- at least the downsize ratio configured by the user
    while coarse_graph:getSize() > self.minimum_graph_size 
      and coarse_graph:getRatio() <= (1 - self.downsize_ratio) 
    do
      coarse_graph:coarsen()
    end
  end

  if self.coarsen then
    -- use the natural spring length as the initial natural spring length
    local spring_length = self.natural_spring_length

    -- compute a random initial layout for the coarsest graph
    self:computeInitialLayout(coarse_graph.graph, spring_length)

    -- set the spring length to the average edge length of the initial layout
    spring_length = table.combine_values(coarse_graph.graph.edges, function (sum, edge)
      return sum + edge.nodes[1].pos:minus(edge.nodes[2].pos):norm()
    end, 0)
    spring_length = spring_length / #coarse_graph.graph.edges

    -- additionally improve the layout with the force-based algorithm
    -- if there are more than two nodes in the coarsest graph
    if coarse_graph:getSize() > 2 then
      self:computeForceLayout(coarse_graph.graph, spring_length, SpringHu2006.adaptive_step_update)
    end

    -- undo coarsening step by step, applying the force-based sub-algorithm
    -- to every intermediate coarse graph as well as the original graph
    while coarse_graph:getLevel() > 0 do
      -- compute the diameter of the parent coarse graph
      local parent_diameter = coarse_graph.graph:getPseudoDiameter()

      -- interpolate the previous coarse graph from its parent
      coarse_graph:interpolate()

      -- compute the diameter of the current coarse graph
      local current_diameter = coarse_graph.graph:getPseudoDiameter()

      -- scale node positions by the quotient of the pseudo diameters
      for node in table.value_iter(coarse_graph.graph) do
        node.pos:update(function (n, value)
          return value * (current_diameter / parent_diameter)
        end)
      end

      -- compute forces in the graph
      self:computeForceLayout(coarse_graph.graph, spring_length, SpringHu2006.conservative_step_update)
    end
  else
    -- compute a random initial layout for the coarsest graph
    self:computeInitialLayout(coarse_graph.graph, self.natural_spring_length)

    -- set the spring length to the average edge length of the initial layout
    spring_length = table.combine_values(coarse_graph.graph.edges, function (sum, edge)
      return sum + edge.nodes[1].pos:minus(edge.nodes[2].pos):norm()
    end, 0)
    spring_length = spring_length / #coarse_graph.graph.edges

    -- improve the layout with the force-based algorithm
    self:computeForceLayout(coarse_graph.graph, spring_length, SpringHu2006.adaptive_step_update)
  end

  local avg_spring_length = table.combine_values(self.graph.edges, function (sum, edge)
    return sum + edge.nodes[1].pos:minus(edge.nodes[2].pos):norm()
  end, 0)
  avg_spring_length = avg_spring_length / #self.graph.edges
end



function SpringHu2006:computeInitialLayout(graph, spring_length)
  -- TODO how can supernodes and fixed nodes go hand in hand? 
  -- maybe fix the supernode if at least one of its subnodes is 
  -- fixated?

  -- fixate all nodes that have a 'desired at' option. this will set the
  -- node.fixed member to true and also set node.pos:x() and node.pos:y()
  self:fixateNodes(graph)

  if #graph.nodes == 2 then
    if not (graph.nodes[1].fixed and graph.nodes[2].fixed) then
      local fixed_index = graph.nodes[2].fixed and 2 or 1
      local loose_index = graph.nodes[2].fixed and 1 or 2

      if not graph.nodes[1].fixed and not graph.nodes[2].fixed then
        -- both nodes can be moved, so we assume node 1 is fixed at (0,0)
        graph.nodes[1].pos:set{x = 0, y = 0}
      end

      -- position the loose node relative to the fixed node, with
      -- the displacement (random direction) matching the spring length
      local direction = Vector:new{x = math.random(1, spring_length), y = math.random(1, spring_length)}
      local distance = 1.8 * spring_length * self.graph_density * math.sqrt(self.graph_size) / 2
      local displacement = direction:normalized():timesScalar(distance)

      Sys:log('SpringHu2006: distance = ' .. distance)

      graph.nodes[loose_index].pos = graph.nodes[fixed_index].pos:plus(displacement)
    else
      -- both nodes are fixed, initial layout may be far from optimal
    end
  else
    -- function to filter out fixed nodes
    local function nodeNotFixed(node) return not node.fixed end

    -- use a random positioning technique
    local function positioning_func(n) 
      local radius = 2 * spring_length * self.graph_density * math.sqrt(self.graph_size) / 2
      return math.random(-radius, radius)
    end

    -- compute initial layout based on the random positioning technique
    for node in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
      node.pos:set{x = positioning_func(1), y = positioning_func(2)}
    end
  end
end



function SpringHu2006:computeForceLayout(graph, spring_length, step_update_func)
  -- global (=repulsive) force function
  function repulsive_force(distance, graph_distance, weight)
    --return (1/4) * (1/math.pow(graph_distance, 2)) * (distance - (spring_length * graph_distance))
    return (distance - (spring_length * graph_distance))
  end

  -- fixate all nodes that have a 'desired at' option. this will set the
  -- node.fixed member to true and also set node.pos:x() and node.pos:y()
  self:fixateNodes(graph)

  -- adjust the initial step length automatically if desired by the user
  local step_length = self.initial_step_length == 0 and spring_length or self.initial_step_length
 
  -- convergence criteria etc.
  local converged = false
  local energy = math.huge
  local iteration = 0
  local progress = 0

  -- compute graph distance between all pairs of nodes
  local distances = algorithms.floyd_warshall(graph)

  while not converged and iteration < self.iterations do
    -- remember old node positions
    local old_positions = table.map_pairs(graph.nodes, function (n, node)
      return node, node.pos:copy()
    end)

    -- remember the old system energy and reset it for the current iteration
    local old_energy = energy
    energy = 0

    local function nodeNotFixed(node) return not node.fixed end

    for v in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
      -- vector for the displacement of v
      local d = Vector:new(2)

      for u in table.value_iter(graph.nodes) do
        if v ~= u then
          -- compute the distance between u and v
          local delta = u.pos:minus(v.pos)

          -- enforce a small virtual distance if the nodes are
          -- located at (almost) the same position
          if delta:norm() < 0.1 then
            delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
          end

          local graph_distance = (distances[u] and distances[u][v]) and distances[u][v] or #graph.nodes + 1

          -- compute the repulsive force vector
          local force = repulsive_force(delta:norm(), graph_distance, v.weight)
          local force = delta:normalized():timesScalar(force)

          -- move the node v accordingly
          d = d:plus(force)
        end
      end

      -- really move the node now
      -- TODO note how all nodes are moved by the same amount  (step_length)
      -- while Walshaw multiplies the normalized force with min(step_length, 
      -- d:norm()). could that improve this algorithm even further?
      v.pos = v.pos:plus(d:normalized():timesScalar(step_length))

      -- update the energy function
      energy = energy + math.pow(d:norm(), 2)
    end

    -- update the step length and progress counter
    step_length, progress = step_update_func(step_length, self.cooling_factor, energy, old_energy, progress)

    -- compute the maximum node movement in this iteration
    local max_movement = table.combine_values(graph.nodes, function (max, x)
      local delta = x.pos:minus(old_positions[x])
      if delta:norm() > max then
        return delta:norm()
      else
        return max
      end
    end, 0)
    
    -- the algorithm will converge if the maximum movement is below a 
    -- threshold depending on the spring length and the convergence 
    -- tolerance
    if max_movement < spring_length * self.convergence_tolerance then
      converged = true
    end

    -- increment the iteration counter
    iteration = iteration + 1
  end
end



--- Fixes nodes at their specified positions.
--
function SpringHu2006:fixateNodes(graph)
  local number_of_fixed_nodes = 0

  for node in table.value_iter(graph.nodes) do
    -- read the 'desired at' option of the node
    local coordinate = node:getOption('/graph drawing/desired at')

    if coordinate then
      -- parse the coordinate
      local coordinate_pattern = '{([%d.-]+)}{([%d.-]+)}'
      local x, y = coordinate:gmatch(coordinate_pattern)()
      
      -- apply the coordinate
      node.pos:set{x = tonumber(x), y = tonumber(y)}

      -- mark the node as fixed
      node.fixed = true

      number_of_fixed_nodes = number_of_fixed_nodes + 1
    end
  end
  if number_of_fixed_nodes > 1 then
     self.growth_direction = "fixed"  -- do not grow, orientation is now fixed
  end
end



function SpringHu2006.conservative_step_update(step, cooling_factor)
  return cooling_factor * step, nil
end



function SpringHu2006.adaptive_step_update(step, cooling_factor, energy, old_energy, progress)
  if energy < old_energy then
    progress = progress + 1
    if progress >= 5 then
      progress = 0
      step = step / cooling_factor
    end
  else
    progress = 0
    step = cooling_factor * step
  end
  return step, progress
end
