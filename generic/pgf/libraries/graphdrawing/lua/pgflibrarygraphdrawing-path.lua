-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file defines a path class, containing multiple points.  It is
-- used in the algorithm implementations.

pgf.module("pgf.graphdrawing")

Path = {}
Path.__index = Path

--- Creates a new path.
-- @param values Values to be merged with the default-metatable of a path
-- @return A new path.
function Path:new(values)
   local defaults = {
      _points = {}
   }
   setmetatable(defaults, Path)
   local result = table.custom_merge(values, defaults)
   return result
end

--- Adds a new segment to the path.
-- @param posStart Startposition of the new segment
-- @param posEnd Endposition of the new segment
-- @keepAbsPosition true if the coordinates are not set in relation to others
function Path:createPath(posStart, posEnd, keepAbsPosition)
   path = Path:new()
   path:addPoint(posStart, keepAbsPosition)
   path:addPoint(posEnd, keepAbsPosition)
   return path
end

--- Copies the internal points of a path.
-- @return array of points
function Path:getPoints()
	return table.custom_copy(self._points)
end

--- Appends new point at the end of path.
-- @param point Point to be added to the path
-- @param keepAbsPosition true if the coordinates of the point are absolute
function Path:addPoint(point, keepAbsPosition)
	if #self._points > 0 then
		point:setOrigin(self._points[#self._points], keepAbsPosition)
	end
	table.insert(self._points, point)
end

--- Returns last point in path.
-- @return last point
function Path:getLastPoint()
	if #self._points > 0 then
		return self._points[#self._points]
	end
end

--- Adds new point with x,y relative to last point.
-- @param x x-coordinate of the new point
-- @param y y-coordinate of the new point
function Path:move(x,y)
	local newPos = Vector:new(2, function (n) return ({x, y})[n] end)
	self:addPoint(newPos)
end

--- Checks if the lines a1a2 and b1b2 intersect.
-- @param a1 Start of the first line.
-- @param a2 End of the first line.
-- @param b1 Start of the second line.
-- @param b2 End of the second line.
-- @param allowedIntersections A boolean table with the keys a1, a2, b1 and b2.
--        If two or three of those values are true, the corresponding start
--        and/or end points are allowed to match without being seen as
--        intersection.
--        If all four keys are true any matching of start and end points is
---       allowed as long as the two lines are not coincedent.
--        If three of the keys are true or start and end of a line are
--        allowed to match, nill will be returned.
--        If this optional parameter is not given, any matching points will be
--        seen as intersections.
-- @return true, if lines intersect, false otherwise. If allowedIntersections
--         contained an invalid value, nil will be returned.
function Path:_intersects(a1, a2, b1, b2, allowedIntersections)
   if allowedIntersections == nil then
      allowedIntersections = {a1 = false, a2 = false, b1 = false, b2 = false}
   end

   -- denominator for for the parameters ua and ub are the same
   local d = (b2:y() - b1:y()) * (a2:x() - a1:x()) - (b2:x() - b1:x()) * (a2:y() - a1:y())

   -- nominators
   local n_a = (b2:x() - b1:x()) * (a1:y() - b1:y()) - (b2:y() - b1:y()) * (a1:x() - b1:x())
   local n_b = (a2:x() - a1:x()) * (a1:y() - b1:y()) - (a2:y() - a1:y()) * (a1:x() - b1:x())

   if n_a == 0 and n_b == 0 and d == 0 then
      -- lines are coincident
      return true
   elseif d == 0 then
      -- lines are not coincident, but parallel
      return false
   end

   -- calculate intersesection point
   local ua = n_a / d
   local ub = n_b / d

   -- handle allowed intersections
   -- two points allowed
   if allowedIntersections["a1"] and allowedIntersections["b1"] and
      not allowedIntersections["a2"] and not allowedIntersections["b2"] then
      if a1:x() == b1:x() and a1:y() == b1:y() then
         return false
      end
   elseif allowedIntersections["a2"] and allowedIntersections["b2"] and
      not allowedIntersections["a1"] and not allowedIntersections["b1"] then
      if a2:x() == b2:x() and a2:y() == b2:y() then
         return false
      end
   elseif allowedIntersections["a1"] and allowedIntersections["b2"] and
      not allowedIntersections["a2"] and not allowedIntersections["b1"] then
      if a1:x() == b2:x() and a1:y() == b2:y() then
         return false
      end
   elseif allowedIntersections["a2"] and allowedIntersections["b1"] and
      not allowedIntersections["a1"] and not allowedIntersections["b2"] then
      if a2:x() == b1:x() and a2:y() == b1:y() then
         return false
      end
   -- three points allowed
   elseif not allowedIntersections["a1"] and allowedIntersections["b1"] and
      allowedIntersections["a2"] and allowedIntersections["b2"] then
      if (a2:x() == b1:x() and a2:y() == b1:y()) or (a2:x() == b2:x() and a2:y() == b2:y()) then
         return false
      end
   elseif allowedIntersections["a1"] and not allowedIntersections["b1"] and
      allowedIntersections["a2"] and allowedIntersections["b2"] then
      if (b2:x() == a1:x() and b2:y() == a1:y()) or (b2:x() == a1:x() and b2:y() == a1:y()) then
         return false
      end
   elseif not allowedIntersections["a1"] and allowedIntersections["b1"] and
      not allowedIntersections["a2"] and allowedIntersections["b2"] then
      if (a1:x() == b1:x() and a1:y() == b1:y()) or (a1:x() == b2:x() and a1:y() == b2:y()) then
        return false
      end
   elseif not allowedIntersections["a1"] and allowedIntersections["b1"] and
      allowedIntersections["a2"] and not allowedIntersections["b2"] then
      if (b1:x() == a1:x() and b1:y() == a1:y()) or (b1:x() == a1:x() and b1:y() == a1:y()) then
         return false
      end
   -- four points allowed
   elseif allowedIntersections["a1"] and allowedIntersections["a2"] and
      allowedIntersections["b1"] and allowedIntersections["b2"] then
      if (a1:x() == b1:x() and a1:y() == b1:y()) or (a1:x() == b2:x() and a1:y() == b2:y()) or
         (a2:x() == b1:x() and a2:y() == b1:y()) or (a2:x() == b2:x() and a2:y() == b2:y()) then
         return false
      end
   else
      -- invalid configuration of allowedIntersecions
      return nil
   end

   -- check if intersection is within range of lines
   if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then
      return true
   end

   return false
end

--- Tests if the path is intersected by path.
-- @param path other path
function Path:intersects(path)
   local firstPoint = false
   local pathPoints = path:getPoints()
   for i=1,#self._points - 1 do
      for j=1,#pathPoints - 1 do
         local allowedIntersections = {a1 = false, a2 = false, b1 = false, b2 = false}
         -- first and last point of the two paths are allowed to match
         if i == 1 then
            if j == 1 then
               allowedIntersections["a1"] = true
	       allowedIntersections["b1"] = true
            end
            if j == #pathPoints - 1 then
               allowedIntersections["a1"] = true
               allowedIntersections["b2"] = true
            end
         end
         if i == #self._points - 1 then
            if j == #pathPoints - 1 then
               allowedIntersections["a2"] = true
               allowedIntersections["b2"] = true
            end
            if j == 1 then
               allowedIntersections["a2"] = true
               allowedIntersections["b1"] = true
            end
         end
         if self:_intersects(self._points[i], self._points[i+1],
                             pathPoints[j], pathPoints[j+1],
                             allowedIntersections) then
            return true
         end
      end
   end
   return false
end

--- Returns a readable string representation of the path.
-- @return String representation of the path
-- @ignore This should not appear in the documentation.
function Path:__tostring()
   local t = {}
   for v in table.value_iter(self._points) do
      t[#t+1] = tostring(v)
   end
   return table.concat(t, " ")
end


--- Returns the length of the whole path.
-- @return Length of the whole path.
function Path:getLength()
   local length = 0
   for pidx = 1, #self._points-1 do
      local a = self._points[pidx]
      local b = self._points[pidx+1]
      length = length + math.sqrt(math.pow(a:x()-b:x(),2)+math.pow(a:y()-b:y(),2))
   end
   return length
end
