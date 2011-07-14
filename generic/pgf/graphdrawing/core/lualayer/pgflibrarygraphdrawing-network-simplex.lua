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



NetworkSimplex.BALANCE_TOP_BOTTOM = 1
NetworkSimplex.BALANCE_LEFT_RIGHT = 2



function NetworkSimplex:new(graph, balancing)
  local simplex = {
    graph = graph,
    balancing = balancing,
  }
  setmetatable(simplex, NetworkSimplex)
  return simplex
end



function NetworkSimplex:run()
  -- initialize the tree edge search index
  self.search_index = 1

  -- initialize internal edge parameters
  self.cut_value = {}
  for edge in table.value_iter(self.graph.edges) do
    self.cut_value[edge] = 0
  end

  -- initialize internal node parameters
  self.marked = {}
  for node in table.value_iter(self.graph.nodes) do
    self.marked[node] = false
  end

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
    
    assert(enter_edge, 'no non-tree edge to replace ' .. tostring(leave_edge) .. ' could be found')

    self:dump_tree(self.tree, 'tree before replacing edges')
    self:dumpRanking('', 'ranking before replacing edges')
    self:dump_cut_values('cut values before replacing edges')
    self:dump_slack('edge slacks before replacing edges')

    -- exchange leave_edge and enter_edge in the tree, updating
    -- the ranks and cut values of all nodes
    self:exchangeTreeEdges(leave_edge, enter_edge)
    
    self:dump_tree(self.tree, 'tree after replacing edges')
    self:dumpRanking('', 'ranking after replacing edges')
    self:dump_cut_values('cut values after replacing edges')
    self:dump_slack('edge slacks after replacing edges')

    -- find the next tree edge with a negative cut value, if 
    -- there are any left
    leave_edge = self:findNegativeCutEdge()
  end

  self:dumpRanking('', 'ranking before normalization and/or balancing')
  self:dump_tree(self.tree, 'final tree after running the network simplex')
  self:dump_cut_values('cut values after running the network simplex')
  self:dump_slack('edge slacks after running the network simplex')

  if self.balancing == NetworkSimplex.BALANCE_TOP_BOTTOM then
    -- normalize by setting the least rank to zero
    self.ranking:normalizeRanks()

    -- move nodes to feasible ranks with the least number of nodes
    -- in order to avoid crowding and to improve the overall aspect 
    -- ratio of the drawing
    self:balanceRanksTopBottom()
  elseif self.balancing == NetworkSimplex.BALANCE_LEFT_RIGHT then
    self:balanceRanksLeftRight()
  end

  self:dumpRanking('', 'ranking after normalization and/or balancing')
  self:dump_cut_values('cut values after normalization and/or balancing')
  self:dump_slack('edge slacks after normalization and/or balancing')
end



-- Jannis: Verified this one, it's correct.
function NetworkSimplex:constructFeasibleTree()
  self:dump_tree(self.graph, 'input graph')

  self:computeInitialRanking()

  self:dumpRanking('', 'initial ranking')

  -- find a maximal tree of tight edges in the graph
  while self:findTightTree() < #self.graph.nodes do
    self:dump_tree(self.tree, 'incomplete feasible tree')

    Sys:log('find non-tree edge with minimal slack:')

    local min_slack_edge = nil

    for node in table.value_iter(self.graph.nodes) do
      local out_edges = node:getOutgoingEdges()
      for edge in table.value_iter(out_edges) do
        --Sys:log('  check if ' .. tostring(edge) .. ' is incident to the tree')
        if not self.tree_edge[edge] and self:isIncidentToTree(edge) then
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
          --Sys:log('  set rank of ' .. node.name .. ' from ' .. rank .. ' to ' .. rank + delta)
          self.ranking:setRank(self.orig_node[node], rank + delta)
          --self:dumpRanking('  ', 'ranking after that')
        end

        --self:dumpRanking('  ', 'ranking before normalization')
        --self.ranking:normalizeRanks()
        --self:dumpRanking('  ', 'ranking after normalization')
      end
    end

    Sys:log('  minimal slack edge ' .. tostring(min_slack_edge) .. ' has slack ' .. self:edgeSlack(min_slack_edge) .. ' now')
    self:dumpRanking('', 'ranking after adding ' .. tostring(min_slack_edge) .. ' to the tree')
  end

  self:dump_tree(self.tree, 'final feasible tree')
  self:dumpRanking('', 'feasible tree ranking')

  self:initializeCutValues()

  self:dump_cut_values("feasible tree cut values")
end



-- Jannis: Verified this one, it's correct.
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
  local tail = leave_edge:getTail()
  local head = leave_edge:getHead()

  local v = nil
  local direction = nil
  
  if self.lim[tail] < self.lim[head] then
    v = tail
    direction = 'in'
  else
    v = head
    direction = 'out'
  end

  local search_root = v
  local enter_edge = nil
  local slack = math.huge

  local function find_edge(v, direction)
    Sys:log('  find edge ' .. v.name .. ', ' .. direction)

    if direction == 'out' then

      local out_edges = self.orig_node[v]:getOutgoingEdges()
      for edge in table.value_iter(out_edges) do
        local head = edge:getHead()
        local tree_head = self.tree_node[head]

        assert(head and tree_head)

        if not self.tree_edge[edge] then
          if not self:inTailComponentOf(tree_head, search_root) then
            if self:edgeSlack(edge) < slack or not enter_edge then
              enter_edge = edge
              slack = self:edgeSlack(edge)
            end
          end
        else
          if self.lim[tree_head] < self.lim[v] then
            find_edge(tree_head, 'out')
          end
        end
      end

      for edge in table.value_iter(v:getIncomingEdges()) do
        if slack <= 0 then
          break
        end

        local tail = edge:getTail()

        if self.lim[tail] < self.lim[v] then
          find_edge(tail, 'out')
        end
      end
    
    else

      local in_edges = self.orig_node[v]:getIncomingEdges()
      for edge in table.value_iter(in_edges) do
        local tail = edge:getTail()
        local tree_tail = self.tree_node[tail]

        assert(tail and tree_tail)
        
        if not self.tree_edge[edge] then
          if not self:inTailComponentOf(tree_tail, search_root) then
            if self:edgeSlack(edge) < slack or not enter_edge then
              enter_edge = edge
              slack = self:edgeSlack(edge)
            end
          end
        else
          if self.lim[tree_tail] < self.lim[v] then
            find_edge(tree_tail, 'in')
          end
        end
      end

      for edge in table.value_iter(v:getOutgoingEdges()) do
        if slack <= 0 then
          break
        end

        local head = edge:getHead()

        if self.lim[head] < self.lim[v] then
          find_edge(head, 'in')
        end
      end
    
    end
  end

  self:dumpRange(self.lim, self.low, self.parent_edge, '', 'range before finding a replacement edge')

  find_edge(v, direction)
  
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

  -- remove the old edge from the tree
  self:removeEdgeFromTree(leave_edge)

  -- add the new edge to the tree
  local tree_edge = self:addEdgeToTree(enter_edge)

  -- set its cut value
  self.cut_value[tree_edge] = -cutval

  self:calculateDFSRange(ancestor, self.parent_edge[ancestor], self.low[ancestor])
end



function NetworkSimplex:balanceRanksTopBottom()
  Sys:log('balancing the ranks:')

  -- available ranks
  local ranks = self.ranking:getRanks()

  -- node to in/out weight mappings
  local in_weight = {}
  local out_weight = {}
  
  -- node to lowest/highest possible rank mapping
  local min_rank = {}
  local max_rank = {}

  -- compute the in and out weights of each node
  for node in table.value_iter(self.graph.nodes) do
    -- assume there are no restrictions on how to rank the node
    min_rank[node], max_rank[node] = ranks[1], ranks[#ranks]

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



-- Jannis: Verified that this function works correctly.
function NetworkSimplex:balanceRanksLeftRight()
  for edge in table.value_iter(self.tree.edges) do
    if self.cut_value[edge] == 0 then
      local other_edge = self:findReplacementEdge(edge)
      if other_edge then
        local delta = self:edgeSlack(other_edge)
        if delta > 1 then
          if self.lim[edge:getTail()] < self.lim[edge:getHead()] then
            self:rerank(edge:getTail(), delta / 2)
          else
            self:rerank(edge:getHead(), -delta / 2)
          end
        end
      end
    end
  end
end



-- Jannis: Verified this one, it's correct.
function NetworkSimplex:computeInitialRanking()
  Sys:log('compute initial ranking:')
  
  -- queue for nodes to rank next
  local queue = {}

  -- convenience functions for managing the queue
  local function enqueue(node) table.insert(queue, node) end
  local function dequeue() return table.remove(queue, 1) end

  -- reset the two-dimensional mapping from ranks to lists 
  -- of corresponding nodes
  self.ranking:reset()

  -- mapping of nodes to the number of unscanned incoming edges
  local remaining_edges = {}

  -- add all sinks to the queue
  for node in table.value_iter(self.graph.nodes) do
    local edges = node:getIncomingEdges()
    
    remaining_edges[node] = #edges

    if #edges == 0 then
      Sys:log('  queue ' .. node.name)
      enqueue(node)
    end
  end

  -- run long as there are nodes to be ranked
  while #queue > 0 do
    -- fetch the next unranked node from the queue
    local node = dequeue()

    Sys:log('  visit ' .. node.name)

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

    -- get a list of the node's outgoing edges
    local out_edges = node:getOutgoingEdges()

    -- queue neighbours of nodes for which all incoming edges have been scanned
    for edge in table.value_iter(out_edges) do
      local head = edge:getHead()
      remaining_edges[head] = remaining_edges[head] - 1
      if remaining_edges[head] <= 0 then
        enqueue(head)
      end
    end
  end
end



-- Jannis: This function works correctly.
function NetworkSimplex:findTightTree()
  Sys:log('find tight tree:')

  local function build_tight_tree(node)
    Sys:log('    visit ' .. node.name)

    local out_edges = node:getOutgoingEdges()
    local in_edges = node:getIncomingEdges()

    local edges = table.merge_values(out_edges, in_edges)

    for edge in table.value_iter(edges) do
      local neighbour = edge:getNeighbour(node)
      if (not self.marked[neighbour]) and self:edgeSlack(edge) == 0 then
        self:addEdgeToTree(edge)

        for node in table.value_iter(edge.nodes) do
          self.marked[node] = true
        end
        
        if #self.tree.edges == #self.graph.nodes-1 then
          return true
        end

        if build_tight_tree(neighbour) then
          return true
        end
      end
    end

    return false
  end

  self.marked = {}

  for node in table.value_iter(self.graph.nodes) do
    Sys:log('  build tree starting at ' .. node.name)

    self.tree = Graph:new()
    self.tree_node = {}
    self.orig_node = {}
    self.tree_edge = {}
    self.orig_edge = {}

    build_tight_tree(node)

    if #self.tree.edges > 0 then
      break
    end
  end

  return #self.tree.nodes
end



function NetworkSimplex:edgeSlack(edge)
  -- make sure this is never called with a tree edge
  assert(not self.orig_edge[edge])

  local head_rank = self.ranking:getRank(edge:getHead())
  local tail_rank = self.ranking:getRank(edge:getTail())
  local length = head_rank - tail_rank
  return length - edge.minimum_levels
end



function NetworkSimplex:isIncidentToTree(edge)
  -- make sure this is never called with a tree edge
  assert(not self.orig_edge[edge])

  local head = edge:getHead()
  local tail = edge:getTail()

  if self.tree_node[head] and not self.tree_node[tail] then
    return true
  elseif self.tree_node[tail] and not self.tree_node[head] then
    return true
  else
    return false
  end
end



-- Jannis: Verified that this works correctly.
function NetworkSimplex:initializeCutValues()
  self:calculateDFSRange(self.tree.nodes[1], nil, 1)

  local function init(search)
    search:push({ node = self.tree.nodes[1], parent_edge = nil })
  end

  local function visit(search, data)
    search:setVisited(data, true)

    for edge in table.reverse_value_iter(data.node:getIncomingEdges()) do
      if edge ~= data.parent_edge then
        search:push({ node = edge:getTail(), parent_edge = edge })
      end
    end

    for edge in table.reverse_value_iter(data.node:getOutgoingEdges()) do
      if edge ~= data.parent_edge then
        search:push({ node = edge:getHead(), parent_edge = edge })
      end
    end
  end

  local function complete(search, data)
    Sys:log('postorder')
    if data.parent_edge then
      self:updateCutValue(data.parent_edge)
    end
  end

  DepthFirstSearch:new(self.tree, init, visit, complete):run()
end



--- DFS algorithm that calculates post-order traversal indices and parent edges.
--
-- This algorithm performs a depth-first search in a directed or undirected
-- graph. For each node it calculates the node's post-order traversal index, the
-- minimum post-order traversal index of its descendants as well as the edge by
-- which the node was reached in the depth-first traversal.
--
-- Jannis: Verified that this one works correctly.
--
function NetworkSimplex:calculateDFSRange(root, edge_from_parent, lowest)
  Sys:log('dfsrange from ' .. root.name .. ', edge from parent ' .. tostring(edge_from_parent) .. ', lowest ' .. lowest)

  local function dfs_range(node, par, low)
    local lim = low
    self.parent_edge[node] = par
    self.low[node] = low

    for edge in table.value_iter(node:getOutgoingEdges()) do
      if edge ~= par then
        lim = dfs_range(edge:getNeighbour(node), edge, lim)
      end
    end
    for edge in table.value_iter(node:getIncomingEdges()) do
      if edge ~= par then
        lim = dfs_range(edge:getNeighbour(node), edge, lim)
      end
    end
    self.lim[node] = lim
    return lim + 1
  end
  dfs_range(root, edge_from_parent, lowest)

  local verbose_before = Sys:getVerbose()
  Sys:setVerbose(true)
  self:dumpRange(self.lim, self.low, self.parent_edge, '', 'range after dfsrange')
  local lim_lookup = {}
  local min_lim = math.huge
  local max_lim = -math.huge
  for node in table.value_iter(self.tree.nodes) do
    assert(self.lim[node])
    assert(self.low[node])
    assert(not lim_lookup[self.lim[node]])
    lim_lookup[self.lim[node]] = true
    min_lim = math.min(min_lim, self.lim[node])
    max_lim = math.max(max_lim, self.lim[node])
  end
  for n = min_lim, max_lim do
    assert(lim_lookup[n] == true)
  end
  Sys:setVerbose(verbose_before)
end



-- Jannis: This function works correctly.
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



-- Jannis: This function works correctly.
function NetworkSimplex:inTailComponentOf(node, v)
  --Sys:log(node.name .. ' (tree node ' .. tostring(self.tree_node[node]) .. ') inTailCompOf ' .. v.name .. ' (tree node ' .. tostring(self.tree_node[v]) .. ')')
  --self:dumpRange(self.lim, self.low, self.parent_edge, '  ', 'current range information')
  return (self.low[v] <= self.lim[node]) and (self.lim[node] <= self.lim[v])
end



-- Jannis: This function works correctly.
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



-- Jannis: This function works correctly even with the iterative
-- solution implemented below.
function NetworkSimplex:rerank(node, delta)
  local function init(search)
    search:push({ node = node, delta = delta })
  end

  local function visit(search, data)
    search:setVisited(data, true)

    local orig_node = self.orig_node[data.node]
    self.ranking:setRank(orig_node, self.ranking:getRank(orig_node) - data.delta)

    for edge in table.reverse_value_iter(data.node:getIncomingEdges()) do
      if edge ~= self.parent_edge[data.node] then
        search:push({ node = edge:getTail(), delta = data.delta })
      end
    end

    for edge in table.reverse_value_iter(data.node:getOutgoingEdges()) do
      if edge ~= self.parent_edge[data.node] then
        search:push({ node = edge:getHead(), delta = data.delta })
      end
    end
  end

  DepthFirstSearch:new(self.tree, init, visit):run()
end



-- Jannis: This function works correctly.
function NetworkSimplex:rerankBeforeReplacingEdge(leave_edge, enter_edge)
  local delta = self:edgeSlack(enter_edge)
  
  if delta > 0 then
    local tail = leave_edge:getTail()
    
    if #tail.edges == 1 then
      self:rerank(tail, delta)
    else
      local head = leave_edge:getHead()

      if #head.edges == 1 then
        self:rerank(head, -delta)
      else
        if self.lim[tail] < self.lim[head] then
          self:rerank(tail, delta)
        else
          self:rerank(head, -delta)
        end
      end
    end
  end
end



-- Jannis: This function works correctly.
function NetworkSimplex:updateCutValuesUpToCommonAncestor(v, w, cutval, dir)
  Sys:log('update cut values from ' .. v.name .. ' up to common ancestor of ' .. v.name .. ' and ' .. w.name)

  while not self:inTailComponentOf(w, v) do
    local edge = self.parent_edge[v]

    if edge:isTail(v) then
      d = dir
    else
      d = not dir
    end

    if d then
      self.cut_value[edge] = self.cut_value[edge] + cutval
    else
      self.cut_value[edge] = self.cut_value[edge] - cutval
    end

    if self.lim[edge:getTail()] > self.lim[edge:getHead()] then
      v = edge:getTail()
    else
      v = edge:getHead()
    end
  end

  return v
end



function NetworkSimplex:addEdgeToTree(edge)
  assert(not self.tree_edge[edge])

  -- create the new tree edge
  local tree_edge = edge:copy()
  self.orig_edge[tree_edge] = edge
  self.tree_edge[edge] = tree_edge

  -- create tree nodes if necessary
  for node in table.value_iter(edge.nodes) do
    local tree_node 
    
    if self.tree_node[node] then
      tree_node = self.tree_node[node]
    else
      tree_node = node:copy()
      self.orig_node[tree_node] = node
      self.tree_node[node] = tree_node
    end

    self.tree:addNode(tree_node)
    tree_edge:addNode(tree_node)
  end

  self.tree:addEdge(tree_edge)

  return tree_edge
end



function NetworkSimplex:removeEdgeFromTree(edge)
  self.tree:deleteEdge(edge)
  self.tree_edge[self.orig_edge[edge]] = nil
  self.orig_edge[edge] = nil
end



function NetworkSimplex:dump_tree(tree, name)
  Sys:log(name .. ':')
  for node in table.value_iter(tree.nodes) do
    Sys:log('  node ' .. node.name)
    for edge in table.value_iter(node.edges) do
      Sys:log('    edge ' .. tostring(edge))
    end
  end
  for edge in table.value_iter(tree.edges) do
    Sys:log('  edge ' .. tostring(edge))
  end
end



function NetworkSimplex:dump_cut_values(title)
  Sys:log(title .. ':')
  for edge in table.value_iter(self.tree.edges) do
    Sys:log('  ' .. tostring(edge) .. ': cut value = ' .. tostring(self.cut_value[edge]))
  end
end



function NetworkSimplex:dump_slack(title)
  Sys:log(title .. ':')
  for edge in table.value_iter(self.tree.edges) do
    Sys:log('  ' .. tostring(edge) .. ': slack = ' .. self:edgeSlack(self.orig_edge[edge]))
  end
end



function NetworkSimplex:dumpRange(lim, low, parent_edge, prefix, title)
  Sys:log(prefix .. title .. ':')
  for node in table.value_iter(self.tree.nodes) do
    Sys:log(string.format('%s  node %-30s lim %i low %i parent %s\n',
                          prefix,
                          node.name,
                          tonumber(lim[node]) or -1,
                          tonumber(low[node]) or -1, 
                          tostring(parent_edge[node])))
  end
end



function NetworkSimplex:dumpRanking(prefix, title)
  local ranks = self.ranking:getRanks()
  Sys:log(prefix .. title)
  for rank in table.value_iter(ranks) do
    local nodes = self.ranking:getNodes(rank)
    local str = prefix .. '  rank ' .. rank .. ':'
    local str = table.combine_values(nodes, function (str, node)
      return str .. ' ' .. node.name .. ' (' .. self.ranking:getRankPosition(node) .. ')'
    end, str)
    Sys:log(str)
  end
end
