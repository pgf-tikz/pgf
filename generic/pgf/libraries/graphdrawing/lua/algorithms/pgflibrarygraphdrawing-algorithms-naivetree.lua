-- Copyright 2011 by Jannis Pohlmann <jannis@xfce.org>
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This is about the most naive implementation of a tree drawing algorithm.

pgf.module("pgf.graphdrawing")



--- A very naive and simple algorithm for drawing arbitrary trees.
--
-- In this algorithm, each node is assigned an x coordinate that reflects
-- reflects its level in the rooted tree. The y coordinates of the nodes at each 
-- level are simply incremented from the left to the right.
--
-- @param graph   The tree to draw.
-- @param options Options passed to the algorithm from TikZ.
--
function drawGraphAlgorithm_naivetree(graph, options)
  -- find the root note
  graph.root = graph:findNodeIf(function (node) return node:getOption("root") end)
  if graph.root == nil then
    error("no root node specified. aborting")
  end

  -- determine the node distance
  local node_distance = tonumber(graph:getOption('node distance') or 28.5)

  -- array for incrementing the x coordinate at each level
  local column = {}

  -- traverse the tree with a pre-order iterator
  for node in preorderTraversal(graph) do
    -- compute the grid column for this node
    if column[node.level] == nil then
      column[node.level] = 0
    else
      column[node.level] = column[node.level] + 1
    end

    -- position the node, using the level as the y coordinate and
    -- the column as the x coordinate
    node.pos.y = -1 * node.level * node_distance
    node.pos.x = column[node.level] * node_distance
  end
end



--- Iterate over a graph in a pre-order traversal.
-- 
-- This function returns an pre-order iterator for all nodes in the tree.
--
-- @param graph The input tree to iterate over.
--
-- @return Pre-order iterator for all nodes in the tree.
--
function preorderTraversal(graph)
  local stack = {}
  local visited = {}
  
  -- Push a node to the stack
  local function push(stack, node)
    table.insert(stack, node)
  end

  -- Pop a node from the stack
  local function pop(stack)
    return table.remove(stack, #stack)
  end

  -- Check if a node has not been visited yet
  local function isNotVisited(node)
    return visited[node] == nil
  end

  -- Return all not-yet-visited children of a node
  local function getChildren(node)
    local children = {}
    for edge in values(node:getEdges()) do
      local child = edge:getNeighbour(node)
      if not visited[child] then
        --Sys:logMessage('naivetree: child ' .. string.gsub(child.name, '.*@(.*)', '%1'))
        table.insert(children, child)
      end
    end
    return children
  end

  -- Visit the root node
  push(stack, graph.root)
  visited[graph.root] = true
  graph.root.level = 1

  return function ()
    -- check if the stack still has nodes
    while #stack > 0 do
      -- pop the next node from the stack
      local node = pop(stack)

      -- iterate over all children in reverse order
      local children = getChildren(node)
      for i = #children,1,-1 do
        -- visit the child node
        push(stack, children[i])
        visited[children[i]] = true

        -- compute the level of the child in the tree 
        children[i].level = node.level + 1
      end

      -- return the node we just popped from the stack
      return node
    end

    -- no nodes left, end the traversal
    return nil
  end
end
