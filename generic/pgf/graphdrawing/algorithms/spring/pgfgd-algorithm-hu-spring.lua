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



--- Implementation of a spring-electrical graph drawing algorithm.
-- 
-- This implementation is based on the paper 
--
--   "Efficient and High Quality Force-Directed Graph Drawing"
--   Yifan Hu, 2006
--
-- Modifications compared to the original algorithm:
--
function drawGraphAlgorithm_hu_spring(graph)
  -- apply the random seed specified by the user
  local seed = tonumber(graph:getOption('/graph drawing/spring layout/random seed')) or 42
  if seed == 0 then seed = os.time() end
  math.randomseed(seed)

  --Sys:setVerbose(true)
  --Sys:log('coarsening option: ' .. tostring(graph:getOption('/graph drawing/spring layout/coarsening')))
  --Sys:log('quadtree option:   ' .. tostring(graph:getOption('/graph drawing/spring layout/quadtree')))
  --Sys:setVerbose(false)

  -- check if we should use the multilevel approach
  local use_coarsening = graph:getOption('/graph drawing/spring layout/coarsening') == 'true'

  -- check if we should use the quadtree optimization
  local use_quadtree = graph:getOption('/graph drawing/spring layout/quadtree') == 'true'

  -- determine other parameters of for the algorithm
  local k = tonumber(graph:getOption('/graph drawing/spring layout/natural spring dimension')) or 28.5
  local C = tonumber(graph:getOption('/graph drawing/spring layout/spring constant')) or 0.01 * 10
  local iterations = tonumber(graph:getOption('/graph drawing/spring layout/maximum iterations')) or 500
  local t = tonumber(graph:getOption('/graph drawing/spring layout/temperature')) or 0.9 
  local tol = tonumber(graph:getOption('/graph drawing/spring layout/tolerance')) or 0.01

  Sys:setVerbose(true)
  Sys:log('HU: use coarsening: ' .. tostring(use_coarsening))
  Sys:log('HU: use quadtree: ' .. tostring(use_quadtree))
  Sys:log('HU: iterations: ' .. tostring(iterations))
  --Sys:setVerbose(false)

  -- initialize the weights of nodes and edges
  for node in table.value_iter(graph.nodes) do
    node.weight = 1
  end
  for edge in table.value_iter(graph.edges) do
    edge.weight = 1
  end

  if use_coarsening then
    Sys:log('generating coarse graphs')

    local coarse_graph = CoarseGraph:new(graph)

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

    --Sys:log(' ')

    --while coarse_graph:getLevel() > 0 do
    --  Sys:log('  coarse graph ' .. coarse_graph:getLevel())
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

    while coarse_graph:getSize() > 2 and coarse_graph:getRatio() <= 0.75 do
      coarse_graph:coarsen()
    end

    compute_initial_layout(coarse_graph.graph, k)
    apply_forces(coarse_graph.graph, iterations, use_quadtree, k, C, t, tol)

    while coarse_graph:getLevel() > 0 do
      coarse_graph:interpolate()
      apply_forces(coarse_graph.graph, iterations, use_quadtree, k, C, t, tol)
    end
  else
    -- directly compute the force-based layout for the input graph
    apply_forces(graph, iterations, use_quadtree, k, C, t, tol)
  end

  -- adjust the orientation
  orientation.adjust(graph)
end



function compute_initial_layout(graph, k)
  -- TODO how can supernodes and fixated nodes go hand in hand? 
  -- maybe fix the supernode if at least one of its subnodes is 
  -- fixated?
  --
  -- fixate all nodes that have an 'at' option. this will set the
  -- node.fixed member to true and also set node.pos:x() and node.pos:y()
  fixate_nodes(graph)

  -- decide what technique to use for the initial layout
  local initial_positioning = graph:getOption('/graph drawing/spring layout/initial positioning') or 'random'
  local positioning_func = positioning.technique(initial_positioning, graph, k)

  local function nodeNotFixed(node) return not node.fixed end

  -- compute initial layout based on the selected positioning technique
  --Sys:log('WALSHAW: initial layout:')
  for node in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
    node.pos:set{x = positioning_func(1), y = positioning_func(2)}
  end
end



--- Fixes nodes at their specified positions.
--
function fixate_nodes(graph)
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
function parse_at_option(node)
  local x, y = node:getOption('/graph drawing/desired at'):gmatch('{([%d.-]+)}{([%d.-]+)}')()
  return tonumber(x), tonumber(y)
end



function apply_forces(graph, iterations, use_quadtree, k, C, t, tol)
  local converged = false
  local energy = math.huge
  local iteration = 0
  local progress = 0
  local step = k -- TODO does this really make sense? same for the walshaw algorithm
  
  while not converged and iteration < iterations do
    -- remember old node positions
    local old_positions = table.map_pairs(graph.nodes, function (n, node)
      return node, node.pos:copy()
    end)

    -- remember the old system energy and reset it for the current iteration
    local old_energy = energy
    energy = 0

    for xi in table.value_iter(graph.nodes) do
      local force = Vector:new{ 0, 0 }

      for xj in table.value_iter(graph.nodes) do
        if xi ~= xj then
          local delta = xj.pos:minus(xi.pos)

          if delta:norm() < 0.1 then
            delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
          end

          local fr = repulsive_force(delta:norm(), k, C)
          
          force = force:plus(delta:normalized():timesScalar(fr))
        end
      end

      for edge in table.value_iter(xi.edges) do
        local xj = edge:getNeighbour(xi)

        local delta = xj.pos:minus(xi.pos)

        if delta:norm() < 0.1 then
          delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
        end

        local fa = attractive_force(delta:norm(), k, C)

        force = force:plus(delta:normalized():timesScalar(fa))
      end

      xi.pos = xi.pos:plus(force:normalized():timesScalar(step))

      energy = energy + math.pow(force:norm(), 2)
    end

    step, progress = update_steplength(step, energy, old_energy, t, progress)

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



function repulsive_force(distance, k, C)
  return -C * k*k / distance
end



function attractive_force(distance, k, C)
  return distance*distance / k
end



function update_steplength(step, energy, old_energy, t, progress)
  if energy < old_energy then
    progress = progress + 1
    if progress >= 5 then
      progress = 0
      step = step / t
    end
  else
    progress = 0
    step = t * step
  end
  return step, progress
end
