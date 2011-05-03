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

--- This file contains path test cases.

pgf.module("pgf.graphdrawing")

function testNewPath()
	local path = Path:new()
	assert(#path._points == 0)
	local point = Vector:new(2)
	local path2 = Path:new{_points = {point}}
	assert(#path2._points == 1)
end

function testGetPointsPath()
	local point = Vector:new(2)
	local path = Path:new{_points = {point}}
	local tab = path:getPoints()
	assert(#tab == 1)
	assert(tab[1] == point)
end

function testAddPointPath()
	local path = Path:new()
	local point1 = Vector:new(2)
	local point2 = Vector:new(2, function (n) return 1 end)
	path:addPoint(point1)
	assert(#path:getPoints() == 1)
	assert(path:getPoints()[1] == point1)
	assert(not point1:getOrigin())
	assert(not point2:getOrigin())
	path:addPoint(point2)
	assert(point2:getOrigin())
	assert(point2.origin == point1)
	assert(point2:x() == 1 and point2:y() == 1)
	local point3 = Vector:new(2, function (n) return 3 end)
	path:addPoint(point3, true)
	assert(point3:getOrigin())
	assert(point3.origin == point2)
	assert(point3:x() == 2 and point3:y() == 2)
end

function testGetLastPointPath()
	local path = Path:new()
	local point1 = Vector:new(2)
	local point2 = Vector:new(2, function (n) return 1 end)
	path:addPoint(point1)
	assert(path:getLastPoint() == point1)
	path:addPoint(point2)
	assert(path:getLastPoint() == point2)
end

function testMovePath()
	local path = Path:new()
	local point1 = Vector:new(2)
	local point2 = Vector:new(2, function (n) return 1 end)
	path:addPoint(point1)
	path:addPoint(point2)
	path:move(2, -1)
	assert(#path:getPoints() == 3)
	assert(path:getLastPoint().origin == point2)
	assert(path:getLastPoint():x() == 2 and path:getLastPoint():y() == -1)
end

function testIntersects()
   local path1 = Path:new()
   local path2 = Path:new()
   local path3 = Path:new()
   local path5 = Path:new()
   local path6 = Path:new()
   
   
   --Dreieck
   local path7 = Path:new()
   path7:addPoint(Vector:new(2, function (n) return ({0, 0})[n] end))
   path7:addPoint(Vector:new(2, function (n) return ({0, 1})[n] end))
   local path8 = Path:new()
   path8:addPoint(Vector:new(2, function (n) return ({0, 0})[n] end))
   path8:addPoint(Vector:new(2, function (n) return ({1, 0})[n] end))
   local path9 = Path:new()
   path9:addPoint(Vector:new(2, function (n) return ({0, 1})[n] end))
   path9:addPoint(Vector:new(2, function (n) return ({1, 0})[n] end))
   
   assert(not path7:intersects(path8))
   assert(not path8:intersects(path7))
   assert(not path9:intersects(path8))
   assert(not path9:intersects(path7))
   
   --Drei Pfade auf einer Linie
   local path10 = Path:new()
   path10:addPoint(Vector:new(2, function (n) return ({0, 0})[n] end))
   path10:addPoint(Vector:new(2, function (n) return ({0, 2})[n] end))
   local path11 = Path:new()
   path11:addPoint(Vector:new(2, function (n) return ({0, 0})[n] end))
   path11:addPoint(Vector:new(2, function (n) return ({0, 1})[n] end))
   local path12 = Path:new()
   path12:addPoint(Vector:new(2, function (n) return ({0, 1})[n] end))
   path12:addPoint(Vector:new(2, function (n) return ({0, 2})[n] end))
   
   assert(path10:intersects(path11))
   assert(path10:intersects(path12))
   assert(path11:intersects(path12))

   -- Test with two points per path
   path1:addPoint(Vector:new(2, function (n) return ({0, 0})[n] end))
   path1:addPoint(Vector:new(2, function (n) return ({2, 0})[n] end))
   
   path2:addPoint(Vector:new(2, function (n) return ({0, 1})[n] end))
   path2:addPoint(Vector:new(2, function (n) return ({2, 1})[n] end))
   
   path3:addPoint(Vector:new(2, function (n) return ({1, 2})[n] end))
   path3:addPoint(Vector:new(2, function (n) return ({1, -1})[n] end))
   
   path5:addPoint(Vector:new(2, function (n) return ({0, 5})[n] end))
   path5:addPoint(Vector:new(2, function (n) return ({7, 4})[n] end))
   
   path6:addPoint(Vector:new(2, function (n) return ({0, 0})[n] end))
   path6:addPoint(Vector:new(2, function (n) return ({-1, -1})[n] end))

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
   path4:addPoint(Vector:new(2, function (n) return ({-1, -1})[n] end))
   path4:addPoint(Vector:new(2, function (n) return ({1, -1})[n] end))
   path4:addPoint(Vector:new(2, function (n) return ({1, 3})[n] end))

   assert(path4:intersects(path1))
   assert(path1:intersects(path4))
end

testNewPath()
testGetPointsPath()
testAddPointPath()
testGetLastPointPath()
testMovePath()
testIntersects()
