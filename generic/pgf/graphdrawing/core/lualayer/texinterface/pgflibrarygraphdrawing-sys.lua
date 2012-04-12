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
  io.flush()
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
function Sys:putTeXBox(node, texnode, minX, minY, maxX, maxY, posX, posY, lateSetup)
   tex.print(string.format("\\pgfgdinternalshipoutnode{%s}{%fpt}{%fpt}{%fpt}{%fpt}{%s}{%s}{%s}{%s}",
   	        Sys:escapeTeXNodeName(node.name),
   	        minX, maxX,
   	        minY, maxY,
   	        posX, posY,
   	        texnode, lateSetup))
end



--- Callback to pgf when shipout of nodes and edges starts
--
function Sys:beginShipout()
  tex.print("\\pgfgdbeginshipout")
end


--- Callback to pgf when shipout of nodes starts
--
function Sys:beginNodeShipout()
  tex.print("\\pgfgdbeginnodeshipout")
end

--- Callback to pgf when shipout of edges starts
--
function Sys:beginEdgeShipout()
  tex.print("\\pgfgdbeginedgeshipout")
end



--- Ends the shipout of nodes and edges in general.
--
-- @see Sys:beginShipout()
--
function Sys:endShipout()
  tex.print("\\pgfgdendshipout")
end


--- Callback to pgf when shipout of nodes ends
--
function Sys:endNodeShipout()
  tex.print("\\pgfgdendnodeshipout")
end

--- Callback to pgf when shipout of edges ends
--
function Sys:endEdgeShipout()
  tex.print("\\pgfgdendedgeshipout")
end



--- Assembles and outputs the TeX command to draw an edge.
--
-- @param edge Edge to generate the \TeX/\tikzname\ command for.
--
function Sys:putEdge(edge)
  -- map nodes to node strings
  local node_strings = table.map_values(edge.nodes, function (node) 
    return '{' .. node.name .. '}'
  end)
  
  -- reverse strings if the edge is reversed
  if edge.reversed then
    node_strings = table.reverse_values(node_strings, node_strings)
  end
  
  local bend_string = ''
  if #edge.bend_points > 0 then
    local bend_strings = table.map_values(edge.bend_points, 
					  function (vector)
					    return '(' .. tostring(vector.x) .. 'pt,' .. tostring(vector.y) .. 'pt)'
    end)
    if edge.reversed then
      bend_strings = table.reverse_values(bend_strings, bend_strings)
    end
    bend_string = '-- ' .. table.concat(bend_strings, '--')
  end
  
  -- generate string for the entire edge
  local callback = '\\pgfgdedgecallback'
     .. table.concat(node_strings,'') .. '{' .. edge.direction .. '}{'
     .. edge.tikz_options ..'}{' .. edge.edge_nodes .. '}{'
     .. table.combine_pairs(edge.algorithmically_generated_options,
			      function (s, k, v) return s .. ','
			      .. tostring(k) .. '={' .. tostring(v) .. '}' end, '')
     .. '}{' .. bend_string .. '}'

  -- hand TikZ code over to TeX
  tex.print(callback)
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


function Sys:debug(...)
   texio.write_nl("")
   -- this is to even print out nil arguments in between
   local args = {...}
   for i = 1, table.getn(args) do
      if i ~= 1 then texio.write(" ") end
      texio.write(tostring(args[i]))
   end
   texio.write_nl("")
end



--- Adds a |not yet positionedPGFINTERNAL| prefix to the name of a node. 
--
-- The prefix is required by PGF to place the node. Actually, when deferring 
-- the node placement, the prefix is added to avoid references to the node.
--
-- @param name Name of a node to be prefixed.
--
-- @return Name of the node prefixed with |not yet positionedPGFINTERNAL|.
--
function Sys:escapeTeXNodeName(name)
  return 'not yet positionedPGFINTERNAL' .. name
end



--- Removes the |not yet positionedPGFINTERNAL| prefix from the name of a node.
--
-- @see Sys:escapeTeXNodeName(name)
--
-- @param name Name of a node with the internal prefix present.
--
-- @return Name of the node with the internal name prefix removed.
--
function Sys:unescapeTeXNodeName(name)
  return string.sub(name, string.len("not yet positionedPGFINTERNAL") + 1)
end
