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
--   Yifan Hu
--
-- although it currently does not implement the multilevel part.
--
-- @param graph
--
function drawGraphAlgorithm_standard_spring_electrical(graph)
  -- apply the random seed specified by the user
  local seed = tonumber(graph:getOption('/graph drawing/spring layouts/random seed') or 42)
  if seed == 0 then seed = os.time() end
  math.randomseed(seed)

  -- determine parameters for the algorithm
  local k = tonumber(graph:getOption('/graph drawing/spring layouts/natural spring dimension') or 28.5)
  local C = tonumber(graph:getOption('/graph drawing/spring layouts/FOO BAR BAZ') or 0.2)
  local iterations = tonumber(graph:getOption('/graph drawing/spring layouts/maximum iterations') or 500)

  -- decide what technique to use for the initial layout
  local initial_positioning = graph:getOption('/graph drawing/spring layouts/initial positioning') or 'random'
  local positioning_func = positioning.technique(initial_positioning, graph, k)

  -- fixate all nodes that have an 'at' option. this will set the
  -- node.fixed member to true and also set node.pos.x and node.pos.y
  fixate_nodes(graph)

  -- compute initial layout based on the selected positioning technique
  --Sys:log('initial layout:')
  for node in table.value_iter(graph.nodes) do
    node.position = Vector:new(2, function (n)
      if node.fixed then
	 local pos = { node.pos:x(), node.pos:y() }
        return pos[n]
      else
        return positioning_func(n)
      end
    end)
    node.disp = Vector:new(2, function (n) return 0 end)

    --Sys:log('  ' .. node:shortname() .. ' at ' .. tostring(node.position))
  end

  -- correct the factor K so that the resulting natural spring dimension
  -- really equals the desired value in the final drawing
  k = 1.76 * k

  -- global (repulsive) force function
  local function fr(distance) 
    return -C * (k*k) / distance
  end 

  -- local (spring) force function
  local function fa(distance) 
    return (distance * distance) / k
  end

  local progress = 0

  -- cooling function
  local function update_steplength(step, energy, energy0) 
    local t = 0.95
    if energy < energy0 then
      progress = progress + 1
      if progress >= 5 then
        progress = 0
        step = step / t
      end
    else
      progress = 0
      step = t * step
    end
    return step
  end

  -- tweakable parameters  
  local step = k
  local tol = 0.001

  -- convergence criteria
  local converged = false
  local i = 0

  -- other parameters of the system
  local energy = 2e+20
  
  while not converged and i < iterations do
    -- assume that we are converging
    converged = true
    i = i + 1

    -- remember the previous system energy
    local energy0 = energy
    energy = 0

    local function nodeNotFixed(node) return not node.fixed end

    -- iterate over all nodes
    for v in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
      assert(not v.fixed)

      -- vector for the displacement of v
      local f = Vector:new(2)

      -- get a list of all neighbours of v
      local neighbours = table.map_values(v.edges, function (e) 
        return e:getNeighbour(v) 
      end)
      
      -- compute attractive forces between v and its neighbours
      for u in table.value_iter(neighbours) do
        -- compute the distance between u and v
        local delta = u.position:minus(v.position)
        local delta_norm = delta:norm()

        -- enforce a small virtual distance if the nodes are
        -- located at (almost) the same position
        if delta_norm < 0.1 then
          delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
          delta_norm = delta:norm()
        end

        -- compute the spring force between them
        local force = delta:normalized():timesScalar(fa(delta_norm))

        --Sys:log(v:shortname() .. ' and ' .. u:shortname() .. ' <=> ' .. tostring(force))

        -- move the node v accordingly
        f = f:plus(force)
      end

      -- compute repulsive forces
      for u in table.value_iter(graph.nodes) do
        if u.name ~= v.name then
          -- compute the distance between u and v
          local delta = u.position:minus(v.position)
          local delta_norm = delta:norm()

          -- enforce a small virtual distance if the nodes are
          -- located at (almost) the same position
          if delta_norm < 0.1 then
            delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
            delta_norm = delta:norm()
          end

          -- compute the repulsive force vector
          local force = delta:normalized():timesScalar(fr(delta_norm))

          --Sys:log(v:shortname() .. ' vs. ' .. u:shortname() .. ' >=< ' .. tostring(force))

          -- move the node v accordingly
          f = f:plus(force)
        end
      end

      --Sys:log('total force of ' .. v:shortname() .. ': ' .. tostring(d))

      -- remember the previous position of v
      old_position = v.position:copy()

      if f:norm() > 0 then
        -- reposition v according to the force vector and the current temperature
        v.position = v.position:plus(f:normalized():timesScalar(step))
        energy = energy + math.pow(f:norm(), 2)
      end

      -- we need to improve the system energy as long as any of
      -- the node movements is large enough to assume we're far
      -- away from the minimum system energy
      if (v.position:minus(old_position):norm() > k * tol) then
        converged = false
      end
    end

    step = update_steplength(step, energy, energy0)
  end

  -- apply node positions
  for node in table.value_iter(graph.nodes) do
     node.pos:set{x = node.position:x()}
     node.pos:set{y = node.position:y()}
  end

  -- adjust orientation
  orientation.adjust(graph)
end



--- Fixes nodes at their specified positions.
--
function fixate_nodes(graph)
  for node in table.value_iter(graph.nodes) do
    if node:getOption('/graph drawing/at') then
       local x, y = parse_at_option(node)
       node.pos:set{x = x, y = y}
       node.fixed = true
    end
  end
end



--- Parses the at option of a node.
--
function parse_at_option(node)
  local x, y = node:getOption('/graph drawing/at'):gmatch('{([%d.-]+)}{([%d.-]+)}')()
  return tonumber(x), tonumber(y)
end



