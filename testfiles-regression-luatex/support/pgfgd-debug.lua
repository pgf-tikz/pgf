local InterfaceToDisplay = assert(pgf.gd.interface.InterfaceToDisplay)

-- helper
local function typeout(...)
  texio.write_nl(17, "Gd Lua layer Info: " .. string.format(...))
end

local createVertex = assert(InterfaceToDisplay.createVertex)
function InterfaceToDisplay.createVertex(name, ...)
  typeout("Create vertex '%s'", name)
  createVertex(name, ...)
end

local createEdge = assert(InterfaceToDisplay.createEdge)
function InterfaceToDisplay.createEdge(tail, head, direction, ...)
  typeout("Create edge '%s' from '%s' to '%s'", direction, tail, head)
  createEdge(tail, head, direction, ...)
end

--[[ this generates too many debugging lines
local createEvent = assert(InterfaceToDisplay.createEvent)
function InterfaceToDisplay.createEvent(kind, ...)
  typeout("Create event '%s'", kind)
  return createEvent(kind, ...)
end
--]]

local addToVertexOptions = assert(InterfaceToDisplay.addToVertexOptions)
function InterfaceToDisplay.addToVertexOptions(name, ...)
  typeout("Add options to vertex '%s'", name)
  addToVertexOptions(name, ...)
end
