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



hu_spring = {}



--- Implementation of a spring-electrical graph drawing algorithm.
-- 
-- This implementation is based on the paper 
--
--   "Efficient and High Quality Force-Directed Graph Drawing"
--   Yifan Hu, 2006
--
-- Modifications compared to the original algorithm are explained in 
-- the manual.
--
function drawGraphAlgorithm_Hu2006_spring(graph)
  -- check if we should use the multilevel approach
  local use_coarsening = graph:getOption('/graph drawing/spring layout/coarsen') == 'true'

  -- check if we should use the quadtree optimization
  local use_quadtree = graph:getOption('/graph drawing/spring layout/approximate repulsive forces') == 'true'

  -- determine other parameters of for the algorithm
  local iterations = tonumber(graph:getOption('/graph drawing/spring layout/iterations'))
  local k = tonumber(graph:getOption('/graph drawing/spring layout/natural spring dimension'))
  local C = tonumber(graph:getOption('/graph drawing/spring layout/spring constant'))
  local cooling_factor = tonumber(graph:getOption('/graph drawing/spring layout/cooling factor'))
  local tol = tonumber(graph:getOption('/graph drawing/spring layout/convergence tolerance'))
  local min_graph_size = tonumber(graph:getOption('/graph drawing/spring layout/coarsening/minimum graph size'))
  local initial_step_length = tonumber(graph:getOption('/graph drawing/spring layout/initial step dimension'))
  local downsize_ratio = tonumber(graph:getOption('/graph drawing/spring layout/coarsening/downsize ratio'))
  downsize_ratio = math.max(0, math.min(1, downsize_ratio))


  Sys:log('HU: use coarsening: ' .. tostring(use_coarsening))
  Sys:log('HU: use quadtree: ' .. tostring(use_quadtree))
  Sys:log('HU: iterations: ' .. tostring(iterations))
  Sys:log('HU: cooling factor: ' .. tostring(cooling_factor))
  Sys:log('HU: tolerance: ' .. tostring(tol))
  Sys:log('HU: k: ' .. tostring(k))

  local time_before_algorithm = os.clock()

  -- apply the random seed specified by the user
  local seed = tonumber(graph:getOption('/graph drawing/spring layout/random seed'))
  if seed == 0 then seed = os.time() end
  math.randomseed(seed)

  -- initialize the weights of nodes and edges
  for node in table.value_iter(graph.nodes) do
    node.weight = tonumber(node:getOption('/graph drawing/spring layout/electric charge'))
  end
  for edge in table.value_iter(graph.edges) do
    edge.weight = 1
  end

  if use_coarsening then
    --Sys:log('generating coarse graphs')

    local coarse_graph = CoarseGraph:new(graph)

    --Sys:log('  initial graph:')
    --for node in table.value_iter(coarse_graph:getGraph().nodes) do
    --  Sys:log('    node ' .. node.name .. ' at ' .. tostring(node.pos))
    --end
    --for edge in table.value_iter(coarse_graph:getGraph().edges) do
    --  Sys:log('    edge ' .. edge.nodes[1].name .. ' ' .. edge.direction .. ' ' .. edge.nodes[2].name)
    --end
    --
    --while coarse_graph:getSize() > 2 and coarse_graph:getRatio() <= 0.75 do
    --  Sys:log('  coarse graph ' .. coarse_graph:getLevel() + 1)
    --  Sys:log('    construction:')
    --  coarse_graph:coarsen()
    --  Sys:log('    new graph:')
    --  for node in table.value_iter(coarse_graph:getGraph().nodes) do
    --    Sys:log('      node ' .. node.name .. ' at ' .. tostring(node.pos))
    --  end
    --  for edge in table.value_iter(coarse_graph:getGraph().edges) do
    --    Sys:log('      edge ' .. edge.nodes[1].name .. ' ' .. edge.direction .. ' ' .. edge.nodes[2].name)
    --  end
    --  Sys:log('    ratio = ' .. coarse_graph:getRatio())
    --end
    --
    --Sys:log(' ')
    --
    --while coarse_graph:getLevel() > 0 do
    --  Sys:log('  coarse graph ' .. coarse_graph:getLevel()-1)
    --  Sys:log('    reconstruction:')
    --  coarse_graph:interpolate()
    --  Sys:log('    new graph:')
    --  for node in table.value_iter(coarse_graph:getGraph().nodes) do
    --    Sys:log('      node ' .. node.name .. ' at ' .. tostring(node.pos))
    --  end
    --  for edge in table.value_iter(coarse_graph:getGraph().edges) do
    --    Sys:log('      edge ' .. edge.nodes[1].name .. ' ' .. edge.direction .. ' ' .. edge.nodes[2].name)
    --  end
    --  Sys:log('    ratio = ' .. coarse_graph:getRatio())
    --end

    --Sys:log(' ')

    -- coarsen the graph repeatedly until either only two nodes are
    -- left or the number of nodes cannot be reduced by more than
    -- 25% compared to the previous coarse version of the graph
    while coarse_graph:getSize() > min_graph_size 
      and coarse_graph:getRatio() <= (1 - downsize_ratio) 
    do
      coarse_graph:coarsen()
    end

    -- this seems to be necessary to have edges in the final drawing that
    -- have an average length roughly equal to the natural spring dimension
    -- requested by the user
    --
    -- TODO try not applying this factor and instead using the
    -- general repulsive force model with an exponent > 1.
    -- k = 1.76 * k
    k = 1.3 * k

    -- compute a random initial layout for the coarsest graph
    hu_spring.compute_initial_layout(coarse_graph.graph, k)

    -- set k to the average edge length of the initial layout
    k = table.combine_values(coarse_graph.graph.edges, function (sum, edge)
      return sum + edge.nodes[1].pos:minus(edge.nodes[2].pos):norm()
    end, 0)
    k = k / #coarse_graph.graph.edges

    -- negative step length means automatic choice of the step length
    -- based on the natural spring dimension
    if initial_step_length == 0 then
      initial_step_length = k
    end

    -- additionally improve the layout with the force-based algorithm
    -- if there are more than two nodes in the coarsest graph
    if coarse_graph:getSize() > 2 then
      hu_spring.apply_forces(coarse_graph.graph, iterations, use_quadtree, k, C, cooling_factor, tol, initial_step_length, hu_spring.adaptive_step_update)
    end

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
      hu_spring.apply_forces(coarse_graph.graph, iterations, use_quadtree, k, C, cooling_factor, tol, initial_step_length, hu_spring.conservative_step_update)
    end
  else
    -- compute a random initial layout for the coarsest graph
    hu_spring.compute_initial_layout(graph, k)

    -- set k to the average edge length of the initial layout
    k = table.combine_values(graph.edges, function (sum, edge)
      return sum + edge.nodes[1].pos:minus(edge.nodes[2].pos):norm()
    end, 0)
    k = k / #graph.edges

    -- negative step length means automatic choice of the step length
    -- based on the natural spring dimension
    if initial_step_length == 0 then
      initial_step_length = k
    end

    -- improve the layout with the force-based algorithm
    hu_spring.apply_forces(graph, iterations, use_quadtree, k, C, cooling_factor, tol, initial_step_length, hu_spring.conservative_step_update)
  end

  local time_after_algorithm = os.clock()
  Sys:log(string.format('algorithm took %.2f seconds', (time_after_algorithm - time_before_algorithm)))

  Sys:log(' ')

  -- adjust the orientation
  orientation.adjust(graph)
end



function hu_spring.compute_initial_layout(graph, k)
  -- TODO how can supernodes and fixated nodes go hand in hand? 
  -- maybe fix the supernode if at least one of its subnodes is 
  -- fixated?
  --
  -- fixate all nodes that have an 'at' option. this will set the
  -- node.fixed member to true and also set node.pos:x() and node.pos:y()
  hu_spring.fixate_nodes(graph)

  if #graph.nodes == 2 then
    -- TODO here we need to respect fixed nodes
    graph.nodes[1].pos:set{x = 0, y = 0}
    graph.nodes[2].pos:set{x = math.random(1, k), y = math.random(1, k)}
    graph.nodes[2].pos = graph.nodes[2].pos:normalized():timesScalar(k)
  else
    -- decide what technique to use for the initial layout
    local positioning_func = positioning.technique('random', graph, k)

    local function nodeNotFixed(node) return not node.fixed end

    -- compute initial layout based on the selected positioning technique
    for node in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
      node.pos:set{x = positioning_func(1), y = positioning_func(2)}
    end
  end
end



--- Fixes nodes at their specified positions.
--
function hu_spring.fixate_nodes(graph)
  for node in table.value_iter(graph.nodes) do
    if node:getOption('/graph drawing/desired at') then
      local at_x, at_y = parse_at_option(node)
      node.pos:set{x = at_x, y = at_y}
      node.fixed = true
    end
  end
end



--- Parses the |/graph drawing/desired at| option of a node.
--
function hu_spring.parse_at_option(node)
  local x, y = node:getOption('/graph drawing/desired at'):gmatch('{([%d.-]+)}{([%d.-]+)}')()
  return tonumber(x), tonumber(y)
end



function hu_spring.apply_forces(graph, iterations, use_quadtree, k, C, cooling_factor, tol, initial_step_length, step_update_func)
  local converged = false
  local energy = math.huge
  local iteration = 0
  local progress = 0
  local step = initial_step_length
  
  while not converged and iteration < iterations do
    -- remember old node positions
    local old_positions = table.map_pairs(graph.nodes, function (n, node)
      return node, node.pos:copy()
    end)

    -- remember the old system energy and reset it for the current iteration
    local old_energy = energy
    energy = 0

    local quadtree = nil
    if use_quadtree then
      -- compute the minimum x and y coordinates of all nodes
      local min_pos = table.combine_values(graph.nodes, function (min_pos, node)
        return Vector:new(2, function (n) 
          return math.min(min_pos:get(n), node.pos:get(n))
        end)
      end, graph.nodes[1].pos)

      -- compute maximum x and y coordinates of all nodes
      local max_pos = table.combine_values(graph.nodes, function (max_pos, node)
        return Vector:new(2, function (n) 
          return math.max(max_pos:get(n), node.pos:get(n))
        end)
      end, graph.nodes[1].pos)

      -- make sure the maximum position is at least a tiny bit
      -- larger than the minimum position
      if min_pos:equals(max_pos) then
        max_pos = max_pos:plus(Vector:new(2, function (n)
          return 0.1 + math.random() * 0.1
        end))
      end

      min_pos = min_pos:minusScalar(1)
      max_pos = max_pos:plusScalar(1)

      -- create the quadtree
      quadtree = QuadTree:new(min_pos:x(), min_pos:y(),
                              max_pos:x() - min_pos:x(),
                              max_pos:y() - min_pos:y())

      -- insert nodes into the quadtree
      --Sys:log(' ')
      for node in table.value_iter(graph.nodes) do
        --Sys:log(' ')
        --Sys:log('quadtree before inserting ' .. node.name .. ' ' .. tostring(node.pos))
        --quadtree:dump('  ')
        quadtree:insert(Particle:new(node.pos, node.weight))
        --Sys:log(' ')
        --Sys:log('quadtree after inserting ' .. node.name .. ' ' .. tostring(node.pos))
        --quadtree:dump('  ')
        --Sys:log(' ')
      end
      --Sys:log(' ')
    end

    for v in table.value_iter(graph.nodes) do
      local force = Vector:new{ 0, 0 }

      -- compute repulsive forces
      if use_quadtree then
        -- determine the cells that have a repulsive influence on v
        local cells = quadtree:findInteractionCells(v, hu_spring.barnes_hut_criterion)

        -- compute the repulsive force between these cells and v
        for cell in table.value_iter(cells) do
          -- check if the cell is a leaf
          if #cell.subcells == 0 then
            -- compute the forces between the node and all particles in the cell
            for particle in table.value_iter(cell.particles) do
              local real_particles = table.custom_copy(particle.subparticles)
              table.insert(real_particles, particle)

              for real_particle in table.value_iter(real_particles) do
                local delta = real_particle.pos:minus(v.pos)
            
                -- enforce a small virtual distance if the node and the cell's 
                -- centre of mass are located at (almost) the same position
                if delta:norm() < 0.1 then
                  delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
                end

                local fr = hu_spring.repulsive_force_quadtree(delta:norm(), real_particle.mass, k, C)
                
                force = force:plus(delta:normalized():timesScalar(fr))
              end
            end
          else
            -- compute the distance between the node and the cell's centre of mass
            local delta = cell.centre_of_mass:minus(v.pos)

            -- enforce a small virtual distance if the node and the cell's 
            -- centre of mass are located at (almost) the same position
            if delta:norm() < 0.1 then
              delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
            end

            local fr = hu_spring.repulsive_force_quadtree(delta:norm(), cell.mass, k, C)
            
            force = force:plus(delta:normalized():timesScalar(fr))
          end
        end
      else
        for u in table.value_iter(graph.nodes) do
          if v ~= u then
            local delta = u.pos:minus(v.pos)

            if delta:norm() < 0.1 then
              delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
            end

            local fr = hu_spring.repulsive_force(delta:norm(), u.weight, k, C)
            
            force = force:plus(delta:normalized():timesScalar(fr))
          end
        end
      end

      for edge in table.value_iter(v.edges) do
        local u = edge:getNeighbour(v)

        local delta = u.pos:minus(v.pos)

        if delta:norm() < 0.1 then
          delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
        end
    
        local fa = hu_spring.attractive_force(delta:norm(), k, C)

        force = force:plus(delta:normalized():timesScalar(fa))
      end

      v.pos = v.pos:plus(force:normalized():timesScalar(step))

      --Sys:log('HU:   move ' .. v.name .. ' to ' .. tostring(v.pos))

      energy = energy + math.pow(force:norm(), 2)
    end

    step, progress = step_update_func(step, cooling_factor, energy, old_energy, progress)

    local max_movement = table.combine_values(graph.nodes, function (max, x)
      local delta = x.pos:minus(old_positions[x])
      local delta_norm = delta:norm()

      if delta_norm > max then
        return delta_norm
      else
        return max
      end
    end, 0)
    
    if max_movement < k * tol then
      converged = true
    end

    iteration = iteration + 1
  end
end



function hu_spring.repulsive_force(distance, weight, k, C)
  return (-1) * weight * C * k * k * weight / distance
end



function hu_spring.repulsive_force_quadtree(distance, mass, k, C)
  return (-1) * mass * C * (k * k) / distance
end



function hu_spring.attractive_force(distance, k, C)
  -- TODO HU does not subtract k here but this might make sense because
  -- the force should be repulsive if the edge is compressed and
  -- attractive if the edge is longer than its natural length
  return (distance * distance - k) / k
end



function hu_spring.conservative_step_update(step, cooling_factor)
  return cooling_factor * step, nil
end



function hu_spring.adaptive_step_update(step, cooling_factor, energy, old_energy, progress)
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



function hu_spring.barnes_hut_criterion(cell, particle)
  local distance = particle.pos:minus(cell.centre_of_mass):norm()
  return cell.width / distance <= 1.2
end
