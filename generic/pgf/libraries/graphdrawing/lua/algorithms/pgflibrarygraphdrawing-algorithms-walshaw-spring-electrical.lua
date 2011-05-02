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
function drawGraphAlgorithm_walshaw_spring_electrical(graph)
  -- apply the random seed specified by the user
  local seed = tonumber(graph:getOption('random seed') or 42)
  if seed == 0 then seed = os.time() end
  math.randomseed(seed)

  -- check if we should use the multilevel approach
  local use_coarsening = graph:getOption('coarsening') or false

  Sys:logMessage('use coarsening: ' .. tostring(use_coarsening))

  -- determine parameters for the algorithm
  local k = tonumber(graph:getOption('natural spring dimension') or 28.5)
  
  -- correct the factor K so that the resulting natural spring dimension
  -- really equals the desired value in the final drawing
  -- graph.k = 1.03 * graph.k

  if use_coarsening then
    -- compute coarsened graphs (this could be done on-demand instead
    -- of computing all graphs at once to reduce memory usage)
    local graphs = compute_coarse_graphs(graph)

    for i = #graphs,1,-1 do
      Sys:logMessage('lay out coarse graph ' .. i-1)

      if i == #graphs then
        graphs[i].k = k * #graphs
        compute_initial_layout(graphs[i])
      else
        interpolate_from_parent(graphs[i], graphs[i+1])
        compute_force_layout(graphs[i])
        -- 1. interpolate from parent coarse graph
        -- 2. perform force based layout
      end

      Sys:logMessage(' ')
    end
  else
    -- directly compute the force-based layout for the input graph
    graph.k = k
    compute_force_layout(graph)
  end

  -- adjust orientation
  -- TODO make sure that orientation will not generate NANs
  --orientation.adjust(graph)
end


function compute_coarse_graphs(graph)
  -- determine parameters for the algorithm
  local minimum_graph_size = tonumber(graph:getOption('minimum coarsened graph size') or 2)

  -- set weights to 1 unless specified otherwise
  for node in table.value_iter(graph.nodes) do
    node.weight = tonumber(node:getOption('node weight') or 1)
  end
  for edge in table.value_iter(graph.edges) do
    edge.weight = tonumber(edge:getOption('edge weight') or 1)
  end

  -- compute iteratively coarsened graphs
  local graphs = { graph }
  dump_current_graph(graphs)

  while #graphs[#graphs].nodes > minimum_graph_size do
    local parent_graph = graphs[#graphs]

    -- copy the parent graph
    local coarse_graph = copy_graph(parent_graph)
    table.insert(graphs, coarse_graph)

    -- approximate a maximum matching using a greedy heuristic
    local matching_edges = find_maximum_matching(coarse_graph)

    for edge in table.value_iter(matching_edges) do
      --Sys:logMessage('contracting edge ' .. tostring(edge))

      -- get the two nodes of the matching edge that we are about to contract
      local i, j = edge.nodes[1], edge.nodes[2]

      -- create a supernode v
      local v = Node:new{ name = 'not yet positioned@' .. i:shortname() .. ':' .. j:shortname() }
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
      -- TODO what to do about loops?
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
      --Sys:logMessage('merge ' .. i:shortname() .. ' and ' .. j:shortname())
      --Sys:logMessage('  neighbours of ' .. i:shortname())
      --for node, edge in pairs(i_neighbours) do
      --  Sys:logMessage('    ' .. node:shortname() .. ' via ' .. tostring(edge))
      --end
      --Sys:logMessage('  neighbours of ' .. j:shortname())
      --for node, edge in pairs(j_neighbours) do
      --  Sys:logMessage('    ' .. node:shortname() .. ' via ' .. tostring(edge))
      --end
      --Sys:logMessage('  common neighbours')
      --for node, edges in pairs(common_neighbours) do
      --  Sys:logMessage('    ' .. node:shortname() .. ' via ' .. tostring(edges[1]) .. ' and ' .. tostring(edges[2]))
      --end

      -- merge neighbour lists
      disjoint_neighbours = table.merge(i_neighbours, j_neighbours)

      -- create edges between the supernode and the neighbours of the
      -- merged nodes
      for k, edge in pairs(disjoint_neighbours) do
        local e_copy = Edge:new{direction = Edge.UNDIRECTED, weight = edge.weight}
        e_copy:addNode(v)
        e_copy:addNode(k)

        --Sys:logMessage('  create edge ' .. tostring(e_copy))
        coarse_graph:addEdge(e_copy)

        --Sys:logMessage('  delete edge ' .. tostring(edge))
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

        --Sys:logMessage('  create edge ' .. tostring(e_copy))
        coarse_graph:addEdge(e_copy)

        --Sys:logMessage('  delete edge ' .. tostring(edge))
        coarse_graph:deleteEdge(edge)
      end

      -- delete the nodes i, j which were replaced by v
      coarse_graph:deleteNode(i)
      coarse_graph:deleteNode(j)
    end

    dump_current_graph(graphs)
  end

  return graphs
end



function dump_current_graph(graphs)
  local graph = graphs[#graphs]

  Sys:logMessage('coarse graph ' .. #graphs-1 .. ':')
  for node in table.value_iter(graph.nodes) do
    Sys:logMessage('  node ' .. node:shortname())
  end
  for edge in table.value_iter(graph.edges) do
    Sys:logMessage('  edge (' .. edge.nodes[1]:shortname() .. ', ' .. edge.nodes[2]:shortname() .. ')')
  end
  Sys:logMessage(' ')
end



function copy_graph(graph)
  local copy = graph:copy()
  for e in table.value_iter(graph.edges) do
    local u, v = e.nodes[1], e.nodes[2]

    local u_copy = copy:findNodeIf(function (node)
      return node.name == u.name
    end) or Node:new{
      name = u.name, 
      weight = u.weight,
      pos = u.pos,
      position = u.position,
      fixed = u.fixed,
      subnodes = u.subnodes,
    }

    copy:addNode(u_copy)

    local v_copy = copy:findNodeIf(function (node)
      return node.name == v.name
    end) or Node:new{
      name = v.name, 
      weight = v.weight,
      pos = v.pos,
      position = v.position,
      fixed = v.fixed
    }

    copy:addNode(v_copy)

    local e_copy = Edge:new{direction = Edge.UNDIRECTED, weight = e.weight}
    e_copy:addNode(u_copy)
    e_copy:addNode(v_copy)

    copy:addEdge(e_copy)
  end
  return copy
end



function find_maximum_matching(graph)
  -- TODO problem here: due to the use of pairs() the algorithm is 
  -- randomized in a fashion that we cannot control with our seed (I
  -- think). Probably better to use a depth-first search here or 
  -- implement the randomized access ourselves...

  local matching = {}
  local matched_nodes = {}

  --Sys:logMessage('find maximum matching')

  for node in table.value_iter(graph.nodes) do
    if not matched_nodes[node] then
      --Sys:logMessage('  visit ' .. node:shortname())

      local neighbours = table.map_pairs(node.edges, function (n, edge)
        return edge:getNeighbour(node), edge
      end)

      --Sys:logMessage('    neighbours:')
      --for node, edge in pairs(neighbours) do
      --  Sys:logMessage('      ' .. node:shortname() .. ' via ' .. tostring(edge))
      --end

      local unmatched = table.filter_keys(neighbours, function (node)
        return not matched_nodes[node]
      end)

      --Sys:logMessage('    unmatched neighbours:')
      --for node, edge in pairs(unmatched) do
      --  Sys:logMessage('      ' .. node:shortname() .. ' via ' .. tostring(edge))
      --end
      
      local next_func = pairs(unmatched)
      local neighbour, edge = next_func(unmatched)

      assert(neighbour or not edge)

      matched_nodes[node] = true
      if neighbour and edge then
        --Sys:logMessage('    match against ' .. neighbour:shortname() .. ' via ' .. tostring(edge))
        matched_nodes[neighbour] = true
        table.insert(matching, edge)
      end
    end
  end

  return matching
end



function compute_initial_layout(graph)
  -- TODO how can supernodes and fixated nodes go hand in hand? 
  -- maybe fix the supernode if at least one of its subnodes is 
  -- fixated?
  --
  -- fixate all nodes that have an 'at' option. this will set the
  -- node.fixed member to true and also set node.pos.x and node.pos.y
  fixate_nodes(graph)

  -- decide what technique to use for the initial layout
  local initial_positioning = graph:getOption('initial positioning') or 'random'
  local positioning_func = positioning.technique(initial_positioning, graph, graph.k)

  -- compute initial layout based on the selected positioning technique
  Sys:logMessage('initial layout:')
  for node in table.value_iter(graph.nodes) do
    node.position = Vector:new(2, function (n)
      if node.fixed then
        local pos = { node.pos.x, node.pos.y }
        return pos[n]
      else
        return positioning_func(n)
      end
    end)
  end

  -- apply node positions
  for node in table.value_iter(graph.nodes) do
    node.pos.x = node.position:x()
    node.pos.y = node.position:y()
    Sys:logMessage('  ' .. node:shortname() .. ' at (' .. node.pos.x .. ', ' .. node.pos.y .. ')')
  end
end



function interpolate_from_parent(graph, parent_graph)
  graph.k = math.sqrt(4/7) * parent_graph.k

  Sys:logMessage('interpolate from parent:')
  for supernode in table.value_iter(parent_graph.nodes) do
    Sys:logMessage('  supernode ' .. supernode:shortname() .. ' at (' .. supernode.pos.x .. ', ' .. supernode.pos.y .. ')')
    if supernode.subnodes then
      local subnode_str = table.concat(table.map_values(supernode.subnodes, 
        function (node) return node:shortname() end), ', ')

      Sys:logMessage('    subnodes of ' .. supernode:shortname() .. ' are: ' .. subnode_str)

      for node in table.value_iter(supernode.subnodes) do
        node.pos.x = supernode.pos.x
        node.pos.y = supernode.pos.y
        Sys:logMessage('    node ' .. node:shortname() .. ' at ( ' .. node.pos.x .. ', ' .. node.pos.y .. ')')
      end
    else
      Sys:logMessage('  ' .. supernode:shortname() .. ' has no subnodes')
    end
  end
end



function compute_force_layout(graph, parent_graph)
  -- determine parameters for the algorithm
  local C = tonumber(graph:getOption('FOO BAR BAZ') or 0.01)
  local iterations = tonumber(graph:getOption('maximum iterations') or 500)

  for node in table.value_iter(graph.nodes) do
    -- convert node position to a vector
    local pos = { node.pos.x, node.pos.y }
    node.position = Vector:new(2, function (n)
      return pos[n]
    end)

    -- set node displacement to 0
    node.disp = Vector:new(2, function (n) return 0 end)
  end

  -- global (repulsive) force function
  local function fg(distance, weight) 
    return -C * weight * (graph.k*graph.k) / distance
  end 

  -- local (spring) force function
  local function fl(distance, d, weight) 
    return ((distance - graph.k) / d) - fg(distance, weight) 
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
    -- assume that we are converging
    converged = true
    i = i + 1

    local function nodeNotFixed(node) return not node.fixed end

    -- iterate over all nodes
    for v in iter.filter(table.value_iter(graph.nodes), nodeNotFixed) do
      assert(not v.fixed)

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

          --Sys:logMessage(v:shortname() .. ' vs. ' .. u:shortname() .. ' >=< ' .. tostring(force))

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

        --Sys:logMessage(v:shortname() .. ' and ' .. u:shortname() .. ' <=> ' .. tostring(force))

        -- move the node v accordingly
        d = d:plus(force)
      end

      --Sys:logMessage('total force of ' .. v:shortname() .. ': ' .. tostring(d))

      -- remember the previous position of v
      old_position = v.position:copy()

      if d:norm() > 0 then
        -- reposition v according to the force vector and the current temperature
        v.position = v.position:plus(d:normalized():timesScalar(math.min(t, d:norm())))
      end

      -- we need to improve the system energy as long as any of
      -- the node movements is large enough to assume we're far
      -- away from the minimum system energy
      if (v.position:minus(old_position):norm() > graph.k * tol) then
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
end



--- Fixes nodes at their specified positions.
--
function fixate_nodes(graph)
  for node in table.value_iter(graph.nodes) do
    if node:getOption('at') then
      node.pos.x, node.pos.y = parse_at_option(node)
      node.fixed = true
    end
  end
end



--- Parses the at option of a node.
--
function parse_at_option(node)
  local x, y = node:getOption('at'):gmatch('{([%d.-]+)}{([%d.-]+)}')()
  return tonumber(x), tonumber(y)
end



