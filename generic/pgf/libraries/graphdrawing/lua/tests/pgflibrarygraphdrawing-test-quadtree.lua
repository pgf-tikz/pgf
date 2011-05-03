-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

--- This file contains box test cases.

pgf.module("pgf.graphdrawing")

Sys:setVerbose(false)

math.randomseed(2)

local tree = QuadTree:new(0, 0, 10, 10)

local nodes = {}

for n in iter.times(5) do
  local node = Node:new{
    name = tostring(n),
    pos = Vector:new(2, function (n) return math.random(0, 10) end)
  }
  table.insert(nodes, node)
end

for node in table.value_iter(nodes) do
  Sys:log('insert node ' .. node.name .. ' ' .. tostring(node.pos))
  tree:insert(node)
  Sys:log('quad tree:')
  tree:dump('  ')
end

assert(true)
