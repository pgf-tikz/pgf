-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

pgf.module("pgf.graphdrawing")

--- @release $Header$

--- This file contains position test cases.

function testNewPosition()
	local p = Position:new()
	assert(p.x == 0 and p.y == 0 and p._relativeTo == nil)
	local p2 = Position:new()
	assert(not (p == p2))
	local p3 = Position:new{x=1, y=2, _relativeTo = p2}
	assert(p3.x == 1 and p3.y == 2 and p3._relativeTo == p2)
end

function testIsAbsPosition()
	local p = Position:new()
	assert(p:isAbsPosition())
	p._relativeTo = p
	assert(not p:isAbsPosition())
end

function testCopyPosition()
	local rel = Position:new()
	local p = Position:new{x=1, y=2, _relativeTo = rel}
	local copy = p:copy()
	assert(copy.x == p.x and copy.y == p.y and copy._relativeTo == p._relativeTo)
end

function testGetAbsPosition()
	local p1 = Position:new{x=2,y=3}
	local x, y = p1:getAbsCoordinates()
	assert(x == p1.x and y == p1.y)
	local p2 = Position:new{x=-1, y = 1}
	p2:relateTo(p1)
	local x, y = p2:getAbsCoordinates()
	assert(x == 1 and y == 4)
end

function testCalcCoordsPosition()
	local p1 = Position:new{x=1, y=2}
	local proot = Position:new{x=0, y=1}
	local x, y = Position.calcCoordsTo(proot, p1)
	assert(x == 1 and y == 1)
end

function testRelateToPosition()
	local p = Position:new{x=1, y=1}
	assert(p._relativeTo == nil)
	local p1 = Position:new{x=1, y=1}
	p:relateTo(p1)
	assert(not p:isAbsPosition() and p1:isAbsPosition())
	assert(p.x == 1 and p.y == 1 and p1.x == 1 and p1.y == 1)
	local p2 = Position:new{x=2, y=2}
	local cp = p:copy()
	p:relateTo(p2, true)
	assert(p2:isAbsPosition() and not p:isAbsPosition())
	assert(p.x == 0 and p.y == 0 and p2.x == 2 and p2.y == 2)
	cp:relateTo(p2)
	assert(p2:isAbsPosition() and not cp:isAbsPosition())
	assert(cp.x == 1 and cp.y == 1 and p2.x == 2 and p2.y == 2)
	cp:relateTo(nil)
	assert(cp._relativeTo == nil)
end

testNewPosition()
testIsAbsPosition()
testCopyPosition()
testGetAbsPosition()
testCalcCoordsPosition()
testRelateToPosition()
