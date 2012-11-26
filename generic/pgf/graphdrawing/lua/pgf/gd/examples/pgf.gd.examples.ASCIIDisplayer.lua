local InterfaceToDisplay = require "pgf.gd.interface.InterfaceToDisplay"

InterfaceToDisplay.bind(require "pgf.gd.examples.BindingToASCII")
require "pgf.gd.layered.library"
require "pgf.gd.force.library"

local graph = [[
graph [layered layout] {
  Alice;
  Bob;
  Charly;
  Dave;
  Eve;
  Fritz;
  George;
  Alice -> Bob;
  Alice -> Charly;
  Charly -> Dave;
  Bob -> Dave;
  Dave -> Eve;
  Eve -> Fritz;
  Fritz -> Alice;
  George -> Eve;
  George -> Fritz;
  Alice -> George;
}  
]]

-- Scan names:
local algorithm, graph_spec = string.match(graph, "%s*graph%s*%[(.-)%]%s*{%s*\n(.*)}")
  
InterfaceToDisplay.pushPhase(algorithm, "main", 1)
InterfaceToDisplay.pushOption("level distance", 6, 2)
InterfaceToDisplay.pushOption("sibling distance", 8, 3)
InterfaceToDisplay.beginGraphDrawingScope(3)
InterfaceToDisplay.pushLayout(4)

for line in string.gmatch(graph_spec, "([^\n]*)\n") do
  if line:find("-") then
    local n1, dir, n2 = string.match(line, "^%s*(.-)%s*(-.)%s*(.-)%s*;")
    InterfaceToDisplay.createEdge(n1, n2, dir, 4)
  else
    local n1 = string.match(line, "^%s*(.-)%s*;")
    InterfaceToDisplay.createVertex(n1, "rectangle", nil, 4)
  end
end

InterfaceToDisplay.runGraphDrawingAlgorithm()
InterfaceToDisplay.renderGraph()
InterfaceToDisplay.endGraphDrawingScope()
      


