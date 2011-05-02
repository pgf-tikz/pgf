-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

--- This file contains a class for defining arbitrary vectors and
--- perform operations on them.

pgf.module('pgf.graphdrawing')



Vector = {}
Vector.__index = Vector



function Vector:new(n, fill_function)
  -- create vector
  local vector = {
    elements = {}
  }
  setmetatable(vector, Vector)

  -- fill vector elements with values
  for i = 1,n do
    vector.elements[i] = fill_function(i)
  end

  return vector
end



function Vector:subtract(other)
  assert(#self.elements == #other.elements)

  return Vector:new(#self.elements, function (n) 
    return self.elements[n] - other.elements[n]
  end)
end



function Vector:dotProduct(other)
  assert(#self.elements == #other.elements)

  local product = 0
  for n = 1,#self.elements do
    product = product + self.elements[n] * other.elements[n]
  end
  return product
end



function Vector:norm()
  return math.sqrt(table.combine_values(self.elements, function (sum, val) 
    return sum + val * val
  end, 0))
end



function Vector:get(index)
  return self.elements[index]
end



function Vector:set(index, value)
  self.elements[index] = value
end



function Vector:update(update_function)
  table.update_values(self.elements, update_function)
end



function Vector:limit(limit_function)
  table.update_values(self.elements, function (n, value)
    local min, max = limit_function(n, value)
    return math.max(min, math.min(max, value))
  end)
end



function Vector:__tostring()
  return '(' .. table.concat(self.elements, ', ') .. ')'
end
