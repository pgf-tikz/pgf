-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file contains an implementation of the network simplex method
--- for node ranking and x coordinate optimization in layered drawing 
--- algorithms.

pgf.module("pgf.graphdrawing")



NetworkSimplex = {}
NetworkSimplex.__index = NetworkSimplex



function NetworkSimplex:new(graph)
  local simplex = {
    graph = graph,
  }
  setmetatable(simplex, NetworkSimplex)
  return simplex
end



function NetworkSimplex:run()
  -- initialize the tree edge search index
  self.search_index = 1

  -- initialize internal edge parameters
  self.cut_value = {}
  self.tree_index = {}
  for edge in table.value_iter(self.graph.edges) do
    self.cut_value[edge] = 0
    self.tree_index[edge] = -1
  end

  -- initialize internal node parameters
  self.marked = {}
  for node in table.value_iter(self.graph.nodes) do
    self.marked[node] = false
  end

  -- reset tight, feasible spanning tree
  self.tree = nil
  self.tree_edge = {}
  self.orig_edge = {}
  self.tree_node = {}
  self.orig_node = {}

  -- reset graph information needed for ranking
  self.lim = {}
  self.low = {}
  self.parent_edge = {}
  self.ranking = Ranking:new()

  self:rankNodes()
end



function NetworkSimplex:rankNodes()
  -- construct feasible tree of tight edges
  self:constructFeasibleTree()

  -- iteratively replace edges with negative cut values 
  -- with non-tree edges (chosen by minimum slack)
  local leave_edge = self:findNegativeCutEdge()
  while leave_edge do
    local enter_edge = self:findReplacementEdge(leave_edge)
    
    assert(enter_edge, 'no non-tree edge to replace ' .. tostring(edge) .. ' could be found')

    Sys:log('replace negative cut edge ' .. tostring(leave_edge) .. ' with ' .. tostring(enter_edge))
    dump_tree(self.tree, 'tree before replacing edges')
    self:dumpRanking('', 'ranking before replacing edges')

    -- exchange leave_edge and enter_edge in the tree, updating
    -- the ranks and cut values of all nodes
    self:exchangeTreeEdges(leave_edge, enter_edge)
    
    dump_tree(self.tree, 'tree after replacing edges')
    self:dumpRanking('', 'ranking after replacing edges')

    -- find the next tree edge with a negative cut value, if 
    -- there are any left
    leave_edge = self:findNegativeCutEdge()
  end

  -- move nodes to feasible ranks with the least number of nodes
  -- in order to avoid crowding and to improve the overall aspect 
  -- ratio of the drawing
  self:balanceRanks()

  -- normalize by setting the least rank to zero
  self.ranking:normalizeRanks()

  self:dumpRanking('', 'ranking after normalization')
end



function NetworkSimplex:constructFeasibleTree()
  self:computeInitialRanking()

  dump_tree(self.graph, 'input graph')
  self:dumpRanking('', 'initial ranking')

  -- find a maximal tree of tight edges in the graph
  self.tree = self:findTightTree()
  while #self.tree.nodes < #self.graph.nodes do
    dump_tree(self.tree, 'incomplete feasible tree')

    Sys:log('find non-tree edge with minimal slack:')

    for node in table.value_iter(self.graph.nodes) do
      local out_edges = node:getOutgoingEdges()
      for edge in table.value_iter(out_edges) do
        --Sys:log('  check if ' .. tostring(edge) .. ' is incident to the tree')
        if self:isIncidentToTree(edge) then
          --Sys:log('    it is')
          if not min_slack_edge or self:edgeSlack(edge) < self:edgeSlack(min_slack_edge) then
            min_slack_edge = edge
          end
        end
      end
    end

    Sys:log('  edge with minimal slack: ' .. tostring(min_slack_edge))

    if min_slack_edge then
      local delta = self:edgeSlack(min_slack_edge)

      if delta > 0 then
        local head = min_slack_edge:getHead()
        local tail = min_slack_edge:getTail()

        if self.tree_node[head] then
          delta = -delta
        end

        Sys:log('  delta = ' .. delta)

        for node in table.value_iter(self.tree.nodes) do
          local rank = self.ranking:getRank(self.orig_node[node])
          Sys:log('  set rank of ' .. node.name .. ' from ' .. rank .. ' to ' .. rank + delta)
          self.ranking:setRank(self.orig_node[node], rank + delta)
        end

        self.ranking:normalizeRanks()
      end
    end

    self.tree = self:findTightTree()
    
    dump_tree(self.tree, 'feasible tree after making ' .. tostring(min_slack_edge) .. ' tight')
    Sys:log('  minimal slack edge ' .. tostring(min_slack_edge) .. ' has slack ' .. self:edgeSlack(min_slack_edge) .. ' now')
    self:dumpRanking('', 'ranking after adding ' .. tostring(min_slack_edge) .. ' to the tree')
  end

  self:initializeCutValues()
end



function NetworkSimplex:findNegativeCutEdge()
  local minimum_edge = nil

  for n in iter.times(#self.tree.edges) do
    local index = self:nextSearchIndex()

    local edge = self.tree.edges[index]

    if self.cut_value[edge] < 0 then
      if minimum_edge then
        if self.cut_value[minimum_edge] > self.cut_value[edge] then
          minimum_edge = edge
        end
      else
        minimum_edge = edge
      end
    end
  end

  return minimum_edge
end



function NetworkSimplex:findReplacementEdge(leave_edge)
  local head = leave_edge:getHead()
  local tail = leave_edge:getTail()
  local v = nil
  local outsearch = false

  --Sys:log('find replacement edge for ' .. tostring(leave_edge))

  if self.lim[tail] < self.lim[head] then
    v = tail
    outsearch = false
  else
    v = head
    outsearch = true
  end

  local enter_edge = nil

  local stack = {}
  local direction_stack = {}

  local function push(node, direction)
    table.insert(stack, node)
    table.insert(direction_stack, direction)
  end

  local function pop()
    return table.remove(stack), table.remove(direction_stack)
  end

  push(v, 'out')

  while #stack > 0 do
    local node, direction = pop()
    --Sys:log('  visit ' .. node.name .. ', direction ' .. direction)

    if direction == 'out' then
      local out_edges = self.orig_node[node]:getOutgoingEdges()

      for edge in table.value_iter(out_edges) do
        local edge_head = edge:getHead()

        if not self.tree_edge[edge] then
          if not self:inTailComponentOf(self.tree_node[edge_head], v) then
            local slack = self:edgeSlack(edge)
            if not enter_edge or slack < self:edgeSlack(enter_edge) then
              enter_edge = edge
            end
          end
        else
          local edge_tail = edge:getTail(edge)
          if self.lim[self.tree_node[edge_tail]] < self.lim[node] then
            push(self.tree_node[edge_tail], 'in')
          end
        end
      end
    else
      --Sys:log('  TODO handle \'in\' direction')
    end
  end

  return enter_edge
end



function NetworkSimplex:exchangeTreeEdges(leave_edge, enter_edge)
  Sys:log('exchange tree edge ' .. tostring(leave_edge) .. ' with ' .. tostring(enter_edge))

  self:rerankBeforeReplacingEdge(leave_edge, enter_edge)

  local cutval = self.cut_value[leave_edge]
  local head = self.tree_node[enter_edge:getHead()]
  local tail = self.tree_node[enter_edge:getTail()]
  
  local ancestor = self:updateCutValuesUpToCommonAncestor(tail, head, cutval, true)
  local other_ancestor = self:updateCutValuesUpToCommonAncestor(head, tail, cutval, false)

  assert(ancestor == other_ancestor)

  self.tree:deleteEdge(leave_edge)

  local edge_copy = enter_edge:copy()
  self.orig_edge[edge_copy] = enter_edge
  self.tree_edge[enter_edge] = edge_copy
  self.cut_value[edge_copy] = -cutval

  for node in table.value_iter(enter_edge.nodes) do
    local node_copy 
    
    if self.tree_node[node] then
      node_copy = self.tree_node[node]
    else
      node_copy = node:copy()
      self.orig_node[node_copy] = node
      self.tree_node[node] = node_copy
    end

    self.tree:addNode(node_copy)
    edge_copy:addNode(node_copy)
  end

  self.tree:addEdge(edge_copy)

  self:calculateDFSRange(ancestor, self.parent_edge[ancestor], self.low[ancestor])
end



function NetworkSimplex:balanceRanks()
  Sys:log('balancing the ranks:')

  -- node to in/out weight mappings
  local in_weight = {}
  local out_weight = {}
  
  -- node to lowest/highest possible rank mapping
  local min_rank = {}
  local max_rank = {}

  -- compute the in and out weights of each node
  for node in table.value_iter(self.graph.nodes) do
    -- assume there are no restrictions on how to rank the node
    min_rank[node], max_rank[node] = self.ranking:getRankRange()

    for edge in table.value_iter(node:getIncomingEdges()) do
      -- accumulate the weights of all incoming edges
      in_weight[node] = (in_weight[node] or 0) + edge.weight
      
      -- update the minimum allowed rank (which is the maximum of
      -- the ranks of all parent neighbours plus the minimum level 
      -- separation caused by the connecting edges)
      local neighbour = edge:getNeighbour(node)
      local neighbour_rank = self.ranking:getRank(neighbour)
      min_rank[node] = math.max(min_rank[node], neighbour_rank + edge.minimum_levels)
    end
    
    for edge in table.value_iter(node:getOutgoingEdges()) do
      -- accumulate the weights of all outgoing edges
      out_weight[node] = (out_weight[node] or 0) + edge.weight

      -- update the maximum allowed rank (which is the minimum of
      -- the ranks of all child neighbours minus the minimum level
      -- sparation caused by the connecting edges)
      local neighbour = edge:getNeighbour(node)
      local neighbour_rank = self.ranking:getRank(neighbour)
      max_rank[node] = math.min(max_rank[node], neighbour_rank - edge.minimum_levels)
    end

    -- check whether the in- and outweight is the same
    if in_weight[node] == out_weight[node] then
      Sys:log('  feasible ranks of ' .. node.name .. ' are ' .. min_rank[node] .. ',...,' .. max_rank[node])

      -- check which of the allowed ranks has the least number of nodes
      local min_nodes_rank = min_rank[node]
      for n = min_rank[node] + 1, max_rank[node] do
        if #self.ranking:getNodes(n) < #self.ranking:getNodes(min_nodes_rank) then
          min_nodes_rank = n
        end
      end

      -- only move the node to the rank with the least number of nodes
      -- if it differs from the current rank of the node
      if min_nodes_rank ~= self.ranking:getRank(node) then
        self.ranking:setRank(node, min_nodes_rank)
      end

      Sys:log('  move ' .. node.name .. ' to rank ' .. self.ranking:getRank(node))
    end
  end
end



function NetworkSimplex:computeInitialRanking()
  -- queue for nodes to rank next
  local queue = {}

  -- number mapping that counts the number of ranked incoming 
  -- neighbours of each node
  local ranked_neighbours = {}

  -- convenience functions for managing the queue
  local function enqueue(node) table.insert(queue, node) end
  local function dequeue() return table.remove(queue, 1) end

  -- function to move unranked nodes to the queue if they have no
  -- unscanned incoming edges
  local function update_queue(node)
    -- check all nodes yet to be ranked
    for edge in table.value_iter(node:getOutgoingEdges()) do
      local neighbour = edge:getNeighbour(node)

      -- increment the number of ranked incoming neighbours of the neighbour node
      ranked_neighbours[neighbour] = (ranked_neighbours[neighbour] or 0) + 1

      -- check whether all incoming edges have been scanned
      if ranked_neighbours[neighbour] >= neighbour:getInDegree() then
        -- we have no unscanned incoming edges, queue the node now
        enqueue(neighbour)
      end
    end
  end

  -- reset the two-dimensional mapping from ranks to lists 
  -- of corresponding nodes
  self.ranking:reset()

  -- add all sinks to the queue
  for node in table.value_iter(self.graph.nodes) do
    if node:getInDegree() == 0 then
      enqueue(node)
      ranked_neighbours[node] = 0
    end
  end

  -- run long as there are nodes to be ranked
  while #queue > 0 do
    -- fetch the next unranked node from the queue
    local node = dequeue()
    -- get a list of its incoming edges
    local in_edges = node:getIncomingEdges()

    -- determine the minimum possible rank for the node
    local rank = table.combine_values(in_edges, function (rank, edge)
      local neighbour = edge:getNeighbour(node)
      if self.ranking:getRank(neighbour) then
        -- the minimum possible rank is the maximum of all neighbour ranks plus
        -- the corresponding edge lengths
        rank = math.max(rank, self.ranking:getRank(neighbour) + edge.minimum_levels)
      end
      return rank
    end, 1)

    -- rank the node
    self.ranking:setRank(node, rank)

    -- queue neighbours of nodes for which all incoming edges have
    -- been scanned
    --
    -- note that we don't need to mark the node's outgoing edges 
    -- as scanned prior to this, because this is equivalent to checking
    -- whether the node has already been ranked or not
    update_queue(node)
  end
end



function NetworkSimplex:dumpRanking(prefix, title)
  local ranks = self.ranking:getRanks()
  Sys:log(prefix .. title)
  for rank, nodes in pairs(ranks) do
    local str = prefix .. '  rank ' .. rank .. ':'
    local str = table.combine_values(nodes, function (str, node)
      return str .. ' ' .. node.name .. ' (' .. self.ranking:getRankPosition(node) .. ')'
    end, str)
    Sys:log(str)
  end
end



function NetworkSimplex:findTightTree(ranks)
  --Sys:log('find tight tree:')

  -- stack of nodes to visit next
  local stack = {}

  -- convenience functions for managing the queue
  function push(node) table.insert(stack, node) end
  function pop() return table.remove(stack) end

  local tree = nil

  -- construct a spanning tree for the subgraph reachable from
  -- each of the nodes in the underlying undirected graph, stop
  -- as soon as we have found one such spanning tree that is 
  -- non-empty
  for node in table.value_iter(self.graph.nodes) do
    --Sys:log('  test with start node ' .. node.name)

    -- create an empty spanning tree
    tree = Graph:new()

    -- create a mapping from original to copied nodes
    local tree_nodes = {}

    -- copy all nodes into the tree
    for node in table.value_iter(self.graph.nodes) do
      -- create a copy of the node
      local copy = node:copy()
      self.orig_node[copy] = node
      self.tree_node[node] = copy

      -- remember the copy
      tree_nodes[node] = copy

      -- add the copied node to the tree
      tree:addNode(copy)
    end

    -- reset the stack
    stack = {}

    -- reset the finished flag
    local finished = false

    -- add the node to the queue
    push(node)

    -- perform a depth-first search in the underlying undirected graph
    while not finished and #stack > 0 do
      -- fetch the next node from the DFS queue
      local node = pop()
      local tree_node = tree_nodes[node]

      --Sys:log('    visit ' .. node.name)

      -- iterate over all outgoing edges
      for edge in table.value_iter(node:getOutgoingEdges()) do
        local neighbour = edge:getNeighbour(node)
        local tree_neighbour = tree_nodes[neighbour]

        --Sys:log('      edge to neighbour ' .. neighbour.name .. ' has slack ' .. self:edgeSlack(edge))

        if not self.marked[tree_neighbour] and self:edgeSlack(edge) == 0 then
          --Sys:log('          queue ' .. neighbour.name)

          -- add the edge to the tree
          local edge_copy = edge:copy()
          self.orig_edge[edge_copy] = edge
          self.tree_edge[edge] = edge_copy
          edge_copy:addNode(tree_node)
          edge_copy:addNode(tree_neighbour)
          tree:addEdge(edge_copy)

          -- mark the two nodes
          self.marked[tree_node] = true
          self.marked[tree_neighbour] = true

          -- add the neighbour to the queue
          push(neighbour)
          
          -- stop if we have a valid spanning tree
          if #tree.edges == #self.graph.nodes - 1 then
            finished = true
            break
          end
        end
      end

      -- iterate over all incoming edges
      for edge in table.value_iter(node:getIncomingEdges()) do
        local neighbour = edge:getNeighbour(edge)
        local tree_neighbour = tree_nodes[neighbour]

        --Sys:log('      edge from neighbour ' .. neighbour.name .. ' has slack ' .. self:edgeSlack(edge))

        if not self.marked[tree_neighbour] and self:edgeSlack(edge) == 0 then
          --Sys:log('        queue ' .. neighbour.name)

          -- add the edge to the tree
          local edge_copy = edge:copy()
          self.orig_edge[edge_copy] = edge
          self.tree_edge[edge] = edge_copy
          edge_copy:addNode(tree_neighbour)
          edge_copy:addNode(tree_node)
          tree:addEdge(edge_copy)

          -- mark the two nodes
          self.marked[tree_node] = true
          self.marked[tree_neighbour] = true

          -- add the neighbour to the queue
          push(neighbour)
          
          -- stop if we have a valid spanning tree
          if #tree.edges == #self.graph.nodes - 1 then
            finished = true
            break
          end
        end
      end
    end

    -- remove all non-marked nodes from the tree
    table.remove_values(tree.nodes, function (node)
      if not self.marked[node] then
        self.tree_node[self.orig_node[node]] = nil
        return true
      else
        return false
      end
    end)

    -- check if we have a valid spanning tree
    if finished or #tree.edges == #self.graph.nodes - 1 then
      dump_tree(self.graph, 'original graph')
      dump_tree(tree, 'tight tree')
      -- return the first spanning tree we can find
      return tree
    end
  end

  return tree
end



function NetworkSimplex:edgeSlack(edge)
  local rank1 = self.ranking:getRank(edge.nodes[1])
  local rank2 = self.ranking:getRank(edge.nodes[2])
  local length = math.abs(rank2 - rank1)
  return length - edge.minimum_levels
end



function NetworkSimplex:isIncidentToTree(edge)
  local incident = false
  if not self.tree_edge[edge] then
    local head = edge:getHead()
    local tail = edge:getTail()

    if self.tree_node[head] and not self.tree_node[tail] then
      incident = true
    elseif self.tree_node[tail] and not self.tree_node[head] then
      incident = true
    end
  end
  return incident
end



function NetworkSimplex:initializeCutValues()
  -- calculate depth-first search tree information for fast
  -- checks of whether a node lies in the head or tail component
  -- of a split-up edge
  self.lim, self.low, self.parent_edge = self:calculateDFSRange(self.tree.nodes[1])

  --for key, val in pairs(self.lim)do
  --  Sys:log('node ' .. key.name .. ' low/lim = ' .. self.low[key] .. '/' .. self.lim[key])
  --end

  -- list of nodes to be visited next
  local stack = {}

  -- state information for nodes in the DFS search
  local discovered = {}
  local visited = {}
  local completed = {}

  -- convenience functions to manage the DFS stack
  function push(node) table.insert(stack, node) end
  function pop() return table.remove(stack) end
  function peek() return stack[#stack] end

  --- push the root node to the stack
  push(self.tree.nodes[1])
  discovered[self.tree.nodes[1]] = true

  -- perform the depth-first search
  while #stack > 0 do
    local node = peek()

    if visited[node] then
      --Sys:log('complete ' .. node.name)

      completed[node] = true
      pop()

      if self.parent_edge[node] then
        self:updateCutValue(self.parent_edge[node])
      end
    else
      --Sys:log('visit ' .. node.name)

      visited[node] = true

      local in_edges = node:getIncomingEdges()
      local out_edges = node:getOutgoingEdges()
      
      local edges = table.reverse_values(table.merge_values(out_edges, in_edges))

      for edge in table.value_iter(edges) do
        local neighbour = edge:getNeighbour(node)
        
        if self.parent_edge[node] ~= edge and not discovered[neighbour] then
          push(neighbour)
          discovered[neighbour] = true
        end
      end
    end
  end

  --Sys:log('cut values:')
  --for edge in table.value_iter(self.tree.edges) do
  --  Sys:log('  ' .. tostring(edge) .. ' cut value ' .. edge.cut_value)
  --end
end



--- DFS algorithm that calculates post-order traversal indices and parent edges.
--
-- This algorithm performs a depth-first search in a directed or undirected
-- graph. For each node it calculates the node's post-order traversal index, the
-- minimum post-order traversal index of its descendants as well as the edge by
-- which the node was reached in the depth-first traversal.
--
function NetworkSimplex:calculateDFSRange(root, edge_from_parent, lowest)
  -- list of nodes to be visited next
  local stack = {}

  -- state information for the nodes
  local discovered = {}
  local visited = {}
  local completed = {}

  -- convenience functions to manage the queue
  function push(node) table.insert(stack, node) end
  function pop() return table.remove(stack) end
  function peek() return stack[#stack] end

  -- allocate variables for the range information
  local parent_edge = {}
  local lim = {}
  local low = {}
  local traversal_index = 0

  -- set range information for the root node
  parent_edge[root] = edge_from_parent
  lim[root] = lowest or 1
  low[root] = lowest or 1

  --- queue the root node
  push(root)
  discovered[root] = true

  -- perform the depth-first search
  while #stack > 0 do
    local node = peek()

    if visited[node] then
      completed[node] = true
      pop()

      local out_edges = node:getOutgoingEdges()
      local in_edges = node:getIncomingEdges()
      local edges = table.reverse_values(table.merge_values(out_edges, in_edges))

      -- remove edges to nodes already completed
      edges = table.filter_values(edges, function (edge)
        return completed[edge:getNeighbour(node)]
      end)

      -- assign post-order traversal number
      lim[node] = traversal_index + 1
      traversal_index = traversal_index + 1

      if #edges == 0 then
        low[node] = lim[node]
      else
        low[node] = table.combine_values(edges, function (value, edge)
          local neighbour = edge:getNeighbour(node)
          return math.min(value, low[neighbour])
        end, #self.tree.nodes)
      end

    else
      visited[node] = true

      local in_edges = node:getIncomingEdges()
      local out_edges = node:getOutgoingEdges()
      
      local edges = table.reverse_values(table.merge_values(out_edges, in_edges))

      for edge in table.value_iter(edges) do
        local neighbour = edge:getNeighbour(node)
        if not discovered[neighbour] then
          push(neighbour)
          parent_edge[neighbour] = edge
          discovered[neighbour] = true
        end
      end
    end
  end

  return lim, low, parent_edge
end



function NetworkSimplex:updateCutValue(tree_edge)
  --Sys:log('update cut value of ' .. tostring(tree_edge))

  local v = nil
  if self.parent_edge[tree_edge:getTail()] == tree_edge then
    v = tree_edge:getTail()
    dir = 1
  else
    v = tree_edge:getHead()
    dir = -1
  end

  --Sys:log('  v = ' .. v.name)
  --Sys:log('  dir = ' .. dir)

  local sum = 0

  local out_edges = self.orig_node[v]:getOutgoingEdges()
  local in_edges = self.orig_node[v]:getIncomingEdges()
  local edges = table.merge_values(out_edges, in_edges)

  for edge in table.value_iter(edges) do
    --Sys:log('  xval(' .. tostring(edge) .. ', v = ' .. v.name .. ', dir = ' .. dir)

    local other = edge:getNeighbour(self.orig_node[v])
    --Sys:log('    other = ' .. other.name)

    local f = 0
    local rv = 0

    if not self:inTailComponentOf(self.tree_node[other], v) then
      f = 1
      rv = edge.weight
    else
      f = 0

      if self.tree_edge[edge] then
        rv = self.cut_value[self.tree_edge[edge]]
      else
        rv = 0
      end

      rv = rv - edge.weight
    end

    --Sys:log('    f = ' .. f)
    --Sys:log('    rv = ' .. rv)

    local d = 0

    if dir > 0 then
      if edge:isHead(self.orig_node[v]) then
        d = 1
      else
        d = -1
      end
    else
      if edge:isTail(self.orig_node[v]) then
        d = 1
      else
        d = -1
      end
    end

    --Sys:log('    d = ' .. d)

    if f > 0 then
      d = -d
      --Sys:log('    d = ' .. d)
    end

    if d < 0 then
      rv = -rv
    end

    --Sys:log('    rv = ' .. rv)

    sum = sum + rv
  end

  self.cut_value[tree_edge] = sum
  --Sys:log('  cutvalue = ' .. sum)
end



function NetworkSimplex:inTailComponentOf(node, v)
  return (self.low[v] <= self.lim[node]) and (self.lim[node] <= self.lim[v])
end



function NetworkSimplex:nextSearchIndex()
  local index = 1
    
  -- avoid tree edge index out of bounds by resetting the search index 
  -- as soon as it leaves the range of edge indices in the tree
  if self.search_index > #self.tree.edges then
    self.search_index = 1
    index = 1
  else
    index = self.search_index
    self.search_index = self.search_index + 1
  end

  return index
end



function NetworkSimplex:rerankBeforeReplacingEdge(leave_edge, enter_edge)
  local delta = self:edgeSlack(enter_edge)
  Sys:log('  delta = ' .. delta)

  local stack = {}
  local delta_stack = {}

  function push(node, delta)
    table.insert(stack, node)
    table.insert(delta_stack, delta)
  end

  function pop()
    return table.remove(stack), table.remove(delta_stack)
  end

  if delta >= 0 then
    local tail = leave_edge:getTail()
    local s = #tail.edges
    
    Sys:log('  s = ' .. s)

    if s == 1 then
      push(tail, delta)
    else
      local head = leave_edge:getHead()
      s = #head.edges

      if s == 1 then
        push(head, -delta)
      else
        if self.lim[tail] < self.lim[head] then
          push(tail, delta)
        else
          push(head, -delta)
        end
      end
    end
  end

  while #stack > 0 do
    local node, delta = pop()

    Sys:log('  rerank ' .. node.name .. ', delta = ' .. delta)

    self:dumpRanking('   ', 'ranks before reranking')

    local rank = self.ranking:getRank(self.orig_node[node])
    self.ranking:setRank(self.orig_node[node], rank - delta)

    self:dumpRanking('   ', 'ranks after reranking')

    local out_edges = node:getOutgoingEdges()
    local in_edges = node:getIncomingEdges()
    local edges = table.merge_values(out_edges, in_edges)

    for edge in table.value_iter(edges) do
      local other = edge:getNeighbour(node)
      if edge ~= self.parent_edge[node] then
        push(other, delta)
      end
    end
  end
end



function NetworkSimplex:updateCutValuesUpToCommonAncestor(v, w, cutval, dir)
  Sys:log('update cut values from ' .. v.name .. ' up to common ancestor of ' .. v.name .. ' and ' .. w.name)

  while not self:inTailComponentOf(w, v) do
    Sys:log('  ' .. w.name .. ' is in head component of ' .. v.name)

    local edge = self.parent_edge[v]

    Sys:log('    parent edge is ' .. tostring(edge))
  
    if edge:isTail(v) then
      d = dir
    else
      d = not dir
    end

    Sys:log('    old cut value of ' .. tostring(edge) .. ' = ' .. self.cut_value[edge])

    if d then
      self.cut_value[edge] = self.cut_value[edge] + cutval
    else
      self.cut_value[edge] = self.cut_value[edge] - cutval
    end

    Sys:log('    new cut value of ' .. tostring(edge) .. ' = ' .. self.cut_value[edge])

    if self.lim[edge:getTail()] > self.lim[edge:getHead()] then
      v = edge:getTail()
    else
      v = edge:getHead()
    end

    Sys:log('    continue with ' .. v.name)
  end

  return v
end
