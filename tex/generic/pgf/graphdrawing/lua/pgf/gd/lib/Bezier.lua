-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



---
-- This library offers a number of methods for working with Bezi\'er
-- curves. 

local Bezier = {}

-- Namespace
require("pgf.gd.lib").Bezier = Bezier


-- Imports

local Coordinate = require 'pgf.gd.model.Coordinate'


---
-- Compute a point ``along a curve at a time''. You provide the four
-- coordinates of the curve and a time. You get a point on the curve
-- as return value as well as the two suport vector for curve
-- before this point and two support vectors for the curve after the
-- point.
--
-- For speed reasons and in order to avoid superfluous creation of
-- lots of tables, all values are provided and returned as pairs of
-- values rather than as |Coordinate| objects.
--
-- @param ax The coordinate where the curve starts.
-- @param ay
-- @param bx The first support point.
-- @param by
-- @param cx The second support point.
-- @param cy
-- @param dx The coordinate where the curve ends.
-- @param dy
-- @param t A time (a number).
--
-- @return The point |p| on the curve at time |t| ($x$-part).
-- @return The point |p| on the curve at time |t| ($y$-part).
-- @return The first support point of the curve between |a| and |p| ($x$-part).
-- @return The first support point of the curve between |a| and |p| ($y$-part).
-- @return The second support point of the curve between |a| and |p| ($x$-part).
-- @return The second support point of the curve between |a| and |p| ($y$-part).
-- @return The first support point of the curve between |p| and |d| ($x$-part).
-- @return The first support point of the curve between |p| and |d| ($y$-part).
-- @return The second support point of the curve between |p| and |d| ($x$-part).
-- @return The second support point of the curve between |p| and |d| ($y$-part).

function Bezier.atTime(ax,ay,bx,by,cx,cy,dx,dy,t)

  local s = 1-t

  local ex, ey = ax*s + bx*t, ay*s + by*t
  local fx, fy = bx*s + cx*t, by*s + cy*t
  local gx, gy = cx*s + dx*t, cy*s + dy*t

  local hx, hy = ex*s + fx*t, ey*s + fy*t
  local ix, iy = fx*s + gx*t, fy*s + gy*t

  local jx, jy = hx*s + ix*t, hy*s + iy*t

  return jx, jy, ex, ey, hx, hy, ix, iy, gx, gy
end


---
-- The ``coordinate version'' of the |atTime| function, where both the
-- parameters and the return values are coordinate objects.

function Bezier.atTimeCoordinates(a,b,c,d,t)
  local jx, jy, ex, ey, hx, hy, ix, iy, gx, gy =
    Bezier.atTime(a.x,a.y,b.x,b.y,c.x,c.y,d.x,d.y,t)

  return
    Coordinate.new(jx, jy),
    Coordinate.new(ex, ey),
    Coordinate.new(hx, hy),
    Coordinate.new(ix, iy),
    Coordinate.new(gx, gy)
end


---
-- Computes the support points of a Bezier curve based on two points
-- on the curves at certain times.
--
-- @param from The start point of the curve
-- @param p1 A first point on the curve
-- @param t1 A time when this point should be reached
-- @param p2 A second point of the curve
-- @param t2 A time when this second point should be reached
-- @param to The end of the curve
--
-- @return sup1 A first support point of the curve
-- @return sup2 A second support point of the curve

function Bezier.supportsForPointsAtTime(from, p1, t1, p2, t2, to)

  local s1 = 1 - t1
  local s2 = 1 - t2

  local f1a = s1^3
  local f1b = t1 * s1^2 * 3
  local f1c = t1^2 * s1 * 3
  local f1d = t1^3
  
  local f2a = s2^3
  local f2b = t2 * s2^2 * 3
  local f2c = t2^2 * s2 * 3
  local f2d = t2^3

  -- The system:
  -- p1.x - from.x * f1a - to.x * f1d = sup1.x * f1b + sup2.x * f1c
  -- p2.x - from.x * f2a - to.x * f2d = sup1.x * f2b + sup2.x * f2c
  --
  -- p1.y - from.y * f1a - to.y * f1d = sup1.y * f1b + sup2.y * f1c
  -- p2.y - from.y * f2a - to.y * f2d = sup1.y * f2b + sup2.y * f2c
  
  local a = f1b
  local b = f1c
  local c = p1.x - from.x * f1a - to.x * f1d
  local d = f2b
  local e = f2c
  local f = p2.x - from.x * f2a - to.x * f2d

  local det = a*e - b*d
  local x1 = -(b*f - e*c)/det
  local x2 = -(c*d - a*f)/det
  
  local c = p1.y - from.y * f1a - to.y * f1d
  local f = p2.y - from.y * f2a - to.y * f2d
  
  local det = a*e - b*d
  local y1 = -(b*f - e*c)/det
  local y2 = -(c*d - a*f)/det

  return Coordinate.new(x1,y1), Coordinate.new(x2,y2)
  
end






-- Done

return Bezier