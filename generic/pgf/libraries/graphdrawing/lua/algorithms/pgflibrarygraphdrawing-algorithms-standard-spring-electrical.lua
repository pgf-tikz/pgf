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
--   "A Multilevel Algorithm for Force-Directed Graph Drawing"
--   C. Walshaw, 2000
--
-- although it currently does not implement the multilevel part.
--
-- Modifications compared to the original algorithm:
--   - a maximum iteration limit was added
--   - the node weight is currently fixed to 1 for all nodes
--   - nodes that are too close to each other during the force 
--     calculation are moved a tiny bit away from each other in 
--     order to avoid division by zero and other nasty effects
-- 
-- Possible enhancements:
--   - implement the multilevel approach
--   - if not set, compute the natural spring dimension automatically,
--     as described in the paper on page 7
--   - allow users to define a node weight in TikZ
--
-- TODO Implement the following keys (or whatever seems appropriate
-- and doable for this algorithm):
--   - /tikz/desired at
--   - /tikz/monotonic energy minimization (how to decide about 
--       alternative steps?)
--   - /tikz/influence cutoff distance (with the multilevel approach)
--   - /tikz/coarsening etc.
--   - /tikz/electric charge (ideally per node, not globally)
--   - /tikz/nail at (or overload /tikz/at)
--   - /tikz/spring stiffness
--   - /tikz/natural spring dimension (ideally per edge, not globally)
--
-- TODO Implement the following features:
--   - clustering of nodes using color classes
--   - different cluster layouts (vertical line, horizontal line,
--     normal cluster, internally fixed subgraph)
--
-- @param graph
--
function drawGraphAlgorithm_standard_spring_electrical(graph)
  -- apply the random seed specified by the user
  math.randomseed(tonumber(graph:getOption('random seed') or os.time()))

  -- determine parameters for the algorithm
  local k = tonumber(graph:getOption('natural spring dimension') or 28.5)
  local C = tonumber(graph:getOption('FOO BAR BAZ') or 0.01)
  local iterations = tonumber(graph:getOption('maximum iterations') or 500)

  -- decide what technique to use for the initial layout
  local initial_positioning = graph:getOption('initial positioning') or 'random'
  local positioning_func = positioning.technique(initial_positioning, graph, k)

  -- compute initial layout based on the selected positioning technique
  --Sys:logMessage('initial layout:')
  for node in table.value_iter(graph.nodes) do
    node.position = Vector:new(2, positioning_func)
    node.disp = Vector:new(2, function (n) return 0 end)

    --Sys:logMessage('  ' .. node:shortname() .. ' at ' .. tostring(node.position))
  end

  -- global (repulsive) force function
  local function fg(x, w) return -C * w * (k*k) / x end 

  -- local (spring) force function
  local function fl(x, d, w) return ((x - k) / d) - fg(x, w) end

  -- cooling function
  local function cool(t) return 0.95 * t end

  -- tweakable parameters  
  local t = k
  local tol = 0.001

  -- convergence criteria
  local converged = false
  local i = 0
  
  while not converged and i < iterations do
    -- assume that we are converging
    converged = true
    i = i + 1

    -- iterate over all nodes
    for v in table.value_iter(graph.nodes) do
      -- vector for the displacement of v
      local d = Vector:new(2)

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
          local force = delta:normalized():timesScalar(fg(delta_norm, 1))

          -- move the node v accordingly
          d = d:plus(force)
        end
      end

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
        local force = delta:normalized():timesScalar(fl(delta_norm, #neighbours, 1))

        -- move the node v accordingly
        d = d:plus(force)
      end

      -- remember the previous position of v
      old_position = v.position:copy()

      if d:norm() > 0 then
        -- reposition v according to the force vector and the current temperature
        v.position = v.position:plus(d:normalized():timesScalar(math.min(t, d:norm())))
      end

      -- we need to improve the system energy as long as any of
      -- the node movements is large enough to assume we're far
      -- away from the minimum system energy
      if (v.position:minus(old_position):norm() > k * tol) then
        converged = false
      end
    end

    t = cool(t)
  end

  -- apply node positions
  for node in table.value_iter(graph.nodes) do
    node.pos.x = node.position:x()
    node.pos.y = node.position:y()
  end

  -- adjust orientation
  orientation.adjust(graph)
end
