-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

--- This file contains path test cases.

pgf.module("pgf.graphdrawing")

function testNewPath()
	local path = Path:new()
	assert(#path._points == 0)
	local point = Position:new{}
	local path2 = Path:new{_points = {point}}
	assert(#path2._points == 1)
end

function testGetPointsPath()
	local point = Position:new{}
	local path = Path:new{_points = {point}}
	local tab = path:getPoints()
	assert(#tab == 1)
	assert(tab[1] == point)
end

function testAddPointPath()
	local path = Path:new()
	local point1 = Position:new()
	local point2 = Position:new{x=1,y=1}
	path:addPoint(point1)
	assert(#path:getPoints() == 1)
	assert(path:getPoints()[1] == point1)
	assert(point1:isAbsPosition())
	assert(point2:isAbsPosition())
	path:addPoint(point2)
	assert(not point2:isAbsPosition())
	assert(point2._relativeTo == point1)
	assert(point2.x == 1 and point2.y == 1)
	local point3 = Position:new{x=3,y=3}
	path:addPoint(point3, true)
	assert(not point3:isAbsPosition())
	assert(point3._relativeTo == point2)
	assert(point3.x == 2 and point3.y == 2)
end

function testGetLastPointPath()
	local path = Path:new()
	local point1 = Position:new()
	local point2 = Position:new{x=1,y=1}
	path:addPoint(point1)
	assert(path:getLastPoint() == point1)
	path:addPoint(point2)
	assert(path:getLastPoint() == point2)
end

function testMovePath()
	local path = Path:new()
	local point1 = Position:new()
	local point2 = Position:new{x=1,y=1}
	path:addPoint(point1)
	path:addPoint(point2)
	path:move(2, -1)
	assert(#path:getPoints() == 3)
	assert(path:getLastPoint()._relativeTo == point2)
	assert(path:getLastPoint().x == 2 and path:getLastPoint().y == -1)
end

function testIntersects()
   local path1 = Path:new()
   local path2 = Path:new()
   local path3 = Path:new()
   local path5 = Path:new()
   local path6 = Path:new()
   
   
   --Dreieck
   local path7 = Path:new()
   path7:addPoint(Position:new{x=0,y=0})
   path7:addPoint(Position:new{x=0,y=1})
   local path8 = Path:new()
   path8:addPoint(Position:new{x=0,y=0})
   path8:addPoint(Position:new{x=1,y=0})
   local path9 = Path:new()
   path9:addPoint(Position:new{x=0,y=1})
   path9:addPoint(Position:new{x=1,y=0})
   
   assert(not path7:intersects(path8))
   assert(not path8:intersects(path7))
   assert(not path9:intersects(path8))
   assert(not path9:intersects(path7))
   
   --Drei Pfade auf einer Linie
   local path10 = Path:new()
   path10:addPoint(Position:new{x=0,y=0})
   path10:addPoint(Position:new{x=0,y=2})
   local path11 = Path:new()
   path11:addPoint(Position:new{x=0,y=0})
   path11:addPoint(Position:new{x=0,y=1})
   local path12 = Path:new()
   path12:addPoint(Position:new{x=0,y=1})
   path12:addPoint(Position:new{x=0,y=2})
   
   assert(path10:intersects(path11))
   assert(path10:intersects(path12))
   assert(path11:intersects(path12))

   -- Test with two points per path
   path1:addPoint(Position:new{x=0,y=0})
   path1:addPoint(Position:new{x=2,y=0})
   
   path2:addPoint(Position:new{x=0,y=1})
   path2:addPoint(Position:new{x=2,y=1})
   
   path3:addPoint(Position:new{x=1,y=2})
   path3:addPoint(Position:new{x=1,y=-1})
   
   path5:addPoint(Position:new{x=0,y=5})
   path5:addPoint(Position:new{x=7,y=4})
   
   path6:addPoint(Position:new{x=0,y=0})
   path6:addPoint(Position:new{x=-1,y=-1})

   assert(not path6:intersects(path1))
   assert(not path1:intersects(path6))
   
   assert(not path1:intersects(path2))
   assert(not path2:intersects(path1))
   
   assert(path1:intersects(path3))
   assert(path3:intersects(path1))
   
   assert(path2:intersects(path3))
   assert(path3:intersects(path2))
   
   assert(path3:intersects(path3))
   
   assert(not path5:intersects(path1))
   assert(not path1:intersects(path5))

   -- Test with three points per path
   local path4 = Path:new()
   path4:addPoint(Position:new{x=-1,y=-1})
   path4:addPoint(Position:new{x=1,y=-1})
   path4:addPoint(Position:new{x=1,y=3})

   assert(path4:intersects(path1))
   assert(path1:intersects(path4))
end

testNewPath()
testGetPointsPath()
testAddPointPath()
testGetLastPointPath()
testMovePath()
testIntersects()
