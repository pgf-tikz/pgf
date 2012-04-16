-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
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

-- This file defines the Interface global object, which is used as a
-- simplified frontend in the TeX part of the library.

-- pgf.module("pgf.graphdrawing")


local control = require "pgf.gd.control"


-- Declare new namespace:

control.TeXInterface = {
  graph = nil,
  parameter_defaults = {},
  tex_boxes = {},
  verbose = false
}
control.TeXInterface.__index = control.TeXInterface


--- Logging

--- Writes log messages to the \TeX\ output, separating the parameters
-- by spaces, provided TeXInterface.verbose is set.
--
-- @param ... List of parameters to write to the \TeX\ output.

function control.TeXInterface:log(...)
  if self.verbose then
    self:debug(...)
  end
end

--- Writes log messages to the \TeX\ output, separating the parameters
-- by spaces, regardless of any settings of the verbose parameter.
--
-- @param ... List of parameters to write to the \TeX\ output.

function control.TeXInterface:debug(...)
   texio.write_nl("")
   -- this is to even print out nil arguments in between
   local args = {...}
   for i = 1, table.getn(args) do
      if i ~= 1 then texio.write(" ") end
      texio.write(tostring(args[i]))
   end
   texio.write_nl("")
end





--- Creates a new graph and adds it to the graph stack.
--
-- The options string consisting of |{key}{value}| pairs is parsed and 
-- assigned to the graph. These options are used to configure the different
-- graph drawing algorithms shipped with \tikzname.
--
-- @see finishGraph
--
-- @param options A string containing |{key}{value}| pairs of 
--                \tikzname\ options.
--
function control.TeXInterface:newGraph(options)
  self.graph = pgf.graphdrawing.Graph:new()
  self.graph:mergeOptions(string.parse_braces(options))
end





--- Adds a new node to the graph.
--
-- This function is called for each node of the graph by the \TeX\
-- layer. The \meta{name} is the name of the node including the
-- internal prefix added by the \TeX\ layer to indicate that the node
-- ``does not yet exist.'' The parameters \meta{xMin} to \meta{yMax}
-- specify a bounding box around the node; note that the origin lies
-- at the anchor postion of the node. The \meta{options} are a string
-- in the format of a sequence of |{key}{value}| pairs. They are
-- parsed and stored in the newly created node object on the Lua
-- layer. Graph drawing algorithms may use these options to treat 
-- the node in special ways. The \meta{lateSetup} is \TeX\ code that
-- just needs to be passed back when the node is finally
-- positioned. It is used to add ``decorations'' to a node after
-- positioning like a label.
--
-- @param box       Box register holding the node.
-- @param name      Name of the node.
-- @param shape     The pgf shape of the node (e.g. "circle" or "rectangle")
-- @param xMin      Minimum x point of the bouding box.
-- @param yMin      Minimum y point of the bouding box.
-- @param xMax      Maximum x point of the bouding box.
-- @param yMax      Maximum y point of the bouding box.
-- @param options   Lua-Options for the node.
-- @param lateSetup Options for the node.
--
function control.TeXInterface:addNode(box, name, shape, xMin, yMin, xMax, yMax, options, lateSetup)
  assert(self.graph, "no graph created")

  self.tex_boxes[#self.tex_boxes + 1] = node.copy_list(tex.box[box])
  local tex = {
    tex_node = #self.tex_boxes,
    shape = shape,
    maxX = xMax,
    minX = xMin,
    maxY = yMax,
    minY = yMin,
    late_setup = lateSetup
  }
  local node = pgf.graphdrawing.Node:new{
    name = string.sub(name, string.len("not yet positionedPGFINTERNAL") + 1),
    tex = tex, 
    options = string.parse_braces(options),
    event_index = #self.graph.events + 1
  }
  self.graph.events[#self.graph.events + 1] = { kind = 'node', parameters = node }
  self.graph:addNode(node)
end




--- Sets options for an already existing node
--
-- This function allows you to change the options of a node that already exists. 
--
-- @param name      Name of the node.
-- @param options   Lua-Options for the node.

function control.TeXInterface:setLateNodeOptions(name, options)
  local node = self.graph:findNode(name)
  if node then
    for k,v in string.parse_braces(options) do
      node.options [k] = v
    end
  end
end


--- Adds an edge from one node to another by name.  
--
-- Both parameters are node names and have to exist before an edge can be
-- created between them.
--
-- @see addNode
--
-- @param from         Name of the node the edge begins at.
-- @param to           Name of the node the edge ends at.
-- @param direction    Direction of the edge (e.g. |--| for an undirected edge 
--                     or |->| for a directed edge from the first to the second 
--                     node).
-- @param parameters   A string of parameters pairs of edge options that are
--                     relevant to graph drawing algorithms.
-- @param tikz_options A string that should be passed back to \pgfgddraw unmodified.
-- @param aux          Another string that should be passed back to \pgfgddraw unmodified.
--
function control.TeXInterface:addEdge(from, to, direction, parameters, tikz_options, aux)
  assert(self.graph, "no graph created")
  local from_node = self.graph:findNode(from)
  local to_node = self.graph:findNode(to)
  assert(from_node and to_node, 'cannot add the edge because its nodes "' .. from .. '" and "' .. to .. '" are missing')
  if direction ~= pgf.graphdrawing.Edge.NONE then
    local edge = self.graph:createEdge(from_node, to_node, direction, aux, string.parse_braces(parameters), tikz_options)
    edge.event_index = #self.graph.events + 1
    self.graph.events[#self.graph.events + 1] = { kind = 'edge', parameters = edge }
  end
end




--- Adds an event to the event sequence.
--
-- @param kind         Name/kind of the event.
-- @param parameters   Parameters of the event.
--
function control.TeXInterface:addEvent(kind, param)
  assert(self.graph, "no graph created")
  self.graph.events[#self.graph.events + 1] = { kind = kind, parameters = param}
end



function control.TeXInterface:addNodeToCluster(node_name, cluster_name)
  assert(self.graph, 'no graph created')
  
  -- find the node
  local node = self.graph:findNode(node_name)

  assert(node, 'cannot add node "' .. node_name .. '" to cluster "' .. cluster_name .. '" because the node does not exist')
  
  -- find the cluster
  local cluster = self.graph:findClusterByName(cluster_name)

  -- if it doesn't exist yet, create it on demand
  if not cluster then
    cluster = pgf.graphdrawing.Cluster:new(cluster_name)
    self.graph:addCluster(cluster)
  end

  -- add the node to the cluster
  cluster:addNode(node)
end



--- Attempts to load the algorithm with the given \meta{name}.
--
-- This function tries to look up the corresponding algorithm file
-- |pgfgd-algorithms-<name>.lua| and attempts to
-- look up the class for calling the algorithm.
--
-- @param name Name of the algorithm.
--
-- @return The algorithm function or nil.
--
function control.TeXInterface:loadAlgorithm(name)

   -- Load the file (if necessary)
   pgf.load("pgfgd-algorithm-" .. name .. ".lua", "tex", false)

   -- look up the main algorithm function
   return pgf.graphdrawing[name]
end


--- Arranges the current graph using the specified algorithm. 
--
-- The algorithm is derived from the graph options and is loaded on
-- demand from the corresponding algorithm file. For a fictitious algorithm 
-- |simple| this file is per convention called 
-- |pgflibrarygraphdrawing-algorithms-simple.lua|. It is required to define
-- at least one function as an entry point to the algorithm. The name of the
-- function is again predetermined as |graph_drawing_algorithm_simple|.
-- When a graph is to be layed out, this function is called with the graph
-- as its only parameter.
--
function control.TeXInterface:runGraphDrawingAlgorithm()
  if #self.graph.nodes == 0 then
    -- Nothing needs to be done
    return
  end
  
  local name = self.graph:getOption("/graph drawing/algorithm"):gsub(' ', '')
  local algorithm_class = pgf.graphdrawing[name]
  
  -- if not defined, try to load the corresponding file
  if not algorithm_class then
    algorithm_class = control.TeXInterface:loadAlgorithm(name)
  end
  
  assert(algorithm_class, "No algorithm named '" .. name .. "' was found. " ..
	 "Either the file does not exist or the class declaration is wrong.")

  local start = os.clock()
  -- Ok, everything setup.
  
  pgf.graphdrawing.pipeline.run_graph_drawing_pipeline(self.graph, algorithm_class)
  
  local stop = os.clock()

  control.TeXInterface:log(string.format("Graph drawing engine: algorithm '" .. name .. "' took %.4f seconds", stop - start))
end



--- Passes the current graph back to the \TeX\ layer and removes it from the stack.
--
function control.TeXInterface:finishGraph()
  assert(self.graph, "no graph created")

  tex.print("\\pgfgdbeginshipout")
  
  tex.print("\\pgfgdbeginnodeshipout")
  for node in table.value_iter(self.graph.nodes) do
    control.TeXInterface:shipoutNode(node)
  end
  tex.print("\\pgfgdendnodeshipout")

  tex.print("\\pgfgdbeginedgeshipout")
  for edge in table.value_iter(self.graph.edges) do
    control.TeXInterface:shipoutEdge(edge)
  end
  tex.print("\\pgfgdendedgeshipout")
  
  tex.print("\\pgfgdendshipout")

  self.graph = nil
end



--- Passes a node back to the \TeX\ layer.
--
-- @param node The node to pass back to the \TeX\ layer.
--
function control.TeXInterface:shipoutNode(node)
  tex.print(string.format("\\pgfgdinternalshipoutnode{%s}{%fpt}{%fpt}{%fpt}{%fpt}{%s}{%s}{%s}{%s}",
			  'not yet positionedPGFINTERNAL' .. node.name,
			  node.tex.minX, node.tex.maxX,
			  node.tex.minY, node.tex.maxY,
			  node.pos.x, node.pos.y,
			  node.tex.tex_node, node.tex.late_setup))
end



function control.TeXInterface:retrieveBox(box_reference)
  local ret = self.tex_boxes[box_reference]
  self.tex_boxes[box_reference] = nil
  return ret
end



--- Passes an edge back to the \TeX\ layer.
--
-- Edges with a direction of |Edge.NONE| are skipped and not passed
-- back to \TeX.
--
-- @param edge The edge to pass back to the \TeX\ layer.
--
function control.TeXInterface:shipoutEdge(edge)

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



--- Defines a default value for a graph parameter. 
--
-- Whenever a graph parameter has not been set by the user explicitly,
-- the value that was last set using this function is used instead.
--
-- @param key The commplete path of the to-be-defined key
-- @param value A string containing the value
--
function control.TeXInterface:setGraphParameterDefault(key,value)
  self.parameter_defaults[key] = value
end



-- Done 

return control.TeXInterface