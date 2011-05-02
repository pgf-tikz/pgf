-- Copyright 2011 by Jannis Pohlmann <jannis@xfce.org>
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

pgf.module("pgf.graphdrawing")



function drawGraphAlgorithm_wetherelltree(graph, options)
  -- find the root node of the graph
  graph.root = graph:findNodeIf(function (node) return node:getOption('root') end)
  if not graph.root then
    error('no root node specified. aborting')
  end

  -- check if this graph really is a tree
  if not isTree(graph) then
    error('graph is not a tree. aborting')
  end
  
  local next_x = {}

  -- perform post order traversal to assign preliminary 
  -- x coordinates to all nodes
  for node in traversePostOrder(graph) do
    local children = getChildren(node)

    if #children == 0 then
      -- no children, just place the node at the next available 
      -- x coordinate of its level
      node.pos.x = next_x[node.level] or 0
    else
      if #children == 1 then
        -- one child, place the node one x coordinate to the right of
        -- the child node
        node.pos.x = children[1].pos.x + 1
      else
        -- place the node at the average x coordinate of all its children
        node.pos.x = 0
        for child in values(children) do
          node.pos.x = node.pos.x + child.pos.x
        end
        node.pos.x = node.pos.x / #children
      end
    end

    -- compute the shifting needed to move the node to the next available
    -- x coordinate of its level (often needed for average-positioned nodes)
    if node.pos.x < (next_x[node.level] or 0) then
      node.pos.shift = next_x[node.level] - node.pos.x
      Sys:logMessage('wetherelltree: ' .. formatNode(node) .. ' shifted by ' .. node.pos.shift)
      node.pos.x = next_x[node.level] or 0
    end

    -- update the next available x coordinate of the node's level
    next_x[node.level] = node.pos.x + 2
  end


  -- perform pre order traversal in order to shift all nodes and their 
  -- subtrees where they belong
  --
  -- FIXME Is this correct? It doesn't look 100% like in the Reingold/Tilford
  -- paper where they show an example of the Wetherell/Shannon algorithm.
  local shift_x = {}
  for node in traversePreOrder(graph) do
    -- compute the shift (maximum of the last shift at this level and the shift
    -- required by the parent node)
    local shift = math.max(shift_x[node.level] or 0, node.parent.pos.shift or 0)
    Sys:logMessage('wetherelltree: ' .. formatNode(node) .. ' needs shifting by ' .. shift)
    node.pos.x = node.pos.x + shift

    -- cumulate the parent's shift and the shift of the node itself so that
    -- the subtree of the node is shifted by the sum of the two
    node.pos.shift = (node.pos.shift or 0) + (node.parent.pos.shift or 0)

    -- remember the shift for the next node located at this level
    shift_x[node.level] = shift
  end

  -- determine the node distance
  local node_distance = tonumber(graph:getOption('node distance') or 28.5)

  -- map simplified x,y coordinates to real coordinates in the drawing
  for node in table.value_iter(graph.nodes) do
    node.pos.y = -1 * node.level * node_distance
    node.pos.x = node.pos.x * node_distance
  end
end



function getChildren(node)
  local children = {}

  for edge in values(node:getEdges()) do
    local child = edge:getNeighbour(node)

    if child.parent ~= child and node.parent ~= child then
      table.insert(children, child)
    end
  end

  return children
end




function traversePostOrder(graph, enterFunc, visitFunc)
  local stack = {}

  local function push(node) 
    table.insert(stack, node) 
  end
  
  local function peek() 
    return stack[#stack] 
  end
 
  local function pop() 
    return table.remove(stack) 
  end

  -- reset nodes
  for node in table.value_iter(graph.nodes) do
    node.visited = false
    node.parent = nil
    node.level = nil
  end

  graph.root.parent = graph.root
  graph.root.level = 0

  push(graph.root)

  return function()
    while #stack > 0 do
      local node = peek()
      local children = getChildren(node)

      for child in values(children) do
        child.parent = node
        child.level = node.level + 1
      end

      local childPushed = false

      for i = #children,1,-1 do 
        if not children[i].visited then
          childPushed = true
          push(children[i])
        end
      end

      if not childPushed then
        node.visited = true
        pop()
        return node
      end
    end
    return nil
  end
end



function traversePreOrder(graph, enterFunc, visitFunc)
  local stack = {}

  local function push(node) 
    table.insert(stack, node) 
  end
  
  local function peek() 
    return stack[#stack] 
  end
 
  local function pop() 
    return table.remove(stack) 
  end

  -- reset nodes
  for node in table.value_iter(graph.nodes) do
    node.visited = false
    node.parent = nil
    node.level = nil
  end

  graph.root.parent = graph.root
  graph.root.level = 0

  push(graph.root)

  return function()
    while #stack > 0 do
      local node = pop()
      local children = getChildren(node)

      for child in values(children) do
        child.parent = node
        child.level = node.level + 1
      end

      for i = #children,1,-1 do
        if not children[i].visited then
          push(children[i])
        end
      end

      return node
    end
    return nil
  end
end



function formatNode(node)
  return string.gsub(node.name, '.*@(.*)', '%1')
end



function isTree(graph)
  local stack = {}

  local function push(node)
    table.insert(stack, node)
  end

  local function pop()
    return table.remove(stack)
  end

  local function edgeNotExplored(edge)
    return not edge.explored
  end

  -- reset nodes
  for node in table.value_iter(graph.nodes) do
    node.visited = false
    node.parent = nil
    node.level = nil
  end

  -- reset edges
  for edge in values(graph.edges) do
    edge.explored = false
  end

  -- a graph is not a tree if it has at least one cycle,
  -- so we'll be looking for cycles in the graph to check
  -- if it is a tree
  local cycle_found = false

  -- visit the root node
  graph.root.visited = true
  graph.root.parent = graph.root
  push(graph.root)

  -- walk the tree in a depth-first search, looking for cycles
  while not cycle_found and #stack > 0 do
    -- get the next node
    local node = pop()

    -- iterate over all adjacent edges that we haven't explored yet
    for edge in filter(values(node:getEdges()), edgeNotExplored) do
      -- mark the edge as explored
      edge.explored = true
      
      -- get the node at the other end of the edge
      local neighbour = edge:getNeighbour(node)

      if neighbour.visited then
        -- a cycle is found if an edge not yet explored leads to
        -- a node that has already been visited
        cycle_found = false
      else
        -- the neighbour has not been visited yet, so do this now
        neighbour.visited = true
        neighbour.parent = node
        push(neighbour)
      end
    end
  end

  -- return true if no cycle was found
  return not cycle_found
end
