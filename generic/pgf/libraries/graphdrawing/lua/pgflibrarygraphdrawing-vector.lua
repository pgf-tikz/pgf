-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

pgf.module('pgf.graphdrawing')



Vector = {}
Vector.__index = Vector



function Vector:new(n, fill_function)
  -- create vector
  local vector = {
    values = {}
  }
  setmetatable(vector, Vector)

  -- fill vector with values
  for i = 1,n do
    vector.values[i] = fill_function(i)
  end

  return vector
end



function Vector:subtract(other)
  assert(#self.values == #other.values)

  return Vector:new(#self.values, function (n) 
    return self.values[n] - other.values[n]
  end)
end



function Vector:computeNorm()
  local sum = 0
  for _, value in ipairs(self.values) do
    sum = sum + value * value
  end
  return math.sqrt(sum)
end



function Vector:get(index)
  return self.values[index]
end



function Vector:set(index, value)
  self.values[i] = value
end



function Vector:update(update_function)
  for n, value in ipairs(self.values) do
    self.values[n] = update_function(n, value)
  end
end



function Vector:limit(limit_function)
  for n, value in ipairs(self.values) do
    local range = limit_function(n, value)
    self.values[n] = math.max(range.min, math.min(range.max, value))
  end
end



function Vector:limitAll(min, max)
  for n, value in ipairs(self.values) do
    self.values[n] = math.max(min, math.min(max, value))
  end
end



function Vector:__tostring()
  return '(' .. table.concat(self.values, ', ') .. ')'
end
