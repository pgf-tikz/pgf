-- Copyright 2011 by Jannis Pohlmann
-- Copyright 2012 by Till Tantau
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

local lib = require "pgf.gd.lib"
local QuadTree = require "pgf.gd.force.QuadTree"


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
--   - /tikz/influence cutoff distance
--   - /tikz/spring stiffness (could this be the equivalent to the electric 
--       charge of nodes?
--   - /tikz/natural spring dimension per edge
--
-- TODO Implement the following features:
--   - clustering of nodes using color classes
--   - different cluster layouts (vertical line, horizontal line,
--     normal cluster, internally fixed subgraph)


graph_drawing_algorithm {
  name = 'SpringElectricalWalshaw2000',
  properties = {
    works_only_on_connected_graphs = true,
    works_only_for_loop_free_graphs = true,
    works_only_for_simple_graphs = true,
  },
  graph_parameters = {
    iterations = {'spring electrical layout/iterations', tonumber},
    cooling_factor = {'spring electrical layout/cooling factor', tonumber},
    initial_step_length = {'spring electrical layout/initial step dimension', tonumber},
    convergence_tolerance = {'spring electrical layout/convergence tolerance', tonumber},

    natural_spring_length = {'spring electrical layout/natural spring dimension', tonumber},
    spring_constant = {'spring electrical layout/spring constant', tonumber},

    approximate_repulsive_forces = {'spring electrical layout/approximate electric forces', toboolean},
    repulsive_force_order = {'spring electrical layout/electric force order', tonumber},
   
    coarsen = {'spring electrical layout/coarsen', toboolean},
    downsize_ratio = {'spring electrical layout/coarsening/downsize ratio', tonumber},
    minimum_graph_size = {'spring electrical layout/coarsening/minimum graph size', tonumber},
  }
}


function SpringElectricalWalshaw2000:run()

  -- Adjust types
  self.downsize_ratio = math.max(0, math.min(1, self.downsize_ratio))
  self.graph_size = #self.graph.nodes
  self.graph_density = (2 * #self.graph.edges) / (#self.graph.nodes * (#self.graph.nodes - 1))

  -- validate input parameters
  assert(self.iterations >= 0, 'iterations (value: ' .. self.iterations .. ') need to be greater than 0')
  assert(self.cooling_factor >= 0 and self.cooling_factor <= 1, 'the cooling factor (value: ' .. self.cooling_factor .. ') needs to be between 0 and 1')
  assert(self.initial_step_length >= 0, 'the initial step dimension (value: ' .. self.initial_step_length .. ') needs to be greater than or equal to 0')
  assert(self.convergence_tolerance >= 0, 'the convergence tolerance (value: ' .. self.convergence_tolerance .. ') needs to be greater than or equal to 0')
  assert(self.natural_spring_length >= 0, 'the natural spring dimension (value: ' .. self.natural_spring_length .. ') needs to be greater than or equal to 0')
  assert(self.spring_constant >= 0, 'the spring constant (value: ' .. self.spring_constant .. ') needs to be greater or equal to 0')
  assert(self.downsize_ratio >= 0 and self.downsize_ratio <= 1, 'the downsize ratio (value: ' .. self.downsize_ratio .. ') needs to be between 0 and 1')
  assert(self.minimum_graph_size >= 2, 'the minimum graph size of coarse graphs (value: ' .. self.minimum_graph_size .. ') needs to be greater than or equal to 2')

  -- initialize node weights
  for node in table.value_iter(self.graph.nodes) do
    node.weight = tonumber(node:getOption('/graph drawing/spring electrical layout/electric charge'))

    -- a node is charged if its weight derives from the default setting 
    -- of 1 (where it has no influence on the forces)
    node.charged = node.weight ~= 1
  end

  -- initialize edge weights
  for edge in table.value_iter(self.graph.edges) do
    edge.weight = 1
  end
  
  
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
      and coarse_graph:getRatio() < (1 - self.downsize_ratio)
    do
      coarse_graph:coarsen()
    end
  end

  -- compute the natural spring length for the coarsest graph in a way
  -- that will result in the desired natural spring length in the 
  -- original graph
  local spring_length = self.natural_spring_length / math.pow(math.sqrt(4/7), coarse_graph:getLevel())

  if self.coarsen then
    -- generate a random initial layout for the coarsest graph
    self:computeInitialLayout(coarse_graph.graph, spring_length)

    -- undo coarsening step by step, applying the force-based sub-algorithm
    -- to every intermediate coarse graph as well as the original graph
    while coarse_graph:getLevel() > 0 do
      -- interpolate the previous coarse graph
      coarse_graph:interpolate()

      -- update the natural spring length so that, for the original graph,
      -- it equals the natural spring dimension configured by the user
      spring_length = spring_length * math.sqrt(4/7)

      -- apply the force-based algorithm to improve the layout
      self:computeForceLayout(coarse_graph.graph, spring_length)
    end
  else
    -- generate a random initial layout for the coarsest graph
    self:computeInitialLayout(coarse_graph.graph, spring_length)
    
    -- apply the force-based algorithm to improve the layout
    self:computeForceLayout(coarse_graph.graph, spring_length)
  end    
end



function SpringElectricalWalshaw2000:computeInitialLayout(graph, spring_length)
  -- TODO how can supernodes and fixed nodes go hand in hand? 
  -- maybe fix the supernode if at least one of its subnodes is 
  -- fixated?

  -- fixate all nodes that have a 'desired at' option. this will set the
  -- node.fixed member to true and also set node.pos.x and node.pos.y
  self:fixateNodes(graph)

  if #graph.nodes == 2 then
    if not (graph.nodes[1].fixed and graph.nodes[2].fixed) then
      local fixed_index = graph.nodes[2].fixed and 2 or 1
      local loose_index = graph.nodes[2].fixed and 1 or 2

      if not graph.nodes[1].fixed and not graph.nodes[2].fixed then
        -- both nodes can be moved, so we assume node 1 is fixed at (0,0)
        graph.nodes[1].pos.x = 0
        graph.nodes[1].pos.y = 0
      end

      -- position the loose node relative to the fixed node, with
      -- the displacement (random direction) matching the spring length
      local direction = lib.Vector:new{x = math.random(1, 2), y = math.random(1, 2)}
      local distance = 3 * spring_length * self.graph_density * math.sqrt(self.graph_size) / 2
      local displacement = direction:normalized():timesScalar(distance)

      graph.nodes[loose_index].pos = graph.nodes[fixed_index].pos:plus(displacement)
    else
      -- both nodes are fixed, initial layout may be far from optimal
    end
  else
    -- function to filter out fixed nodes
    local function nodeNotFixed(node) return not node.fixed end

    -- use the random positioning technique
    local function positioning_func(n)
      local radius = 3 * spring_length * self.graph_density * math.sqrt(self.graph_size) / 2
      return math.random(-radius, radius)
    end

    -- compute initial layout based on the random positioning technique
    for _,node in ipairs(graph.nodes) do
      if not node.fixed then
	node.pos.x = positioning_func(1)
	node.pos.y = positioning_func(2)
      end
    end
  end
end



function SpringElectricalWalshaw2000:computeForceLayout(graph, spring_length)
  -- global (=repulsive) force function
  local function accurate_repulsive_force(distance, weight) 
    return - self.spring_constant * weight * math.pow(spring_length, self.repulsive_force_order + 1) / math.pow(distance, self.repulsive_force_order)
  end 

  -- global (=repulsive, approximated) force function
  local function approximated_repulsive_force(distance, mass)
    return - mass * self.spring_constant * math.pow(spring_length, self.repulsive_force_order + 1) / math.pow(distance, self.repulsive_force_order)
  end

  -- local (spring) force function
  local function attractive_force(distance, d, weight, charged, repulsive_force) 
    -- for charged nodes, never subtract the repulsive force; we want ALL other 
    -- nodes to be attracted more / repulsed less (not just non-adjacent ones),
    -- depending on the charge of course
    if charged then
      return (distance - spring_length) / d - accurate_repulsive_force(distance, weight)
    else
      return (distance - spring_length) / d - (repulsive_force or 0)
    end
  end

  -- define the Barnes-Hut opening criterion
  function barnes_hut_criterion(cell, particle)
    local distance = particle.pos:minus(cell.center_of_mass):norm()
    return cell.width / distance <= 1.2
  end

  -- fixate all nodes that have a 'desired at' option. this will set the
  -- node.fixed member to true and also set node.pos.x and node.pos.y
  self:fixateNodes(graph)

  -- adjust the initial step length automatically if desired by the user
  local step_length = self.initial_step_length == 0 and spring_length or self.initial_step_length

  -- convergence criteria
  local converged = false
  local i = 0
    
  while not converged and i < self.iterations do
  
    -- assume that we are converging
    converged = true
    i = i + 1

    -- build the quadtree for approximating repulsive forces, if desired
    local quadtree = nil
    if self.approximate_repulsive_forces then
      quadtree = self:buildQuadtree(graph)
    end

    local function nodeNotFixed(node) return not node.fixed end

    -- iterate over all nodes
    for _,v in ipairs(graph.nodes) do
      if not v.fixed then
	-- vector for the displacement of v
	local d = lib.Vector:new(2)

	-- repulsive force induced by other nodes
	local repulsive_forces = {}

	-- compute repulsive forces
	if self.approximate_repulsive_forces then
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
		  
		  -- enforce a small virtual distance if the node and the cell's 
		  -- center of mass are located at (almost) the same position
		  if delta:norm() < 0.1 then
		    delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
		  end

		  -- compute the repulsive force vector
		  local repulsive_force = approximated_repulsive_force(delta:norm(), real_particle.mass)
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
	      -- compute the distance between the node and the cell's center of mass
	      local delta = cell.center_of_mass:minus(v.pos)

	      -- enforce a small virtual distance if the node and the cell's 
	      -- center of mass are located at (almost) the same position
	      if delta:norm() < 0.1 then
		delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
	      end

	      -- compute the repulsive force vector
	      local repulsive_force = approximated_repulsive_force(delta:norm(), cell.mass)
	      local force = delta:normalized():timesScalar(repulsive_force)

	      -- TODO for each neighbour of v, check if it is in this cell.
	      -- if this is the case, compute the quadtree force for the mass
	      -- 'node.weight / cell.mass' and remember this as the repulsive
	      -- force of the neighbour;  (it is not necessarily at
	      -- the center of mass of the cell, so the result is only an
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

	      -- enforce a small virtual distance if the nodes are
	      -- located at (almost) the same position
	      if delta:norm() < 0.1 then
		delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
	      end

	      -- compute the repulsive force vector
	      local repulsive_force = accurate_repulsive_force(delta:norm(), u.weight)
	      local force = delta:normalized():timesScalar(repulsive_force)

	      -- remember the repulsive force so we can later subtract them
	      -- when computing the attractive forces
	      repulsive_forces[u] = repulsive_force

	      -- move the node v accordingly
	      d = d:plus(force)
	    end
	  end
	end

	-- compute attractive forces between v and its neighbours
	for edge in table.value_iter(v.edges) do
	  local u = edge:getNeighbour(v)

	  -- compute the distance between u and v
	  local delta = u.pos:minus(v.pos)

	  -- enforce a small virtual distance if the nodes are
	  -- located at (almost) the same position
	  if delta:norm() < 0.1 then
	    delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
	  end

	  -- compute the spring force between them
	  local attr_force = attractive_force(delta:norm(), #v.edges, u.weight, u.charged, repulsive_forces[u])
	  local force = delta:normalized():timesScalar(attr_force)

	  -- move the node v accordingly
	  d = d:plus(force)
	end

	-- remember the previous position of v
	old_position = v.pos:copy()

	if d:norm() > 0 then
	  -- reposition v according to the force vector and the current temperature
	  v.pos = v.pos:plus(d:normalized():timesScalar(math.min(step_length, d:norm())))
	end

	-- we need to improve the system energy as long as any of
	-- the node movements is large enough to assume we're far
	-- away from the minimum system energy
	if v.pos:minus(old_position):norm() > spring_length * self.convergence_tolerance then
	  converged = false
	end
      end
    end

    -- update the step length using the conservative cooling scheme
    step_length = self.cooling_factor * step_length
  end
end



--- Fixes nodes at their specified positions.
--
function SpringElectricalWalshaw2000:fixateNodes(graph)
  local number_of_fixed_nodes = 0

  for node in table.value_iter(graph.nodes) do
    -- read the 'desired at' option of the node
    local coordinate = node:getOption('/graph drawing/desired at')

    if coordinate then
      -- parse the coordinate
      local coordinate_pattern = '{([%d.-]+)}{([%d.-]+)}'
      local x, y = coordinate:gmatch(coordinate_pattern)()
      
      -- apply the coordinate
      node.pos.x = tonumber(x)
      node.pos.y = tonumber(y)

      -- mark the node as fixed
      node.fixed = true

      number_of_fixed_nodes = number_of_fixed_nodes + 1
    end
  end
  if number_of_fixed_nodes > 1 then
     self.growth_direction = "fixed"  -- do not grow, orientation is now fixed
  end
end



function SpringElectricalWalshaw2000:buildQuadtree(graph)
  -- compute the minimum x and y coordinates of all nodes
  local min_pos = table.combine_values(graph.nodes, function (min_pos, node)
    return lib.Vector:new(2, function (n) 
      return math.min(min_pos[n], node.pos[n])
    end)
  end, graph.nodes[1].pos)

  -- compute maximum x and y coordinates of all nodes
  local max_pos = table.combine_values(graph.nodes, function (max_pos, node)
    return lib.Vector:new(2, function (n) 
      return math.max(max_pos[n], node.pos[n])
    end)
  end, graph.nodes[1].pos)

  -- make sure the maximum position is at least a tiny bit
  -- larger than the minimum position
  if min_pos:equals(max_pos) then
    max_pos = max_pos:plus(lib.Vector:new(2, function (n)
      return 0.1 + math.random() * 0.1
    end))
  end

  -- make sure to make the quadtree area slightly larger than required
  -- in theory; for some reason Lua will otherwise think that nodes with
  -- min/max x/y coordinates are outside the box... weird? yes.
  min_pos = min_pos:minusScalar(1)
  max_pos = max_pos:plusScalar(1)

  -- create the quadtree
  quadtree = QuadTree:new(min_pos.x, min_pos.y,
			  max_pos.x - min_pos.x,
			  max_pos.y - min_pos.y)

  -- insert nodes into the quadtree
  for node in table.value_iter(graph.nodes) do
    local particle = QuadTree.Particle:new(node.pos, node.weight)
    particle.node = node
    quadtree:insert(particle)
  end

  return quadtree
end
