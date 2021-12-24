local InterfaceToDisplay = pgf.gd.interface.InterfaceToDisplay

--- Wrap InterfaceToDisplay functions to prepend debugging code
local createVertex = InterfaceToDisplay.createVertex
-- here `...` is a vararg expression, 
-- see https://www.lua.org/manual/5.3/manual.html#3.4.11
function InterfaceToDisplay.createVertex(...)
  local name = ...
  debug("Create vertex '%s'", name)
  createVertex(...)
end

local createEdge = InterfaceToDisplay.createEdge
function InterfaceToDisplay.createEdge(...)
  local tail, head, direction = ...
  debug("Create edge '%s' from '%s' to '%s'", direction, tail, head)
  createEdge(...)
end

-- this generates too many debugging lines
-- local createEvent = InterfaceToDisplay.createEvent
-- function InterfaceToDisplay.createEvent(...)
--   local kind = ...
--   debug("Create event '%s'", kind)
--   return createEvent(...)
-- end

local addToVertexOptions = InterfaceToDisplay.addToVertexOptions
function InterfaceToDisplay.addToVertexOptions(...)
  local name = ...
  debug("Add options to vertex '%s'", name)
  addToVertexOptions(...)
end


-- helper
function debug(format_str, ...)
  tex.sprint(string.format("\\pgfgdluainfo{" .. format_str .. "}", ...))
end
