-- Copyright 2011 by Jannis Pohlmann
-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- A Stack is a very simple wrapper around an array
--
-- 

local Stack = {}
Stack.__index = Stack


-- Namespace
local lib = require "pgf.gd.lib"
lib.Stack = Stack


--- Create a new stack
function lib.Stack:new()
  local stack = {}
  setmetatable(stack, lib.Stack)
  return stack
end


--- Push an element on top of the stack
function lib.Stack:push(data)
  self[#self+1] = data
end


--- Inspect (but not pop) the top element of a stack
function lib.Stack:peek()
  return self[#self]
end


--- Pop an element from the top of the stack
function lib.Stack:pop()
  return table.remove(self, #self)
end


--- Get the height of the stack
function lib.Stack:getSize()
  return #self
end



-- done

return lib.Stack