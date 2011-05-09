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



CoarseGraph = Graph:new{}
CoarseGraph.__index = CoarseGraph



CoarseGraph.COARSEN_INDEPENDENT_EDGES = 0
CoarseGraph.COARSEN_INDEPENDENT_NODES = 1
CoarseGraph.COARSEN_HYBRID = 2



--- Creates a new coarse graph derived from an existing graph.
--
-- Generates a coarse graph for the input |Graph|. 
--
-- Coarsening describes the process of reducing the amount of nodes in a graph 
-- by merging nodes into supernodes. There are different strategies, called 
-- schemes, that can be applied, like merging nodes that belong to edges in a 
-- maximal independent edge set or by creating supernodes based on a maximal 
-- independent node set.
--
-- Coarsening is not performed automatically. The functions |CoarseGraph:coarsen|
-- and |CoarseGraph:interpolate| can be used to further coarsen the graph or
-- to restore the previous state (while interpolating the node positions from
-- the coarser version of the graph).
--
-- Note, however, that the input \meta{graph} is always modified in-place, so
-- if the original version of \meta{graph} is needed in parallel to its 
-- coarse representations, a deep copy of \meta{grpah} needs to be passed over
-- to |CoarseGraph:new|.
--
-- @param graph  An existing graph that needs to be coarsened.
-- @param scheme Coarsening scheme to use. Possible values are:\par
--               |CoarseGraph.COARSEN_INDEPENDENT_EDGES|: 
--                 Coarsen the input graph by computing a maximal independent edge set
--                 and collapsing edges from this set. The resulting coarse graph has
--                 at least 50% of the nodes of the input graph. This coarsening scheme
--                 gives slightly better results than 
--                 |CoarseGraph.COARSEN_INDEPENDENT_NODES| because it is less aggressive.
--                 However, this comes at higher computational cost.\par
--               |CoarseGraph.COARSEN_INDEPENDENT_NODES|:
--                 Coarsen the input graph by computing a maximal independent node set,
--                 making nodes from this set supernodes in the coarse graph, merging
--                 adjacent nodes into the supernodes and connecting the supernodes 
--                 if their grpah distance is no greater than three. This scheme gives
--                 slightly worse results than |CoarseGraph.COARSEN_INDEPENDENT_EDGES|
--                 but is computationally more efficient.\par
--               |CoarseGraph.COARSEN_HYBRID|: Combines the other schemes by starting
--                 with |CoarseGraph.COARSEN_INDEPENDENT_EDGES| and switching to 
--                 |CoarseGraph.COARSEN_INDEPENDENT_NODES| as soon as the first scheme
--                 does not reduce the amount of nodes by a factor of 25%.
--
function CoarseGraph:new(graph, scheme)
  local coarse_graph = {
    graph = graph,
    level = 0,
    scheme = scheme or CoarseGraph.COARSEN_INDEPENDENT_EDGES,
    ratio = 0,
  }
  setmetatable(coarse_graph, CoarseGraph)
  return coarse_graph
end



function CoarseGraph:coarsen()
  local old_graph_size = #self.graph.nodes

  if self.scheme == CoarseGraph.COARSEN_INDEPENDENT_EDGES then
    local matching, unmatched_nodes = self:findMaximalMatching()

    for edge in table.value_iter(matching) do
      -- get the two nodes of the edge that we are about to collapse
      local u, v = edge.nodes[1], edge.nodes[2]

      -- create a supernode
      local supernode = Node:new{
        name = u.name .. ':' .. v.name,
        weight = u.weight + v.weight,
        subnodes = { u, v },
        subnode_edge = edge,
        level = self.level,
      }

      -- add the supernode to the graph
      self.graph:addNode(supernode)

      --Sys:log('      contract edge ' .. u.name .. ' ' .. edge.direction .. ' ' .. v.name .. ' and create node ' .. supernode.name)

      -- collact all neighbours of the nodes to merge, create a node -> edge mapping
      local u_neighbours = table.map_pairs(u.edges, function (n, edge)
        return edge:getNeighbour(u), edge
      end)
      local v_neighbours = table.map_pairs(v.edges, function(n, edge)
        return edge:getNeighbour(v), edge
      end)

      -- remove the two nodes themselves from the neighbour lists
      u_neighbours = table.filter_keys(u_neighbours, function (node)
        return node ~= v
      end)
      v_neighbours = table.filter_keys(v_neighbours, function (node) 
        return node ~= u 
      end)

      -- compute a list of neighbours u and v have in common
      local common_neighbours = table.filter_keys(u_neighbours, function (node)
        return v_neighbours[node] ~= nil
      end)

      -- create a node -> edges mapping for common neighbours
      common_neighbours = table.map_pairs(common_neighbours, function (node, edge)
        return node, { edge, v_neighbours[node] }
      end)

      -- drop common edges from the neighbour mappings
      u_neighbours = table.filter_keys(u_neighbours, function (node)
        return not common_neighbours[node]
      end)
      v_neighbours = table.filter_keys(v_neighbours, function (node)
        return not common_neighbours[node]
      end)

      --Sys:log('      neighbours of ' .. u.name .. ':')
      --for node in table.key_iter(u_neighbours) do
      --  Sys:log('        ' .. node.name .. ' u_neighbours[' .. node.name .. '] = ' .. tostring(u_neighbours[node]))
      --end
      --Sys:log('      neighbours of ' .. v.name .. ':')
      --for node in table.key_iter(v_neighbours) do
      --  Sys:log('        ' .. node.name .. ' u_neighbours[' .. node.name .. '] = ' .. tostring(u_neighbours[node]))
      --end
      --Sys:log('      common neighbours of ' .. u.name .. ' and ' .. v.name .. ':')
      --for node in table.key_iter(common_neighbours) do
      --  Sys:log('        ' .. node.name)
      --end

      -- merge neighbour lists
      local disjoint_neighbours = table.custom_merge(u_neighbours, v_neighbours)

      -- create edges between the supernode and the neighbours of the merged nodes
      for neighbour, edge in pairs(disjoint_neighbours) do
        -- create a superedge to replace the existing one
        local superedge = Edge:new{
          direction = u_neighbours[neighbour] and Edge.RIGHT or Edge.LEFT,
          weight = edge.weight,
          subedges = { edge },
        }

        -- add the supernode and the neighbour to the edge
        if u_neighbours[neighbour] then
          --Sys:log('        create edge ' .. neighbour.name .. ' ' .. superedge.direction .. ' ' .. supernode.name)

          superedge:addNode(neighbour)
          superedge:addNode(supernode)
        else
          --Sys:log('        create edge ' .. neighbour.name .. ' ' .. superedge.direction .. ' ' .. supernode.name)

          superedge:addNode(neighbour)
          superedge:addNode(supernode)
        end

        --Sys:log('        delete edge ' .. edge.nodes[1].name .. ' ' .. edge.direction .. ' ' .. edge.nodes[2].name)

        -- replace the old edge
        self.graph:addEdge(superedge)
        self.graph:deleteEdge(edge)
      end

      -- do the same for all neighbours that the merged nodes have
      -- in common, except that the weights of the new edges are the
      -- sums of the of the weights of the edges to the common neighbours
      for neighbour, edges in pairs(common_neighbours) do
        local weights = table.combine_values(edges, function (weights, edge)
          return weights + edge.weight
        end, 0)

        local superedge = Edge:new{
          direction = Edge.UNDIRECTED,
          weight = weights,
          subedges = edges,
        }

        -- add the supernode and the neighbour to the edge
        superedge:addNode(supernode)
        superedge:addNode(neighbour)

        -- replace the old edges
        self.graph:addEdge(superedge)
        for edge in table.value_iter(edges) do
          self.graph:deleteEdge(edge)
        end
      end

      -- delete the nodes u and v which were replaced by the supernode
      assert(#u.edges == 1)
      assert(#v.edges == 1)
      self.graph:deleteNode(u)
      self.graph:deleteNode(v)
    end
  else
    assert(false, 'schemes other than CoarseGraph.COARSEN_INDEPENDENT_EDGES are not implemented yet')
  end

  -- calculate the number of nodes ratio compared to the previous graph
  self.ratio = #self.graph.nodes / old_graph_size
  
  -- update the level
  self.level = self.level + 1
end



function CoarseGraph:interpolate()
  local edges = table.map_values(self.graph.edges, function (e) return e end)
  local nodes = table.map_values(self.graph.nodes, function (n) return n end)

  for node in table.value_iter(nodes) do
    if node.level == self.level-1 then
      --Sys:log('      split up supernode ' .. node.name)
      --Sys:log('        create node u = ' .. node.subnodes[1].name)
      --Sys:log('        create node v = ' .. node.subnodes[2].name)

      node.subnodes[1].pos:set{x = node.pos:x(), y = node.pos:y()}

      self.graph:addNode(node.subnodes[1])
      self.graph:addNode(node.subnodes[2])

      --Sys:log('        create edge ' .. node.subnode_edge.nodes[1].name .. ' ' .. node.subnode_edge.direction .. ' ' .. node.subnode_edge.nodes[2].name)

      node.subnodes[1]:addEdge(node.subnode_edge)
      node.subnodes[2]:addEdge(node.subnode_edge)

      self.graph:addEdge(node.subnode_edge)

      local edges = table.map_values(node.edges, function (e) return e end)
      for edge in table.value_iter(edges) do
        --Sys:log('        update edge ' .. edge.nodes[1].name .. ' ' .. edge.direction .. ' ' .. edge.nodes[2].name)
        if edge.direction == Edge.RIGHT then
          --Sys:log('          create node ' .. edge.subedges[1].nodes[1].name)
          --Sys:log('          create node ' .. edge.subedges[1].nodes[2].name)

          self.graph:addNode(edge.subedges[1].nodes[1])
          self.graph:addNode(edge.subedges[1].nodes[2])

          --Sys:log('          create edge ' .. edge.subedges[1].nodes[1].name .. ' ' .. edge.subedges[1].direction .. ' ' .. edge.subedges[1].nodes[2].name)

          edge.subedges[1].nodes[1]:addEdge(edge.subedges[1])
          edge.subedges[1].nodes[2]:addEdge(edge.subedges[1])

          self.graph:addEdge(edge.subedges[1])
        elseif edge.direction == Edge.LEFT then
          --Sys:log('          create node ' .. edge.subedges[1].nodes[1].name)
          --Sys:log('          create node ' .. edge.subedges[1].nodes[2].name)

          self.graph:addNode(edge.subedges[1].nodes[1])
          self.graph:addNode(edge.subedges[1].nodes[2])

          --Sys:log('          create edge ' .. edge.subedges[1].nodes[1].name .. ' ' .. edge.subedges[1].direction .. ' ' .. edge.subedges[1].nodes[2].name)

          edge.subedges[1].nodes[1]:addEdge(edge.subedges[1])
          edge.subedges[1].nodes[2]:addEdge(edge.subedges[1])

          self.graph:addEdge(edge.subedges[1])
        else
          local subedges = table.map_values(edge.subedges, function (e) return e end)
          for subedge in table.value_iter(subedges) do
            --Sys:log('          create node ' .. subedge.nodes[1].name)
            --Sys:log('          create node ' .. subedge.nodes[2].name)

            self.graph:addNode(subedge.nodes[1])
            self.graph:addNode(subedge.nodes[2])

            --Sys:log('          create edge ' .. subedge.nodes[1].name .. ' ' .. subedge.direction .. ' ' .. subedge.nodes[2].name)

            subedge.nodes[1]:addEdge(subedge)
            subedge.nodes[2]:addEdge(subedge)

            self.graph:addEdge(subedge)
          end
        end
      end

      self.graph:deleteNode(node)
    end
  end

--  for edge in table.value_iter(edges) do
--    if edge.subedges then
--      Sys:log('      split up edge ' .. edge.nodes[1].name .. ' to ' .. edge.nodes[2].name)
--      for subedge in table.value_iter(edge.subedges) do
--        Sys:log('        create node ' .. subedge.nodes[1].name)
--        Sys:log('        create node ' .. subedge.nodes[2].name)
--
--        self.graph:addNode(subedge.nodes[1])
--        self.graph:addNode(subedge.nodes[2])
--
--        Sys:log('        create edge ' .. subedge.nodes[1].name .. ' to ' .. subedge.nodes[2].name)
--
--        subedge.nodes[1]:addEdge(subedge)
--        subedge.nodes[2]:addEdge(subedge)
--
--        self.graph:addEdge(subedge)
--      end
--
--      Sys:log('        delete edge ' .. edge.nodes[1].name .. ' to ' .. edge.nodes[2].name)
--
--      self.graph:deleteEdge(edge)
--    end
--  end

  --for node in table.value_iter(nodes) do
  --  if node.level == self.level-1 then
  --    Sys:log('      split up node ' .. node.name)

  --    Sys:log('        create node ' .. node.subnodes[1].name)
  --    Sys:log('        create node ' .. node.subnodes[2].name)

  --    self.graph:addNode(node.subnodes[1])
  --    self.graph:addNode(node.subnodes[2])

  --    Sys:log('        create edge ' .. node.subnode_edge.nodes[1].name .. ' to ' .. node.subnode_edge.nodes[2].name)

  --    node.subnode_edge.nodes[1]:addEdge(node.subnode_edge)
  --    node.subnode_edge.nodes[2]:addEdge(node.subnode_edge)

  --    self.graph:addEdge(node.subnode_edge)
  --    
  --    Sys:log('        number of incoming/outgoing edges: ' .. #node.edges)
  --    local edges = table.map_values(node.edges, function (e) return e end)

  --    for edge in table.value_iter(edges) do
  --      Sys:log('        split up edge ' .. edge.nodes[1].name .. ' to ' .. edge.nodes[2].name)

  --      if edge.nodes[1] == node then
  --        Sys:log('          create edge ' .. node.subnodes[1].name .. ' to ' .. edge.nodes[2].name)

  --        local edge_copy = Edge:copy()
  --        edge_copy:addNode(node.subnodes[1])
  --        edge_copy:addNode(edge.nodes[2])
  --        self.graph:addEdge(edge_copy)

  --        Sys:log('          create edge ' .. node.subnodes[2].name .. ' to ' .. edge.nodes[2].name)

  --        local edge_copy = Edge:copy()
  --        edge_copy:addNode(node.subnodes[2])
  --        edge_copy:addNode(edge.nodes[2])
  --        self.graph:addEdge(edge_copy)
  --      else
  --        Sys:log('          create edge ' .. edge.nodes[1].name .. ' to ' .. node.subnodes[1].name)

  --        local edge_copy = Edge:copy()
  --        edge_copy:addNode(edge.nodes[1])
  --        edge_copy:addNode(node.subnodes[1])
  --        self.graph:addEdge(edge_copy)

  --        Sys:log('          create edge ' .. edge.nodes[1].name .. ' to ' .. node.subnodes[2].name)

  --        local edge_copy = Edge:copy()
  --        edge_copy:addNode(edge.nodes[1])
  --        edge_copy:addNode(node.subnodes[2])
  --        self.graph:addEdge(edge_copy)
  --      end

  --      Sys:log('          delete edge ' .. edge.nodes[1].name .. ' to ' .. edge.nodes[2].name)
  --    end

  --    Sys:log('        delete node ' .. node.name)

  --    self.graph:deleteNode(node)
  --  end
  --end

  -- update the level
  self.level = self.level - 1
end



function CoarseGraph:getSize()
  return #self.graph.nodes
end



function CoarseGraph:getRatio()
  return self.ratio
end



function CoarseGraph:getLevel()
  return self.level
end



function CoarseGraph:getGraph()
  return self.graph
end



function CoarseGraph:findMaximalMatching()
  local matching = {}
  local matched_nodes = {}
  local unmatched_nodes = {}

  -- iterate over nodes in random order
  for node in table.randomized_value_iter(self.graph.nodes) do
    -- ignore nodes that have already been matched
    if not matched_nodes[node] then
      -- mark the node as matched
      matched_nodes[node] = true

      -- filter out edges adjacent to neighbours already matched
      local edges = table.filter_values(node.edges, function (edge)
        return not matched_nodes[edge:getNeighbour(node)]
      end)

      if #edges > 0 then
        -- sort edges bby the weights of the node's neighbours
        table.sort(edges, function (a, b)
          return a:getNeighbour(node).weight < b:getNeighbour(node).weight
        end)

        -- match the node against the neighbour with minimum weight
        matched_nodes[edges[1]:getNeighbour(node)] = true
        table.insert(matching, edges[1])
      end
    end
  end

  -- generate a list of nodes that were not matched at all
  for node in table.randomized_value_iter(self.graph.nodes) do
    if not matched_nodes[node] then
      table.insert(unmatched_nodes, node)
    end
  end

  return matching, unmatched_nodes
end
