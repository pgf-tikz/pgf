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


-- create a new quad tree
local tree = QuadTree:new(0, 0, 10, 10, 1)

-- create random nodes (using a fixed seed so the results are reproducible)
math.randomseed(2)
local nodes = {}
for n in iter.times(5) do
  local node = Node:new{
    name = tostring(n),
    pos = Vector:new(2, function (n) return math.random(0, 10) end)
  }
  table.insert(nodes, node)
end

-- insert the nodes into the quad tree
for node in table.value_iter(nodes) do
  Sys:log(' ')
  Sys:log('insert node ' .. node.name .. ' ' .. tostring(node.pos))
  tree:insert(Particle:new(node.pos))
  Sys:log('quad tree:')
  tree:dump('  ')
  Sys:log(' ')
end

-- verify that the mass equals the number of nodes inserted
assert(tree.root_cell.mass == #nodes)

-- verify that the centre of mass is computed as expected
local centre_of_mass = Vector:new(2, function (n) return ({ 4.6, 4 })[n] end)
assert(centre_of_mass:x() == tree.root_cell.centre_of_mass:x())
assert(centre_of_mass:y() == tree.root_cell.centre_of_mass:y())

-- verify that the centre of mass is the average of the node's positions
local avg = table.combine_values(nodes, function (sum, node)
  return sum:plus(node.pos)
end, Vector:new(2, function (n) return 0 end))
avg = avg:dividedByScalar(#nodes)

Sys:log('avg = ' .. tostring(avg))

assert(avg:x() == tree.root_cell.centre_of_mass:x())
assert(avg:y() == tree.root_cell.centre_of_mass:y())

-- define the Barnes-Hut opening criterion
function barnes_hut_criterion(cell, particle)
  local distance = particle.pos:minus(cell.centre_of_mass):norm()
  return cell.width / distance <= 1.2
end

-- find all cells that match the criterion for the different nodes
for node in table.value_iter(nodes) do
  local cells = tree:findInteractionCells(Particle:new(node.pos), barnes_hut_criterion)
  Sys:log('cells that influence ' .. node.name .. ' ' .. tostring(node.pos) .. ':')
  for cell in table.value_iter(cells) do
    Sys:log('  ' .. tostring(cell))
  end
end

--local array = {}
--for i = 1, 1000000 do
--  table.insert(array, Vector:new(2, function (n) return math.random(0, 100) end))
--end
--
--local sum = Vector:new(2, function (n) return 0 end)
--local start = os.clock()
--for i = 1, #array do
--  sum = sum:plus(array[i])
--end
--local stop = os.clock()
--print('sum with normal loop took %.2f seconds', stop - start)
--
--local sum = 0
--local start = os.clock()
--local sum = table.combine_values(array, function (sum, value)
--  return sum:plus(value)
--end, Vector:new(2, function (n) return 0 end))
--local stop = os.clock()
--print('sum with combine values took %.2f seconds', stop - start)
