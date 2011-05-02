-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file contains a class for defining arbitrary vectors and
--- perform operations on them.

pgf.module('pgf.graphdrawing')



Vector = {}
Vector.__index = Vector



--- Creates a new vector with \meta{n} values using an optional \meta{fill\_function}.
--
-- @param n             The number of elements of the vector.
-- @param fill_function Optional function that takes a number between 1 and \meta{n} 
--                      and is expected to return a value for the corresponding element
--                      of the vector. If omitted, all elements of the vector will 
--                      be initialized with 0.
--
-- @return A newly-allocated vector with \meta{n} elements.
--
function Vector:new(n, fill_function)
  -- create vector
  local vector = {
    elements = {}
  }
  setmetatable(vector, Vector)

  -- fill vector elements with values
  if not fill_function then
    for i = 1,n do
      vector.elements[i] = 0
    end
  else
    for i = 1,n do
      vector.elements[i] = fill_function(i)
    end
  end

  return vector
end



--- Creates a copy of the vector that holds the same elements as the original.
--
-- @return A newly-allocated copy of the vector holding exactly the same elements.
-- 
function Vector:copy()
  return Vector:new(#self.elements, function (n) return self.elements[n] end)
end



--- Convenience method that returns the first element of the vector.
--
-- @return The first element of the vector.
--
function Vector:x()
  return self.elements[1]
end



--- Convenience method that returns the second element of the vector.
--
-- @return The second element of the vector.
-- 
function Vector:y()
  return self.elements[2]
end



--- Performs a vector addition and returns the result in a new vector.
--
-- @param other The vector to add.
--
-- @return A new vector with the result of the addition.
--
function Vector:plus(other)
  assert(#self.elements == #other.elements)

  return Vector:new(#self.elements, function (n)
    return self.elements[n] + other.elements[n]
  end)
end



--- Performs an addition with a scalar value and returns the result in a new vector.
--
-- The scalar value is added to all elements of the vector.
--
-- @param scalar Scalar value to add to all elements.
--
-- @return A new vector with the result of the addition.
--
function Vector:plusScalar(scalar)
  return Vector:new(#self.elements, function (n)
    return self.elements[n] + scalar
  end)
end



--- Subtracts two vectors and returns the result in a new vector.
--
-- @param other Vector to subtract.
--
-- @return A new vector with the result of the subtraction.
--
function Vector:minus(other)
  assert(#self.elements == #other.elements)

  return Vector:new(#self.elements, function (n) 
    return self.elements[n] - other.elements[n]
  end)
end



--- Subtracts a scalar value from a vector and returns the result in a new vector.
--
-- @param scalar Scalar value to subtract from all elements.
--
-- @return A new vector with the result of the subtraction.
--
function Vector:minusScalar(scalar)
  return Vector:new(#self.elements, function (n)
    return self.elements[n] - scalar
  end)
end



--- Performs a vector division and returns the result in a new vector.
--
-- @param other Vector to divide by.
--
-- @return A new vector with the result of the division.
--
function Vector:dividedBy(other)
  assert(#self.elements == #other.elements)

  return Vector:new(#self.elements, function (n)
    return self.elements[n] / other.elements[n]
  end)
end



--- Divides a vector by a scalar value and returns the result in a new vector.
--
-- @param scalar Scalar value to divide the vector by.
--
-- @return A new vector with the result of the division.
--
function Vector:dividedByScalar(scalar)
  return Vector:new(#self.elements, function (n)
    return self.elements[n] / scalar
  end)
end



--- Multiplies a vector by a scalar value and returns the result in a new vector.
--
-- @param scalar Scalar value to multiply the vector with.
--
-- @return A new vector with the result of the multiplication.
--
function Vector:timesScalar(scalar)
  return Vector:new(#self.elements, function (n)
    return self.elements[n] * scalar
  end)
end



--- Performs the dot product of two vectors and returns the result in a new vector.
--
-- @param other Vector to perform the dot product with.
--
-- @return A new vector with the result of the dot product.
--
function Vector:dotProduct(other)
  assert(#self.elements == #other.elements)

  local product = 0
  for n = 1,#self.elements do
    product = product + self.elements[n] * other.elements[n]
  end
  return product
end



--- Computes the Euclidean norm of the vector.
--
-- @return The Euclidean norm of the vector.
--
function Vector:norm()
  return math.sqrt(table.combine_values(self.elements, function (sum, val) 
    return sum + val * val
  end, 0))
end



--- Normalizes the vector and returns the result in a new vector.
--
-- @return Normalized version of the original vector.
--
function Vector:normalized()
  return self:dividedByScalar(self:norm())
end



--- Returns the element at the given \meta{index}.
--
-- @return The element at the given \meta{index}.
--
function Vector:get(index)
  return self.elements[index]
end



--- Changes the element at the given \meta{index}.
--
-- @param index The index of the element to change.
-- @param value New value of the element.
--
function Vector:set(index, value)
  self.elements[index] = value
end



--- Resets all vector elements to 0 in-place.
--
function Vector:reset()
  self:update(function (n, value) return 0 end)
end



--- Updates the values of the vector in-place.
--
-- @param update_function A function that is called for each element of the
--                        vector. The elements are replaced by the values 
--                        returned from this function.
--
function Vector:update(update_function)
  table.update_values(self.elements, update_function)
end



--- Limits all elements of the vector in-place.
--
-- @param limit_function A function that is called for each index/element
--                       pair. It is supposed to return minimum and maximum
--                       values for the element. The element is then clamped
--                       to these values.
--
function Vector:limit(limit_function)
  table.update_values(self.elements, function (n, value)
    local min, max = limit_function(n, value)
    return math.max(min, math.min(max, value))
  end)
end



function Vector:__tostring()
  return '(' .. table.concat(self.elements, ', ') .. ')'
end
