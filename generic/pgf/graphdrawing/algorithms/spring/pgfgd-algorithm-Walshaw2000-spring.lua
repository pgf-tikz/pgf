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
  -- apply the random seed specified by the user
  local seed = tonumber(graph:getOption('/graph drawing/spring layout/random seed')) or 42
  if seed == 0 then seed = os.time() end
  math.randomseed(seed)

  for key, val in pairs(graph.options) do
    Sys:setVerbose(true)
    Sys:log(tostring(key) .. ' => ' .. tostring(val))
    Sys:setVerbose(false)
  end

  -- check if we should use the multilevel approach
  local use_coarsening = graph:getOption('/graph drawing/spring layout/coarsening') == 'true'

  -- check if we should use the quadtree optimization
  local use_quadtree = graph:getOption('/graph drawing/spring layout/quadtree') == 'true'

  -- determine parameters for the algorithm
  local k = tonumber(graph:getOption('/graph drawing/spring layout/natural spring dimension')) or 28.5
  local C = tonumber(graph:getOption('/graph drawing/spring layout/spring constant')) or 0.01
  local iterations = tonumber(graph:getOption('/graph drawing/spring layout/maximum iterations')) or 500

  Sys:setVerbose(true)
  Sys:log('WALSHAW: use_coarsening = ' .. tostring(use_coarsening))
  Sys:log('WALSHAW: use_quadtree = '   .. tostring(use_quadtree))
  Sys:log('WALSHAW: iterations = ' .. tostring(iterations))
  Sys:setVerbose(false)

  --Sys:log('WALSHAW: graph:')
  --for node in table.value_iter(graph.nodes) do
  --  Sys:log('WALSHAW:   node ' .. node.name)
  --end
  --for edge in table.value_iter(graph.edges) do
  --  Sys:log('WALSHAW:   edge ' .. edge.nodes[1].name .. ' -- ' .. edge.nodes[2].name)
  --end

  if use_coarsening then
    -- compute coarsened graphs (this could be done on-demand instead
    -- of computing all graphs at once to reduce memory usage)
    local graphs = walshaw_spring.compute_coarse_graphs(graph)

    for i = #graphs,1,-1 do
      --Sys:setVerbose(true)
      --Sys:log('WALSHAW: lay out coarse graph ' .. i-1 .. ' (' .. #graphs[i].nodes .. ' nodes)')
      --Sys:setVerbose(false)

      if i == #graphs then
        -- compute initial natural spring length in a way that will
        -- result in a natural spring length of k in the original graph
        graphs[i].k = k / math.pow(math.sqrt(4/7), #graphs-1)

        -- generate an initial random layout for the coarsest graph
        walshaw_spring.compute_initial_layout(graphs[i])
      else
        -- interpolate from the parent coarse graph and apply the
        -- force-based algorithm to improve the layout
        walshaw_spring.interpolate_from_parent(graphs[i], graphs[i+1])
        walshaw_spring.compute_force_layout(graphs[i], C, iterations, use_quadtree)
      end

      --Sys:log('WALSHAW:  ')
    end
  else
    -- use the natural spring dimension provided by the user as the 
    -- natural spring length
    graph.k = k
    
    -- set node and edge weights to 1
    for node in table.value_iter(graph.nodes) do node.weight = 1 end
    for edge in table.value_iter(graph.edges) do edge.weight = 1 end

    -- directly compute the force-based layout for the input graph
    walshaw_spring.compute_force_layout(graph, C, iterations, use_quadtree)
  end

  -- adjust orientation
  orientation.adjust(graph)
end


function walshaw_spring.compute_coarse_graphs(graph)
  -- determine parameters for the algorithm
  local minimum_graph_size = tonumber(graph:getOption('/graph drawing/spring layout/minimum coarsened graph size') or 2)
  local coarsening_threshold = tonumber(graph:getOption('/graph drawing/spring layout/coarsening threshold') or 0.75)

  -- set weights to 1 unless specified otherwise
  for node in table.value_iter(graph.nodes) do
    node.weight = tonumber(node:getOption('/graph drawing/spring layout/node weight') or 1)
  end
  for edge in table.value_iter(graph.edges) do
    edge.weight = tonumber(edge:getOption('/graph drawing/spring layout/edge weight') or 1)
  end

  -- compute iteratively coarsened graphs
  local graphs = { graph }
  --dump_current_graph(graphs)

  while #graphs[#graphs].nodes > minimum_graph_size do
    --Sys:log('WALSHAW: generating coarse graph ' .. #graphs-1)

    local parent_graph = graphs[#graphs]

    -- copy the parent graph
    local coarse_graph = walshaw_spring.copy_graph(parent_graph)
    table.insert(graphs, coarse_graph)

    -- approximate a maximum matching using a greedy heuristic
    local matching_edges = walshaw_spring.find_maximal_matching(coarse_graph)

    -- abort coarsening if there are no matching edges we can contract
    if #matching_edges == 0 then
      table.remove(graphs, #graphs)
      break
    end

    for edge in table.value_iter(matching_edges) do
      --Sys:log('WALSHAW: contracting edge ' .. tostring(edge))

      -- get the two nodes of the matching edge that we are about to contract
      local i, j = edge.nodes[1], edge.nodes[2]

      -- create a supernode v
      local v = Node:new{ name = i.name .. ':' .. j.name }
      v.weight = i.weight + j.weight

      -- remember the nodes from which the supernode was created
      v.subnodes = { i, j }

      -- add the supernode to the graph
      coarse_graph:addNode(v)
      
      -- collect all neighbours of the nodes to merge, create a 
      -- node -> edge mapping
      local i_neighbours = table.map_pairs(i.edges, function (n, edge)
        return edge:getNeighbour(i), edge
      end)
      local j_neighbours = table.map_pairs(j.edges, function (n, edge)
        return edge:getNeighbour(j), edge
      end)

      -- remove the two nodes themselves from the neighbour list
      i_neighbours = table.filter_keys(i_neighbours, function (node)
        return node ~= j
      end)
      j_neighbours = table.filter_keys(j_neighbours, function (node)
        return node ~= i
      end)

      -- compute a list of neighbours i and j have in common
      local common_neighbours = table.filter_keys(i_neighbours, function (node)
        return j_neighbours[node] ~= nil
      end)

      -- create a node -> edges mapping for common neighbours
      common_neighbours = table.map_pairs(common_neighbours, function (node, edge)
        return node, { edge, j_neighbours[node] }
      end)
      
      -- drop common nodes from the neighbour mappings
      i_neighbours = table.filter_keys(i_neighbours, function (node)
        return not common_neighbours[node]
      end)
      j_neighbours = table.filter_keys(j_neighbours, function (node)
        return not common_neighbours[node]
      end)

      -- debug stuff
      --Sys:log('WALSHAW: merge ' .. i.name .. ' and ' .. j.name)
      --Sys:log('WALSHAW:   neighbours of ' .. i.name)
      --for node, edge in pairs(i_neighbours) do
      --  Sys:log('WALSHAW:     ' .. node.name .. ' via ' .. tostring(edge))
      --end
      --Sys:log('WALSHAW:   neighbours of ' .. j.name)
      --for node, edge in pairs(j_neighbours) do
      --  Sys:log('WALSHAW:     ' .. node.name .. ' via ' .. tostring(edge))
      --end
      --Sys:log('WALSHAW:   common neighbours')
      --for node, edges in pairs(common_neighbours) do
      --  Sys:log('WALSHAW:     ' .. node.name .. ' via ' .. tostring(edges[1]) .. ' and ' .. tostring(edges[2]))
      --end

      -- merge neighbour lists
      disjoint_neighbours = table.custom_merge(i_neighbours, j_neighbours)

      -- create edges between the supernode and the neighbours of the
      -- merged nodes
      for k, edge in pairs(disjoint_neighbours) do
        local e_copy = Edge:new{direction = Edge.UNDIRECTED, weight = edge.weight}
        e_copy:addNode(v)
        e_copy:addNode(k)

        --Sys:log('WALSHAW:   create edge ' .. tostring(e_copy))
        coarse_graph:addEdge(e_copy)

        --Sys:log('WALSHAW:   delete edge ' .. tostring(edge))
        coarse_graph:deleteEdge(edge)
      end

      -- do the same for all neighbours that the merged nodes have 
      -- in common, except that the weights of the new edges becomes
      -- the sum of the weights of the edges to the common neighbours
      for k, edges in pairs(common_neighbours) do
        local weights = table.combine_values(edges, function (weights, edge)
          return weights + edge.weight
        end, 0)

        local e_copy = Edge:new{direction = Edge.UNDIRECTED, weight = weights}
        e_copy:addNode(v)
        e_copy:addNode(k)

        --Sys:log('WALSHAW:   create edge ' .. tostring(e_copy))
        coarse_graph:addEdge(e_copy)

        --Sys:log('WALSHAW:   delete edge ' .. tostring(edge))
        coarse_graph:deleteEdge(edge)
      end

      -- delete the nodes i, j which were replaced by v
      coarse_graph:deleteNode(i)
      coarse_graph:deleteNode(j)
    end

    --dump_current_graph(graphs)

    -- stop coarsening if the number of nodes of the new coarse
    -- graph divided by the number of nodes of its predecessor
    -- is less than the coarsening threshold 
    if (#coarse_graph.nodes / #parent_graph.nodes) > coarsening_threshold then
      --Sys:log('WALSHAW: stop coarsening after ' .. #graphs .. ' graphs\n')
      break
    end
  end

  return graphs
end



function walshaw_spring.dump_current_graph(graphs)
  local graph = graphs[#graphs]

  Sys:log('WALSHAW: coarse graph ' .. #graphs-1 .. ':')
  for node in table.value_iter(graph.nodes) do
    Sys:log('WALSHAW:   node ' .. node.name)
  end
  for edge in table.value_iter(graph.edges) do
    Sys:log('WALSHAW:   edge (' .. edge.nodes[1].name .. ', ' .. edge.nodes[2].name .. ')')
  end
  Sys:log('WALSHAW:  ')
end



function walshaw_spring.copy_graph(graph)
  local copy = graph:copy()
  for e in table.value_iter(graph.edges) do
    local u, v = e.nodes[1], e.nodes[2]

    if u and v then
      local u_copy = copy:findNodeIf(function (node)
        return node.name == u.name
      end) or Node:new{
        name = u.name, 
        weight = u.weight,
        pos = u.pos:copy(),
        fixed = u.fixed,
        subnodes = { u },
      }

      copy:addNode(u_copy)

      local v_copy = copy:findNodeIf(function (node)
        return node.name == v.name
      end) or Node:new{
        name = v.name, 
        weight = v.weight,
        pos = v.pos:copy(),
        fixed = v.fixed,
        subnodes = { v },
      }

      copy:addNode(v_copy)

      local e_copy = Edge:new{direction = Edge.UNDIRECTED, weight = e.weight}
      e_copy:addNode(u_copy)
      e_copy:addNode(v_copy)

      copy:addEdge(e_copy)
    end
  end
  return copy
end



function walshaw_spring.find_maximal_matching(graph)
  local matching = {}
  local matched_nodes = {}

  --Sys:log('WALSHAW: find maximum matching')

  for node in table.randomized_value_iter(graph.nodes) do
    if not matched_nodes[node] then
      --Sys:log('WALSHAW:   visit ' .. node.name)

      -- filter out edges adjacent to already matched neighbours
      local edges = table.filter_values(node.edges, function (edge) 
        local neighbour = edge:getNeighbour(node)
        return not matched_nodes[neighbour]
      end)

      -- sort edges by the weights of the neighbours
      table.sort(edges, function (a, b)
        local neighbour_a = a:getNeighbour(node)
        local neighbour_b = b:getNeighbour(node)
        return neighbour_a.weight < neighbour_b.weight
      end)

      --Sys:log('WALSHAW:     neighbours:')
      --for edge in table.value_iter(edges) do
      --  Sys:log('WALSHAW:       ' .. edge:getNeighbour(node).name .. ' via ' .. tostring(edge))
      --end
      
      -- mark the node as matched
      matched_nodes[node] = true

      if #edges > 0 then
        -- match the node against the neighbour with minimum weight
        local neighbour = edges[1]:getNeighbour(node)
        --Sys:log('WALSHAW:     match against ' .. neighbour.name .. ' via ' .. tostring(edges[1]))
        matched_nodes[neighbour] = true
        table.insert(matching, edges[1])
      end
    end
  end

  return matching
end



function walshaw_spring.compute_initial_layout(graph)
  -- TODO how can supernodes and fixated nodes go hand in hand? 
  -- maybe fix the supernode if at least one of its subnodes is 
  -- fixated?
  --
  -- fixate all nodes that have an 'at' option. this will set the
  -- node.fixed member to true and also set node.pos:x() and node.pos:y()
  walshaw_spring.fixate_nodes(graph)

  -- decide what technique to use for the initial layout
  local initial_positioning = graph:getOption('/graph drawing/spring layout/initial positioning') or 'random'
  local positioning_func = positioning.technique(initial_positioning, graph, graph.k)

  local function nodeNotFixed(node) return not node.fixed end

  -- compute initial layout based on the selected positioning technique
  --Sys:log('WALSHAW: initial layout:')
  for node in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
    node.pos:set{x = positioning_func(1), y = positioning_func(2)}
  end

  --for node in table.value_iter(graph.nodes) do
  --  Sys:log('WALSHAW:   ' .. node.name .. ' at ' .. tostring(node.pos))
  --end

  --Sys:log('WALSHAW: ')
end



function walshaw_spring.interpolate_from_parent(graph, parent_graph)
  graph.k = math.sqrt(4/7) * parent_graph.k

  --Sys:log('WALSHAW:   interpolate from parent')
  for supernode in table.value_iter(parent_graph.nodes) do
    --Sys:log('WALSHAW:     supernode ' .. supernode.name .. ' at ' .. tostring(supernode.pos))
    if supernode.subnodes then
      local subnode_str = table.concat(table.map_values(supernode.subnodes, function (node) return node.name end), ', ')
      --Sys:log('WALSHAW:       subnodes of ' .. supernode.name .. ' are: ' .. subnode_str)

      for node in table.value_iter(supernode.subnodes) do
        local original = table.find(graph.nodes, function (other) return other == node end)
        assert(original)
        original.pos:set{x = supernode.pos:x(), y = supernode.pos:y()}
      end
    else
      --Sys:log('WALSHAW:     ' .. supernode.name .. ' has no subnodes')
      local original = table.find(graph.nodes, function (node) return node == supernode end)
      assert(original)
      original.pos:set{x = supernode.pos:x(), y = supernode.pos:y()}
    end
  end

  for node in table.value_iter(graph.nodes) do
    --Sys:log('WALSHAW:       node ' .. node.name .. ' at ' .. tostring(node.pos))
  end

  --Sys:log('WALSHAW: ')
end



function walshaw_spring.compute_force_layout(graph, C, iterations, use_quadtree)
  --Sys:log('WALSHAW:   compute force based layout')

  for node in table.value_iter(graph.nodes) do
    -- set node displacement to 0
    node.disp = Vector:new(2, function (n) return 0 end)
  end

  -- global (repulsive) force function
  local function fg(distance, weight) 
    return -C * weight * (graph.k*graph.k) / distance
  end 

  -- repulsive quadtree force function
  local function quadtree_fg(distance, mass)
    return -mass * C * (graph.k*graph.k) / distance
  end

  -- local (spring) force function
  local function fl(distance, d, weight) 
    return ((distance - graph.k) / d) - fg(distance, weight) 
  end

  -- define the Barnes-Hut opening criterion
  function barnes_hut_criterion(cell, particle)
    local distance = particle.pos:minus(cell.centre_of_mass):norm()
    return cell.width / distance <= 1.2
  end

  -- cooling function
  local function cool(t) return 0.95 * t end

  -- tweakable parameters  
  local t = graph.k
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
      --Sys:setVerbose(true)
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
      --Sys:setVerbose(false)
    end

    local function nodeNotFixed(node) return not node.fixed end

    -- iterate over all nodes
    for v in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
      assert(not v.fixed)

      -- vector for the displacement of v
      local d = Vector:new(2)

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
              local delta = particle.pos:minus(v.pos)
              local delta_norm = delta:norm()
            
              -- enforce a small virtual distance if the node and the cell's 
              -- centre of mass are located at (almost) the same position
              if delta_norm < 0.1 then
                delta:update(function (n, value) return 0.1 + math.random() * 0.1 end)
                delta_norm = delta:norm()
              end

              -- compute the repulsive force vector
              local force = delta:normalized():timesScalar(quadtree_fg(delta_norm, particle.amount * particle.mass))

              -- move the node v accordingly
              d = d:plus(force)
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
            local force = delta:normalized():timesScalar(fg(delta_norm, u.weight))

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
        local force = delta:normalized():timesScalar(fl(delta_norm, #neighbours, u.weight))

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
      if (v.pos:minus(old_position):norm() > graph.k * tol) then
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



