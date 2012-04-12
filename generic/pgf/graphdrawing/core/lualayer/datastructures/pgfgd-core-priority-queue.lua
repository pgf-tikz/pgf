-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file contains an implementation of a priority queue based on a Fibonacci heap.
--
-- TODO this class needs to be documented.

pgf.module("pgf.graphdrawing")



PriorityQueue = {}
PriorityQueue.__index = PriorityQueue



function PriorityQueue:new()
  local queue = {
    heap = FibonacciHeap:new(),
    nodes = {},
    values = {},
  }
  setmetatable(queue, PriorityQueue)
  return queue
end



function PriorityQueue:enqueue(value, priority)
  local node = self.heap:insert(priority)
  self.nodes[value] = node
  self.values[node] = value
end



function PriorityQueue:dequeue()
  local node = self.heap:extractMinimum()

  if node then
    local value = self.values[node]
    self.nodes[value] = nil
    self.values[node] = nil
    return value
  else
    return nil
  end
end



function PriorityQueue:updatePriority(value, priority)
  local node = self.nodes[value]
  assert(node, 'updating the priority of ' .. tostring(value) .. ' failed because it is not in the priority queue')
  self.heap:updateValue(node, priority)
end



function PriorityQueue:isEmpty()
  return #self.heap.trees == 0
end
