-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This files defines a box class.  Boxes can contain other boxes.  Used
-- in the algorithm implementations.

pgf.module("pgf.graphdrawing")

Box = {}
Box.__index = Box

Box.UPPERLEFT = "upperleft"
Box.UPPERRIGHT = "upperright"
Box.LOWERLEFT = "lowerleft"
Box.LOWERRIGHT = "lowerright"
Box.CENTER = "center"

--- Creates a new box.
-- @param values Values (e.g. height) to be merged with the default-metatable of a box.
-- @return The new box.
function Box:new(values)
   local defaults = {
      pos = Position:new(),
      _boxes = {},
      _paths = {},
      height = 0,
      width = 0
   }
   setmetatable(defaults, Box)
   local result = mergeTable(values, defaults)
   return result
end

--- Adds new internal Box.
-- @param box The box to be added.
function Box:addBox(box)
   box.pos:relateTo(self.pos)
   self._boxes[box] = true
   self:recalculateSize()
end

--- Removes internal Box.
-- @param box The box to remove.
function Box:removeBox(box)
	box.pos:relateTo(nil)
	self._boxes[box] = nil
	self:recalculateSize()
end

--- Checks internal Boxes and resets width and height.
function Box:recalculateSize()
	local width = 0
	local height = 0
	for box in pairs(self._boxes) do
		local ur = box:getPosAt(Box.UPPERRIGHT)
		width = math.max(width, ur.x)
		height = math.max(height, ur.y)
	end
	self.width = width
	self.height = height
end


--- Calculates the coordinates of the box according to the param place.
-- @param place Determines of which position of the box the coordinates should be returned (e.g. the center of the box requieres the param Box.CENTER). Possible values are:
-- Box.UPPERLEFT, Box.UPPERRIGHT, Box.CENTER, Box.LOWERRIGHT, Box.LOWERLEFT.
-- @param absolute If true the absolute coordinates of the box will be returned, otherwise its relative coordinates. 
-- @return X- and y-coordinates of the box. 
function Box:getPosAt(place, absolute)
	local position = self.pos:copy()
	if(place == Box.UPPERLEFT) then
		position.y = position.y + self.height
	elseif(place == Box.UPPERRIGHT) then
		position.y = position.y + self.height
		position.x = position.x + self.width
	elseif(place == Box.LOWERRIGHT) then
		position.x = position.x + self.width
	elseif(place == Box.CENTER) then
		position.x = position.x + (self.width / 2)
		position.y = position.y + (self.height / 2)
	end
	if absolute then
		position.x, position.y = position:getAbsCoordinates()
		position:relateTo(nil)
	end
	return position
end

--- Provides all Paths this box contains.
-- @return Recursive iteration over all paths.
function Box:getPaths()
	local result = {}
	for box in pairs(self._boxes) do
		result = mergeTable(result, box:getPaths())
	end
	result = mergeTable(result, self._paths)
	return result
end
