-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License.
--
-- See the file doc/generic/pgf/licenses/LICENSE for more details.

-- @release $Header$

-- This file contains methods dealing with the output back to the TeX
-- side and some TeX and PGF specialties.

pgf.module("pgf.graphdrawing")

Sys = {}
Sys.__index = Sys

--- Switch for verbose output.
Sys._verbose = false

--- Holds the content of the boxes of the current graph.
--  This is done save box registes.
Sys._boxContent = {}

--- Number of items in _boxContent.
Sys._boxIterator = 1

--- Enables or disables verbose logging for the graph drawing library.
--  @param mode If true, enable verbose logging. Otherwise it'll be disabled.
function Sys:setVerboseMode(mode)
   self._verbose = mode
end

--- Checks the verbosity of the subsystems output.
-- @return Boolean value specifying the verbosity.
function Sys:getVerboseMode()
   return self._verbose
end

--- Init method, sets the box register number.
--  This method is called when the \tikzname\ (pgf) library is loaded.
--  @param bn Number of the box register used for transfering boxes of the
--            current graph.
function Sys:setBoxNumber(bn)
   Sys:logMessage("GD:SYS: setting box register number to " .. bn)
   self._boxRegisterNumber = bn
end

--- Retrieves a box from the transfer box register.
-- @see putTeXBox
function Sys:getTeXBox()
   Sys:logMessage("GD:SYS: getting tex box " .. self._boxRegisterNumber)
   assert(self._boxRegisterNumber, "Box register number not set")
   texbox = node.copy_list(tex.box[self._boxRegisterNumber])
   assert(texbox, "Box register was empty")
   return texbox
end

--- Saves a box from the transfer box register.
--  @param nodeName The name of the node in the box.
--  @param texnode The box which contains the \TeX\ node.
--  @param minX Minimal x of the bounding box.
--  @param minY Minimal y of the bounding box.
--  @param minX Maximum x of the bounding box.
--  @param minX Maximum y of the bounding box.
--  @param posX X coordinate where to put the node in the output.
--  @param posY Y coordinate where to put the node in the output.
function Sys:putTeXBox(nodename, texnode, minX, minY, maxX, maxY, posX, posY)
   tex.print(string.format("\\pgfgdinternalshipoutnode{%s}{%s}{%s}{%s}{%s}{%s}{%s}{%s}",
			   nodename,
			   minX, maxX,
			   minY, maxY,
			   posX, posY,
			   texnode))
end

--- Begins the shipout of nodes by opening a scope in pgf.
function Sys:beginShipout()
   tex.print("\\pgfgdbeginshipout")
end

--- Ends the shipout by closing the opened scope.
-- @see Sys:beginShipout()
function Sys:endShipout()
   tex.print("\\pgfgdendshipout")
end

--- Assembles and outputs the TeX command to draw an edge.
-- @param Edge A lua edge object.
function Sys:putEdge(edge)
   -- map nodes to node strings
   local node_strings = table.map_values(edge.nodes, function (node) 
      return '(' .. string.sub(node.name, string.len('not yet positioned@') + 1) .. ')'
   end)

   -- reverse strings if the edge is reversed
   if edge.reversed then
     node_strings = table.reverse_values(node_strings, node_strings)
   end

   -- determine the direction string, which is '' for undirected edges
   local direction = edge.direction == Edge.UNDIRECTED and '' or edge.direction

   local bend_string = ' to '
   if #edge.bend_points > 0 then
     local bend_strings = table.map_values(edge.bend_points, function (vector)
       return '(' .. tostring(vector:get(1)) .. 'pt,' .. tostring(vector:get(2)) .. 'pt)'
     end)
     bend_string = bend_string .. table.concat(bend_strings, ' to ') .. ' to ' .. edge.edge_nodes
   end

   -- generate string for the entire edge
   --local edge_string = ' ' .. 'edge' .. '[' .. edge.tikz_options .. ']' .. bend_string
   --local draw_string = '\\draw[' .. direction .. '] ' .. table.concat(node_strings, edge_string) .. ';'
   local edge_string = bend_string
   local draw_string = '\\draw[' .. direction .. ',' .. edge.tikz_options ..'] ' .. table.concat(node_strings, edge_string) .. ';'

   -- hand TikZ code over to TeX
   texio.write_nl(draw_string)
   tex.print(draw_string)
end

--- Prints objects to the TeX output, formatting them with tostring and
-- separated by spaces.
-- @param ... List of parameters.
function Sys:logMessage(...)
   if self._verbose then
      texio.write_nl("")
      -- this is to even print out nil arguments in between
      local args = {...}
      for i = 1, table.getn(args) do
	 if i ~= 1 then texio.write(" ") end
	 texio.write(tostring(args[i]))
      end
      texio.write_nl("")
   end
end

--- Adds a ``not yet positionedPGFGDINTERNAL'' prefix to a node name. The prefix is required by
-- pgf to place the node. Actually, when deferring the node placement, the prefix is added to avoid
-- references to the node.
-- @param nodename Name of the node to prefix.
-- @return A newly composed string.
function Sys:escapeTeXNodeName(nodename)
   return 'not yet positionedPGFGDINTERNAL' .. nodename
end

--- Removes the ``not yet positionedPGFGDINTERNAL'' prefix from a node name.
-- @param nodename Nodename without prefix.
-- @return The substring in question.
-- @see Sys:escapeTeXNodeName(nodename)
function Sys:unescapeTeXNodeName(nodename)
   return string.sub(nodename, string.len("not yet positionedPGFGDINTERNAL") + 1)
end
