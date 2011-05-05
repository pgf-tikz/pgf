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
-- @param origin        Optional origin vector.
--
-- @return A newly-allocated vector with \meta{n} elements.
--
function Vector:new(n, fill_function, origin)
  -- create vector
  local vector = {
    elements = {},
    origin = origin or nil,
  }
  setmetatable(vector, Vector)

  if type(n) == 'table' then
    vector:set(n)
  else
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
  end

  return vector
end



--- Creates a copy of the vector that holds the same elements as the original.
--
-- @return A newly-allocated copy of the vector holding exactly the same elements.
-- 
function Vector:copy()
  return Vector:new(#self.elements, function (n) return self.elements[n] end, self.origin)
end



--- Convenience method that returns the first element of the vector.
--
-- The origin vector is not resolved in this function call.
--
-- @return The first element of the vector.
--
function Vector:x()
  return self.elements[1]
end



--- Convenience method that returns the second element of the vector.
--
-- The origin vector is not resolved in this function call.
--
-- @return The second element of the vector.
-- 
function Vector:y()
  return self.elements[2]
end



--- Performs a vector addition and returns the result in a new vector.
--
-- @param other The vector to add. If this vector is defined relative
--              to an origin, then that origin is resolved when 
--              computing the sum of the two vectors. The sum becomes
--              |self + other.origin + other|. The origin of |self|
--              is preserved.
--
-- @return A new vector with the result of the addition.
--
function Vector:plus(other)
  assert(#self.elements == #other.elements)

  return Vector:new(#self.elements, function (n)
    return self.elements[n] + other:get(n)
  end, self.origin)
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
  end, self.origin)
end



--- Subtracts two vectors and returns the result in a new vector.
--
-- @param other Vector to subtract. If this vector is defined relative
--              to an origin, then that origin is resolved when 
--              computing the subtraction of the two vectors. The
--              result becomes |self + other.origin + other|. The origin
--              of |self| is preserved.
--
-- @return A new vector with the result of the subtraction.
--
function Vector:minus(other)
  assert(#self.elements == #other.elements)

  return Vector:new(#self.elements, function (n) 
    return self.elements[n] - other:get(n)
  end, self.origin)
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
  end, self.origin)
end



--- Performs a vector division and returns the result in a new vector.
--
-- The possible origins of the vector operands are resolved
-- and are dropped in the result vector.
--
-- @param other Vector to divide by.
--
-- @return A new vector with the result of the division.
--
function Vector:dividedBy(other)
  assert(#self.elements == #other.elements)

  return Vector:new(#self.elements, function (n)
    return self:get(n) / other:get(n)
  end)
end



--- Divides a vector by a scalar value and returns the result in a new vector.
--
-- The possible origin of the vector is resolved and is 
-- dropped in the result vector.
--
-- @param scalar Scalar value to divide the vector by.
--
-- @return A new vector with the result of the division.
--
function Vector:dividedByScalar(scalar)
  return Vector:new(#self.elements, function (n)
    return self:get(n) / scalar
  end)
end



--- Multiplies a vector by a scalar value and returns the result in a new vector.
--
-- The possible origin of the vector is resolved and is dropped
-- in the result vector.
--
-- @param scalar Scalar value to multiply the vector with.
--
-- @return A new vector with the result of the multiplication.
--
function Vector:timesScalar(scalar)
  return Vector:new(#self.elements, function (n)
    return self:get(n) * scalar
  end)
end



--- Performs the dot product of two vectors and returns the result in a new vector.
--
-- The possible origins of the vector operands are resolved
-- during the compuation.
--
-- @param other Vector to perform the dot product with.
--
-- @return A new vector with the result of the dot product.
--
function Vector:dotProduct(other)
  assert(#self.elements == #other.elements)

  local product = 0
  for n = 1,#self.elements do
    product = product + self:get(n) * other:get(n)
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
-- The possible origin of the vector is resolved during
-- the computation and is dropped in the result vector.
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
  if self.origin then
    local current_origin = self.origin
    local value = 0
    while current_origin do
      value = value + self.origin.elements[index]
      current_origin = current_origin.origin
    end
    return value + self.elements[index]
  else
    return self.elements[index]
  end
end



--- Changes the element at the given \meta{index}.
--
-- @param index The index of the element to change.
-- @param value New value of the element.
--
function Vector:set(index, value)
  if type(index) == 'table' then
    if index.x or index.y then
      if index.x then
        self.elements[1] = index.x
      end
      if index.y then
        self.elements[2] = index.y
      end
    else
      for i = 1,#index do
        self.elements[i] = index[i]
      end
    end
  else
    self.elements[index] = value
  end
end



--- Resets all vector elements to 0 in-place.
--
-- This does not reset the origin vector.
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



--- Sets the origin of the vector.
--
-- @param origin          Vector to use as the origin.
-- @param preserve_values Optional flag. If set to |true|, the origin
--                        will be set and the current elements of the
--                        vector will be changed so that the sum of
--                        the origin and the new element values is equal
--                        to the old values.
--
function Vector:setOrigin(origin, preserve_values)
  assert(not origin or #self.elements == #origin.elements)
  assert(origin ~= self)

  if preserve_values then
    self:update(function (n) return self:get(n) - origin:get(n) end)
  end

  self.origin = origin
end



--- Gets the origin of the vector.
--
-- @return Origin of the vector or |nil| if none is set.
--
function Vector:getOrigin()
  return self.origin
end



function Vector:__tostring()
  if self.origin then
    local values = table.map(self.elements, function (n, element)
      return tostring(self:get(n))
    end)
    return '(' .. table.concat(values, ', ') .. ')'
  else
    return '(' .. table.concat(self.elements, ', ') .. ')'
  end
end



function Vector:equals(other)
  if #self.elements ~= #other.elements then
    return false
  end

  for n = 1, #self.elements do
    if self.elements[n] ~= other.elements[n] then
      return false
    end
  end

  return true
end
