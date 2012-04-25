-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- The Coordinate class
--
-- A Coordinate models a position on the drawing canvas.
--
-- It has an x field and a y field, which are numbers that will be
-- interpreted as TeX points (1/72.27th of an inch). The x-axis goes
-- right and the y-axis goes up.

local Coordinate = {}
Coordinate.__index = Coordinate


-- Namespace

require("pgf.gd.model").Coordinate = Coordinate


--- Creates a new coordinate.
--
-- @param x The x value
-- @param y The y value
--
-- @return A coordinate
--
function Coordinate:new(x,y)
  local new = { x = x, y = y }
  setmetatable(new, Coordinate)
  return new
end


--- Shift a coordinate by another coordinate or by an x and a y value.
--
-- @param a Either an x offset or a coordinate
-- @param b The y offset value
--
-- @return A coordinate
--
function Coordinate:shift(a,b)
  if b then
    self.x = self.x + a
    self.y = self.y + b
  else
    self.x = self.x + a.x
    self.y = self.y + a.y
  end
end



--- Returns a string representation of an arc. This is mainly for debugging
--
-- @return The Arc as string.
--
function Coordinate:__tostring()
  return "(" .. self.x .. "pt," .. self.y .. "pt)"
end


-- Done

return Coordinate