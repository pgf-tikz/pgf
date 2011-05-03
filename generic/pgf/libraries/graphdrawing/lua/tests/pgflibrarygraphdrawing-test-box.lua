-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
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

function testNewBox()
	local box = Box:new{}
	assert(box.pos:x() == 0 and box.pos:y() == 0 and box.width == 0 and box.height == 0)
	local box2 = Box:new{width = 1, height = 2}
	assert(not (box2.pos == box.pos))
	assert(box2.width == 1 and box2.height == 2)
end

function testAddBox()
	local box = Box:new{}
	local boxnew = Box:new{width=10, height=5}
	box:addBox(boxnew)
	assert(boxnew.pos:getOrigin())
	assert(boxnew.pos.origin == box.pos)
	assert(box._boxes[boxnew])
	assert(box.width == boxnew.width and box.height == boxnew.height)
end

function testRemoveBox()
	local box = Box:new{}
	local boxnew = Box:new{width=10, height=5}
	box:addBox(boxnew)
	box:removeBox(boxnew)
	assert(table.count_pairs(box._boxes) == 0)
	assert(not boxnew.pos:getOrigin())
end

function testRecalculateSizeBox()
	local box = Box:new{}
	local boxnew = Box:new{width=10, height=5}
	box:addBox(boxnew)
	assert(box.width == boxnew.width and box.height == boxnew.height)
	box:removeBox(boxnew)
	assert(box.width == 0 and box.height == 0)
end

function testGetPosAtBox()
	local box = Box:new{}
  box.pos:set{x = 10}
  box.pos:set{y = 10}
	local boxnew = Box:new{width=10, height=5}
  boxnew.pos:set{x = 1}
  boxnew.pos:set{y = 1}
	box:addBox(boxnew)
	local ul, ulabs = boxnew:getPosAt(Box.UPPERLEFT), boxnew:getPosAt(Box.UPPERLEFT, true)
  Sys:setVerbose(true)
  Sys:log('ul = ' .. tostring(ul))
  Sys:log('ul.origin = ' .. tostring(ul.origin))
  Sys:log('ulabs = ' .. tostring(ulabs))
  Sys:log('ulabs.origin = ' .. tostring(ulabs.origin))
  Sys:setVerbose(false)
	assert(ul:x() == 1 and ul:y() == 6)
	assert(ul:x() == 1 and ul:y() == 6)
	assert(not (ul == box.pos or ul == boxnew.pos))
	assert(ulabs:x() == ul:x() + box.pos:x() and ulabs:y() == ul:y() + box.pos:y())
	local ur, urabs = boxnew:getPosAt(Box.UPPERRIGHT),
		boxnew:getPosAt(Box.UPPERRIGHT, true)
	assert(ur:x() == 11 and ur:y() == 6)
	assert(urabs:x() == ur:x() + box.pos:x() and urabs:y() == ur:y() + box.pos:y())
	local c, cabs = boxnew:getPosAt(Box.CENTER),
		boxnew:getPosAt(Box.CENTER, true)
	assert(c:x() == 6 and c:y() == 3.5)
	assert(cabs:x() == c:x() + box.pos:x() and cabs:y() == c:y() + box.pos:y())
	local lr, lrabs = boxnew:getPosAt(Box.LOWERRIGHT),
		boxnew:getPosAt(Box.LOWERRIGHT, true)
	assert(lr:x() == 11 and lr:y() == 1)
	assert(lrabs:x() == lr:x() + box.pos:x() and lrabs:y() == lr:y() + box.pos:y())
	local ll, llabs = boxnew:getPosAt(Box.LOWERLEFT),
		boxnew:getPosAt(Box.LOWERLEFT, true)
	assert(ll:x() == 1 and ll:y() == 1)
	assert(llabs:x() == ll:x() + box.pos:x() and llabs:y() == ll:y() + box.pos:y())
end

function testGetPathsBox()
	local box = Box:new{}
	local boxnew = Box:new{}
	box:addBox(boxnew)
	local p1, p2 = Path:new(), Path:new()
	box._paths[p1] = true; boxnew._paths[p2] = true
	local ret = box:getPaths()
	assert(table.count_pairs(ret) == 2)
	assert(ret[p1] and ret[p2])
end

testNewBox()
testAddBox()
testRemoveBox()
testRecalculateSizeBox()
testGetPosAtBox()
testGetPathsBox()
