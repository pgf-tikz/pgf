-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file defines the Interface global object, which is used as a
-- simplified frontend in the TeX part of the library.

pgf.module("pgf.graphdrawing")

--- Sits between the TikZ/TeX side and Lua.
Interface = {
   graphStack = {},
   -- graph = nil,
}
Interface.__index = Interface

--- Creates a new graph and pushes it on top of the graph stack.  The
-- options string is parsed and assigned.
-- @param options A list of options for this graph (deprecated, use \tikzname\ keys instead).
-- @see finishGraph
function Interface:newGraph(options)
   self.graph = Graph:new()
   table.insert(self.graphStack, self.graph)
   Sys:logMessage("GD:INT: options = " .. options)
   self.graph:mergeOptions(parseBraces(options))
end

--- Sets a graph option name to value.
-- @param name The name of the option to set.
-- @param value New value for the option.
function Interface:setOption(name, value)
   self.graph:setOption(name, value)
end

--- Returns the value of the graph option name.
-- @param name Name of the option.
-- @return The stored value or nil.
function Interface:getOption(name)
   return self.graph:getOption(name)
end

--- Adds a new node to the graph.  The options string is parsed and
-- assigned.
-- @param name Name of the node.
-- @param xMin Minimum x point of the bouding box.
-- @param yMin Minimum y point of the bouding box.
-- @param xMax Maximum x point of the bouding box.
-- @param yMax Maximum y point of the bouding box.
-- @param options Options to pass to the node (deprecated, use \tikzname\ keys instead).
function Interface:addNode(name, xMin, yMin, xMax, yMax, options)
   assert(self.graph, "no graph created")
   local tex = {
      texNode = TeXBoxRegister:insertBox(Sys:getTeXBox()), 
      maxX = xMax,
      minX = xMin,
      maxY = yMax,
      minY = yMin
   }
   local node = Node:new{name = name, tex = tex, options = parseBraces(options)}
   self.graph:addNode(node)
   Sys:logMessage("GD:INT: addNode(" .. name ..", " .. "maxX = " .. node.tex.maxX .. ", minX = " .. node.tex.minX 
     .. ", maxY = " .. node.tex.maxY.. ", minY = " .. node.tex.minY .. ",...)")
   -- TODO: maybe the first node can automatically be assigned as the
   -- root node? i.e. if graph.root is nil, assign it, else leave it be
   -- then provide a new method getRoot, which first searches for a
   -- node with "root" attribute and, if none exists, uses the
   -- graph.root node as root ... will remove one step for the user
end

--- Adds an edge from one node to another by name.  That is, both
-- parameters are node names and have to exist before an edge can be
-- created between them.
-- @param options A key=value string, which is currently only passed back to
-- the \TeX layer during shipout (deprecated, use \tikzname\ keys instead).
-- @see addNode
function Interface:addEdge(from, to, direction, options)
   assert(self.graph, "no graph created")
   Sys:logMessage("GD:INT: Edge from: " .. tostring(from) .. " to: " .. tostring(to))
   from = self.graph:findNode(Sys:escapeTeXNodeName(from))
   to = self.graph:findNode(Sys:escapeTeXNodeName(to))
   assert(from and to, "at least one node doesn't exist yet")
   self.graph:createEdge(from, to, direction, parseBraces(options))
end

--- Loads the file with the
-- ``pgflibrarygraphdrawing-algorithms-xyz.lua'' naming scheme.
-- @param name Name of  the algorithm, like ``xyz''.
-- @return The algorithm function or nil.
function Interface:loadAlgorithm(name)
   local functionName = "drawGraphAlgorithm_" .. name
   local filename = "pgflibrarygraphdrawing-algorithms-" .. name .. ".lua"
   pgf.load(filename, "tex")
   return pgf.graphdrawing[functionName]
end

--- Draws/layouts the current graph using the specified algorithm.  The
-- algorithm is derived from the options attribute and is loaded on
-- demand from the corresponding file, e.g. for algorithm ``simple'' it is
-- ``pgflibrarygraphdrawing-algorithms-simple.lua'' which has to define a
-- function named ``drawGraphAlgorithm\_simple'' in the pgf.graphdrawing
-- module.  It is then called with the graph as single parameter.
function Interface:drawGraph()
   if #self.graph.nodes == 0 then
      Sys:logMessage("GD:INT: no nodes, aborting")
      return
   end

   local name = self:getOption("algorithm")
   local functionName = "drawGraphAlgorithm_" .. name
   local algorithm = pgf.graphdrawing[functionName]

   -- if not defined, try to load the corresponding file
   if not algorithm then
      algorithm = self:loadAlgorithm(name)
   end

   assert(algorithm, "the algorithm is nil, e.g. a function named "
	  .. functionName .. " doesn't exist in the pgf.graphdrawing "
	  .. "module")
   local start = os.clock()
   algorithm(self.graph)
   local stop = os.clock()
   Sys:logMessage(string.format("GD:INT: algorithm took %.2f seconds", stop - start))
end

--- Pops the top graph from the graph stack (which is the current graph) and actually
-- draws the nodes and edges on the canvas.
function Interface:finishGraph()
   assert(self.graph, "no graph created")
   Sys:beginShipout()
   local graph = table.remove(self.graphStack)
   self.graph = self.graphStack[#self.graphStack]

   Sys:logMessage("GD:INT: graph = " .. tostring(graph))

   for node in table.value_iter(graph.nodes) do
      Sys:logMessage("GD:INT: node = " .. tostring(node))
      self:drawNode(node)
   end
   
   for edge in table.value_iter(graph.edges) do
      Sys:logMessage("GD:INT: edge = " .. tostring(edge))
      self:drawEdge(edge)
   end

   Sys:endShipout()
end

--- Helper function to actually put the node back to the TeX layer.
-- @param object The lua node object to draw.
function Interface:drawNode(object)
   local texnode = object.tex
   Sys:putTeXBox(
      object.name,
      texnode.texNode,
      texnode.minX,
      texnode.minY,
      texnode.maxX,
      texnode.maxY,
      object.pos:getAbsCoordinates()
   )
end

--- Helper function to put visible edges back to the TeX layer.
-- @param object Lua edge object to draw.
function Interface:drawEdge(object)
   if object.direction ~= Edge.NONE then
      Sys:putEdge(object)
   end
end
