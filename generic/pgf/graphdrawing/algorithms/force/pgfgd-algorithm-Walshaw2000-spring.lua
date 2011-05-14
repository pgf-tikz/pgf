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



walshaw_spring = {}



--- Implementation of a spring-electrical graph drawing algorithm.
-- 
-- This implementation is based on the paper 
--
--   "A Multilevel Algorithm for Force-Directed Graph Drawing"
--   C. Walshaw, 2000
--
-- Modifications compared to the original algorithm:
--   - a maximum iteration limit was added
--   - compute the natural spring length for all coarse graphs based
--     on the formula presented by Walshaw, so that the natural spring
--     length of the original graph (coarse graph 0) is the same as
--     the value requested by the user
--   - allow users to define custom node and edge weights in TikZ
--   - stop coarsening if |V(G_i+1)|/|V(G_i)| < p where p = 0.75
--   - stop coarsening if the maximal matching is empty
--   - improve the runtime of the algorithm by use of a quadtree
--     data structure like Hu does in his algorithm
--   - limiting the number of levels of the quadtree is not implemented
--
-- TODO Implement the following keys (or whatever seems appropriate
-- and doable for this algorithm):
--   - /tikz/desired at
--   - /tikz/monotonic energy minimization (how to decide about 
--       alternative steps?)
--   - /tikz/influence cutoff distance (with the multilevel approach)
--   - /tikz/coarsening etc.
--   - /tikz/electric charge (ideally per node, not globally; has proven
--     to be mostly useless in practice...)
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
function drawGraphAlgorithm_Walshaw2000_spring(graph)
  -- check if we should use the multilevel approach
  local use_coarsening = graph:getOption('/graph drawing/spring layout/coarsen') == 'true'

  -- check if we should use the quadtree optimization
  local use_quadtree = graph:getOption('/graph drawing/spring layout/approximate repulsive forces') == 'true'

  -- determine parameters for the algorithm
  local k = tonumber(graph:getOption('/graph drawing/spring layout/natural spring dimension'))
  local C = tonumber(graph:getOption('/graph drawing/spring layout/spring constant'))
  local iterations = tonumber(graph:getOption('/graph drawing/spring layout/iterations'))
  local min_graph_size = tonumber(graph:getOption('/graph drawing/spring layout/coarsening/minimum graph size'))
  local initial_step_length = tonumber(graph:getOption('/graph drawing/spring layout/initial step dimension'))
  local downsize_ratio = tonumber(graph:getOption('/graph drawing/spring layout/coarsening/downsize ratio'))
  downsize_ratio = math.max(0, math.min(1, downsize_ratio))

  Sys:log('WALSHAW: use_coarsening = ' .. tostring(use_coarsening))
  Sys:log('WALSHAW: approximate repulsive forces = ' .. tostring(use_quadtree))
  Sys:log('WALSHAW: iterations = ' .. tostring(iterations))
  Sys:log('WALSHAW: min_graph_size: ' .. tostring(min_graph_size))

  --Sys:log('WALSHAW: graph:')
  --for node in table.value_iter(graph.nodes) do
  --  Sys:log('WALSHAW:   node ' .. node.name)
  --end
  --for edge in table.value_iter(graph.edges) do
  --  Sys:log('WALSHAW:   edge ' .. edge.nodes[1].name .. ' -- ' .. edge.nodes[2].name)
  --end

  -- apply the random seed specified by the user
  local seed = tonumber(graph:getOption('/graph drawing/spring layout/random seed'))
  if seed == 0 then seed = os.time() end
  math.randomseed(seed)

  -- initialize the weights of nodes and edges
  for node in table.value_iter(graph.nodes) do
    node.weight = tonumber(node:getOption('/graph drawing/spring layout/electric charge'))
    node.charged = node.weight ~= 1
  end
  for edge in table.value_iter(graph.edges) do
    edge.weight = 1
  end

  if use_coarsening then
    -- create the initial coarse representation of the original graph
    local coarse_graph = CoarseGraph:new(graph)
    
    -- coarsen the graph repeatedly until only two nodes are left
    while coarse_graph:getSize() > min_graph_size 
      and coarse_graph:getRatio() < (1 - downsize_ratio) 
    do
      coarse_graph:coarsen()
    end
    
    -- compute initial spring length in a way that will result
    -- in a natural spring length of k in the original graph
    k = k / math.pow(math.sqrt(4/7), coarse_graph.level)

    -- generate a random initial layout for the coarsest graph
    walshaw_spring.compute_initial_layout(coarse_graph.graph, k)

    while coarse_graph:getLevel() > 0 do
      -- interpolate from the parent graph
      coarse_graph:interpolate()

      -- update the natural spring length so that, for the original graph, 
      -- it equals the natural spring dimension requested by the user 
      k = k * math.sqrt(4/7)

      -- negative step length means automatic choice of the step length
      -- based on the natural spring dimension
      if initial_step_length < 0 then
        initial_step_length = k
      end

      -- apply the force-based algorithm to improve the layout
      walshaw_spring.compute_force_layout(coarse_graph.graph, k, C, initial_step_length, iterations, use_quadtree)
    end
  else
    -- negative step length means automatic choice of the step length
    -- based on the natural spring dimension
    if initial_step_length < 0 then
      initial_step_length = k
    end

    -- directly compute the force-based layout for the input graph
    walshaw_spring.compute_force_layout(graph, k, C, initial_step_length, iterations, use_quadtree)
  end

  -- adjust orientation
  orientation.adjust(graph)
end



function walshaw_spring.compute_initial_layout(graph, k)
  -- TODO how can supernodes and fixated nodes go hand in hand? 
  -- maybe fix the supernode if at least one of its subnodes is 
  -- fixated?
  --
  -- fixate all nodes that have an 'at' option. this will set the
  -- node.fixed member to true and also set node.pos:x() and node.pos:y()
  walshaw_spring.fixate_nodes(graph)

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
    --Sys:log('WALSHAW: initial layout:')
    for node in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
      node.pos:set{x = positioning_func(1), y = positioning_func(2)}
      --Sys:log('WALSHAW:   ' .. node.name .. ' at ' .. tostring(node.pos))
    end
  end
end



function walshaw_spring.compute_force_layout(graph, k, C, initial_step_length, iterations, use_quadtree)
  --Sys:log('WALSHAW:   compute force based layout')

  for node in table.value_iter(graph.nodes) do
    -- set node displacement to 0
    node.disp = Vector:new(2, function (n) return 0 end)
  end

  -- global (repulsive) force function
  local function fg(distance, weight) 
    return -C * weight * k * k / distance
  end 

  -- repulsive quadtree force function
  local function quadtree_fg(distance, mass)
    -- TODO here (and in the quadtree) we should take the node weight
    -- into the equation
    return -mass * C * k * k / distance
  end

  -- local (spring) force function
  local function fl(distance, d, weight, charged, repulsive_force) 
    -- for charged nodes, never subtract the repulsive force; we
    -- want all other nodes to be attracted more / repulsed less,
    -- depending on the charge
    if charged then
      return (distance - k) / d - fg(distance, weight)
    else
      return ((distance - k) / d) - (repulsive_force or 0)
    end
  end

  -- define the Barnes-Hut opening criterion
  function barnes_hut_criterion(cell, particle)
    local distance = particle.pos:minus(cell.centre_of_mass):norm()
    return cell.width / distance <= 1.2
  end

  -- cooling function
  local function cool(t) return 0.95 * t end

  -- tweakable parameters  
  local t = initial_step_length
  local tol = 0.001

  -- convergence criteria
  local converged = false
  local i = 0
    
  while not converged and i < iterations do
    --Sys:log('WALSHAW:     iteration ' .. i .. ' (max: ' .. iterations .. ')')
  
    -- assume that we are converging
    converged = true
    i = i + 1

    -- check whether the quadtree optimization is to be used
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
        local particle = Particle:new(node.pos, node.weight)
        particle.node = node
        quadtree:insert(particle)
        --Sys:log(' ')
        --Sys:log('quadtree after inserting ' .. node.name .. ' ' .. tostring(node.pos))
        --quadtree:dump('  ')
        --Sys:log(' ')
      end
      --Sys:log(' ')
    end

    local function nodeNotFixed(node) return not node.fixed end

    -- iterate over all nodes
    for v in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
      assert(not v.fixed)

      -- vector for the displacement of v
      local d = Vector:new(2)

      -- repulsive force induced by other nodes
      local repulsive_forces = {}

      -- compute repulsive forces
      if use_quadtree then
        -- determine the cells that have an repulsive influence on v
        local cells = quadtree:findInteractionCells(v, barnes_hut_criterion)

        -- compute the repulsive force between these cells and v
        for cell in table.value_iter(cells) do
          -- check if the cell is a leaf
          if #cell.subcells == 0 then
            -- compute the forces between the node and all particles in the cell
            for particle in table.value_iter(cell.particles) do
              -- build a table that contains the particle plus all its subparticles 
              -- (particles at the same position)
              local real_particles = table.custom_copy(particle.subparticles)
              table.insert(real_particles, particle)

              for real_particle in table.value_iter(real_particles) do
                local delta = real_particle.pos:minus(v.pos)
                local delta_norm = delta:norm()
            
                -- enforce a small virtual distance if the node and the cell's 
                -- centre of mass are located at (almost) the same position
                if delta_norm < 0.1 then
                  delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
                  delta_norm = delta:norm()
                end

                -- compute the repulsive force vector
                local repulsive_force = quadtree_fg(delta_norm, real_particle.mass)
                local force = delta:normalized():timesScalar(repulsive_force)

                -- remember the repulsive force for the particle so that we can 
                -- subtract it later when computing the attractive forces with
                -- adjacent nodes
                repulsive_forces[real_particle.node] = repulsive_force

                -- move the node v accordingly
                d = d:plus(force)
              end
            end
          else
            -- compute the distance between the node and the cell's centre of mass
            local delta = cell.centre_of_mass:minus(v.pos)
            local delta_norm = delta:norm()

            -- enforce a small virtual distance if the node and the cell's 
            -- centre of mass are located at (almost) the same position
            if delta_norm < 0.1 then
              delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
              delta_norm = delta:norm()
            end

            -- compute the repulsive force vector
            local force = delta:normalized():timesScalar(quadtree_fg(delta_norm, cell.mass))

            -- TODO for each neighbour of v, check if it is in this cell.
            -- if this is the case, compute the quadtree force for the mass
            -- 'node.weight / cell.mass' and remember this as the repulsive
            -- force of the neighbour;  (it is not necessarily at
            -- the centre of mass of the cell, so the result is only an
            -- approximation of the real repulsive force generated by the
            -- neighbour)

            -- move te node v accordingly
            d = d:plus(force)
          end
        end
      else
        for u in table.value_iter(graph.nodes) do
          if u.name ~= v.name then
            -- compute the distance between u and v
            local delta = u.pos:minus(v.pos)
            local delta_norm = delta:norm()

            -- enforce a small virtual distance if the nodes are
            -- located at (almost) the same position
            if delta_norm < 0.1 then
              delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
              delta_norm = delta:norm()
            end

            -- compute the repulsive force vector
            local repulsive_force = fg(delta_norm, u.weight)
            local force = delta:normalized():timesScalar(repulsive_force)

            -- remember the repulsive force so we can later subtract them
            -- when computing the attractive forces
            repulsive_forces[u] = repulsive_force

            --Sys:log(v.name .. ' vs. ' .. u.name .. ' >=< ' .. tostring(force))

            -- move the node v accordingly
            d = d:plus(force)
          end
        end
      end

      -- get a list of all neighbours of v
      local neighbours = table.map_values(v.edges, function (e) 
        return e:getNeighbour(v) 
      end)
      
      -- compute attractive forces between v and its neighbours
      for u in table.value_iter(neighbours) do
        -- compute the distance between u and v
        local delta = u.pos:minus(v.pos)
        local delta_norm = delta:norm()

        -- enforce a small virtual distance if the nodes are
        -- located at (almost) the same position
        if delta_norm < 0.1 then
          delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
          delta_norm = delta:norm()
        end

        -- compute the spring force between them
        local attractive_force = fl(delta_norm, #neighbours, u.weight, u.charged, repulsive_forces[u])
        local force = delta:normalized():timesScalar(attractive_force)

        --Sys:log(v.name .. ' and ' .. u.name .. ' <=> ' .. tostring(force))

        -- move the node v accordingly
        d = d:plus(force)
      end

      --Sys:log('WALSHAW: total force of ' .. v.name .. ': ' .. tostring(d))

      -- remember the previous position of v
      old_position = v.pos:copy()

      if d:norm() > 0 then
        -- reposition v according to the force vector and the current temperature
        v.pos = v.pos:plus(d:normalized():timesScalar(math.min(t, d:norm())))
      end

      -- we need to improve the system energy as long as any of
      -- the node movements is large enough to assume we're far
      -- away from the minimum system energy
      if (v.pos:minus(old_position):norm() > k * tol) then
        converged = false
      end
    end

    t = cool(t)
  end

  --for node in table.value_iter(graph.nodes) do
  --  Sys:log('WALSHAW:     node ' .. node.name .. ' at ' .. tostring(node.pos))
  --end
end



--- Fixes nodes at their specified positions.
--
function walshaw_spring.fixate_nodes(graph)
  for node in table.value_iter(graph.nodes) do
    if node:getOption('/graph drawing/desired at') then
      local at_x, at_y = parse_at_option(node)
      node.pos:set{x = at_x, y = at_y}
      node.fixed = true
    end
  end
end



--- Parses the at option of a node.
--
function walshaw_spring.parse_at_option(node)
  local x, y = node:getOption('/graph drawing/desired at'):gmatch('{([%d.-]+)}{([%d.-]+)}')()
  return tonumber(x), tonumber(y)
end



