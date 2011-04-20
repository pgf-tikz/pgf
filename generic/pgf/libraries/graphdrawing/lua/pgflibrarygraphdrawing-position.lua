-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file defines a position class, representing absolute and
-- relative positions.

pgf.module("pgf.graphdrawing")

Position = {}
Position.__index = Position

--- Represents a relative postion.
-- @param values Values (e.g. x- and y-coordinate) to be merged with the default-metatable of a position.
-- @return A new position object.
function Position:new(values)
	local default = {x = 0, y = 0, _relativeTo = nil}
	setmetatable(default, Position)
	local result = mergeTable(values, default)
	return result;
end

--- Determines if the position is absolute.
-- @return True if the position is absolute, else false.
function Position:isAbsPosition()
	return not self._relativeTo
end

--- Creates a copy of this position object.
-- @return Copy of the position.
function Position:copy()
	return Position:new{x = self.x, y = self.y,
		_relativeTo = self._relativeTo}
end

--- Computes absolute coordinates of a position.
-- @param x Just used internally for recrusion.
-- @param y Just used internally for recrusion.
-- @return Absolute position.
function Position:getAbsCoordinates(x, y)
	local x = self.x + (x or 0)
	local y = self.y + (y or 0)
	if not self._relativeTo then
		return x, y
	else
		return self._relativeTo:getAbsCoordinates(x, y)
	end
end

--- Returns a vector between two positions.
-- @param posFrom Position A.
-- @param posTo Position B.
-- @return x- and y-coordinates of the vector between posFrom and posTo.
function Position.calcCoordsTo(posFrom, posTo)
	local sx, sy = posFrom:getAbsCoordinates()
	local px, py = posTo:getAbsCoordinates()
	return px - sx, py - sy
end

--- Relates a position to the given position.
-- @param pos The relative position.
-- @param keepAbsPosition If true, the coordinates of the position are computed 
--in the relation to the given position pos.
function Position:relateTo(pos, keepAbsPosition)
	if keepAbsPosition and pos then
		self.x, self.y = Position.calcCoordsTo(pos, self)
	end
	self._relativeTo = pos
end

--- Returns a readable string representation of the position.
-- @return string representation of the position.
-- @ignore This should not appear in the documentation.
function Position:__tostring()
   return "(" .. self.x .. "," .. self.y .. ")"
end

--- Returns a boolean value whether the object is equal to the given position.
-- @return true if the position is equal to the given position pos.
function Position:equals(pos)
   sx, sy = self:getAbsCoordinates()
   tx, ty = pos:getAbsCoordinates()
   return sx == tx and sy == ty
end
