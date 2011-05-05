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
Sys.verbose = false



--- Holds the content of the boxes of the current graph.
Sys.box_content = {}



--- Number of items in box_content.
Sys.box_iterator = 1



--- Enables or disables verbose logging for the graph drawing library.
--
-- @param verbose Enables verbose logging if set to |true|.
--
function Sys:setVerbose(verbose)
  self.verbose = verbose
end



--- Returns whether or not verbose logging is enabled.
--
-- @return |true| if verbose logging is enabled. |false| otherwise.
--
function Sys:getVerbose()
  return self.verbose
end



--- Initializes the graph drawing system by setting the box register number.
--
--  This method is called when the \tikzname\ |graphdrawing| library is loaded.
--
--  @param boxregister Number of the box register used for transfering boxes 
--                     of the current graph.
--
function Sys:setBoxNumber(boxregister)
  Sys:log("GD:SYS: setting box register number to " .. boxregister)
  self.box_register_number = boxregister
end



--- Retrieves a box from the transfer box register.
--
-- @see putTeXBox
--
function Sys:getTeXBox()
  Sys:log("GD:SYS: getting tex box " .. self.box_register_number)
  assert(self.box_register_number, "Box register number not set")
  texbox = node.copy_list(tex.box[self.box_register_number])
  assert(texbox, "Box register was empty")
  return texbox
end



--- Saves a box from the transfer box register.
--
--  @param node    Node in the box.
--  @param texnode The box which contains the \TeX\ node.
--  @param minX    Minimum x coordinate of the bounding box.
--  @param minY    Minimum y coordinate of the bounding box.
--  @param minX    Maximum x coordinate of the bounding box.
--  @param minX    Maximum y coordinate of the bounding box.
--  @param posX    X coordinate where to put the node in the output.
--  @param posY    Y coordinate where to put the node in the output.
--
function Sys:putTeXBox(node, texnode, minX, minY, maxX, maxY, posX, posY)
  tex.print(string.format("\\pgfgdinternalshipoutnode{%s}{%s}{%s}{%s}{%s}{%s}{%s}{%s}",
   	        Sys:escapeTeXNodeName(node.name),
   	        minX, maxX,
   	        minY, maxY,
   	        posX, posY,
   	        texnode))
end



--- Begins the shipout of nodes by opening a scope in PGF.
--
function Sys:beginShipout()
  tex.print("\\pgfgdbeginshipout")
end



--- Ends the shipout by closing the scope opened in PGF.
--
-- @see Sys:beginShipout()
--
function Sys:endShipout()
  tex.print("\\pgfgdendshipout")
end



--- Assembles and outputs the TeX command to draw an edge.
--
-- @param edge Edge to generate the \TeX/\tikzname\ command for.
--
function Sys:putEdge(edge)
  -- map nodes to node strings
  local node_strings = table.map_values(edge.nodes, function (node) 
    return '(' .. node.name .. ')'
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
  tex.print(draw_string)
end



--- Writes log messages to the \TeX\ output, separating the parameters by spaces.
--
-- @param ... List of parameters to write to the \TeX\ output.
--
function Sys:log(...)
  if self.verbose then
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



--- Adds a |not yet positionedPGFGDINTERNAL| prefix to the name of a node. 
--
-- The prefix is required by PGF to place the node. Actually, when deferring 
-- the node placement, the prefix is added to avoid references to the node.
--
-- @param name Name of a node to be prefixed.
--
-- @return Name of the node prefixed with |not yet positionedPGFGDINTERNAL|.
--
function Sys:escapeTeXNodeName(name)
  return 'not yet positionedPGFGDINTERNAL' .. name
end



--- Removes the |not yet positionedPGFGDINTERNAL| prefix from the name of a node.
--
-- @see Sys:escapeTeXNodeName(name)
--
-- @param name Name of a node with the internal prefix present.
--
-- @return Name of the node with the internal name prefix removed.
--
function Sys:unescapeTeXNodeName(name)
  return string.sub(name, string.len("not yet positionedPGFGDINTERNAL") + 1)
end
