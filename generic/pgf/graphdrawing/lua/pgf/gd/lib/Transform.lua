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
-- The |Transform| table provides a set of static methods for
-- creating and handling canvas transformation matrices. Such a matrix
-- is actually just an array of six numbers. The idea is that
-- ``applying'' an array { a, b, c, d, e, f } a vector $(x,y)$ will
-- yield the new vector $(ax+by+e,cx+dy+f)$. For details on how such
-- matrices work, see Section~\ref{section-transform-cm}
--
local Transform = {}


-- Namespace

require("pgf.gd.model").Transform = Transform


--- Creates a new transformation array.
--
-- @param a First component
-- @param b Second component
-- @param c Third component
-- @param d Fourth component
-- @param x The x shift
-- @param y The y shift
--
-- @return A transformation object.
--
function Transform.new(a,b,c,d,x,y)
  return { a, b, c, d, x, y }
end


--- Creates a new transformation object that represents a shift. 
--
-- @param x An x-shift
-- @param y A y-shift
--
-- @return A transformation object
--
function Transform.new_shift(x,y)
  return { 1, 0, 0, 1, x, y }
end


--- Creates a new transformation object that represents a rotation. 
--
-- @param angle An angle
--
-- @return A transformation object
--
function Transform.new_rotation(angle)
  local c = math.cos(angle)
  local s = math.sin(angle)
  return { c, -s, s, c, 0, 0 }
end


--- Creates a new transformation object that represents a scaling. 
--
-- @param x The horizontal scaling
-- @param y The vertical scaling (if missing, the horizontal scaling is used)
--
-- @return A transformation object
--
function Transform.new_scaling(x_scale, y_scale)
  return { x_scale, 0, 0, y_scale or x_scale, 0, 0 }
end




---
-- Concatenate two transformation matrices, returning the new one.
--
-- @param a The first transformation
-- @param b The second transformation
--
-- @return The transformation representing first applying |b| and then
-- applying |a|.
--
function Transform.concat(a,b)
  local a1, a2, a3, a4, a5, a6, b1, b2, b3, b4, b5, b6 =
    a[1], a[2], a[3], a[4], a[5], a[6], b[1], b[2], b[3], b[4], b[5], b[6]
  return { a1*b1 + a2*b3,  a1*b2 + a2*b4,
	   a3*b1 + a4*b3,  a3*b2 + a4*b4,
	   a1*b5 + a2*b6 + a5,  a3*b5 + a4*b6 + a6 }
end



---
-- Inverts a transformation matrix.
--
-- @param t The transformation.
--
-- @return The inverted transformation
--
function Transform.invert(t)
  local t1, t2, t3, t4 = t[1], t[2], t[3], t[4]
  local idet = 1/(t1*t4 - t2*t3)

  return { t4*idet, -t2*idet, -t3*idet, t1*idet, -t[5], -t[6] }
end


-- Done

return Transform