-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- 
-- A Coordinate models a position on the drawing canvas.
--
-- It has an |x| field and a |y| field, which are numbers that will be
-- interpreted as \TeX\ points (1/72.27th of an inch). The $x$-axis goes
-- right and the $y$-axis goes up.
--
-- @field x 
-- @field y 

local Coordinate = {}
Coordinate.__index = Coordinate


-- Namespace

require("pgf.gd.model").Coordinate = Coordinate




--- Creates a new coordinate.
--
-- @param x The $x$ value
-- @param y The $y$ value
--
-- @return A coordinate
--
function Coordinate.new(x,y)
  local new = { x = x, y = y }
  setmetatable(new, Coordinate)
  return new
end


--- Creates a new coordinate that is a copy of an existing one.
--
-- @return A new coordinate at the same location as |self|
--
function Coordinate:clone()
  local new = { x = self.x, y = self.y }
  setmetatable(new, Coordinate)
  return new
end



--- Apply a transformation matrix to a coordinate,
-- see |pgf.gd.lib.Transform| for details.
--
-- @param t A tansformation

function Coordinate:apply(t)
  local x = self.x
  local y = self.y
  self.x = t[1]*x + t[2]*y + t[5]
  self.y = t[3]*x + t[4]*y + t[6]
end



--- Shift a coordinate
--
-- @param a An $x$ offset
-- @param b A $y$ offset 

function Coordinate:shift(a,b)
  self.x = self.x + a
  self.y = self.y + b
end



--- Compute a bounding box around an array of coordinates
--
-- @param array An array of coordinates
--
-- @return |min_x| The minimum $x$ value of the bounding box of the array
-- @return |min_y| The minimum $y$ value
-- @return |max_x|
-- @return |max_y|
-- @return |center_x| The center of the bounding box
-- @return |center_y| 

function Coordinate:boundingBox(array)
  if #array > 0 then
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge
    
    for i=1,#array do
      local c = array[i]
      local x = c.x
      local y = c.y
      if x < min_x then min_x = x end
      if y < min_y then min_y = y end
      if x > max_x then max_x = x end
      if y > max_y then max_y = y end
    end
    
    return min_x, min_y, max_x, max_y, (min_x+max_x) / 2, (min_y+max_y) / 2
  end
end




-- Returns a string representation of an arc. This is mainly for debugging
--
-- @return The Arc as string.
--
function Coordinate:__tostring()
  return "(" .. self.x .. "pt," .. self.y .. "pt)"
end


-- Done

return Coordinate