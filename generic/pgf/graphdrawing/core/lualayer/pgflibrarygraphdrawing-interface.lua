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
  defaultGraphParameters = {}
}
Interface.__index = Interface



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
function Interface:newGraph(options)
  self.graph = Graph:new()
  table.insert(self.graphStack, self.graph)
  Sys:log("GD:INT: options = " .. options)
  self.graph:mergeOptions(string.parse_braces(options))
end



--- Sets the graph option \meta{name} to \meta{value}. Only affects the current graph.
--
-- @param name  The name of the option to set.
-- @param value New value for the option.
--
function Interface:setOption(name, value)
  self.graph:setOption(name, value)
end



--- Returns the value of the graph option \meta{name}.
--
-- @param name Name of the option.
--
-- @return The value of the \meta{name} option or |nil|.
--
function Interface:getOption(name)
  return self.graph:getOption(name)
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
-- @param name      Name of the node.
-- @param xMin      Minimum x point of the bouding box.
-- @param yMin      Minimum y point of the bouding box.
-- @param xMax      Maximum x point of the bouding box.
-- @param yMax      Maximum y point of the bouding box.
-- @param options   Lua-Options for the node.
-- @param lateSetup Options for the node.
--
function Interface:addNode(name, xMin, yMin, xMax, yMax, options, lateSetup)
  assert(self.graph, "no graph created")
  local tex = {
    texNode = TeXBoxRegister:insertBox(Sys:getTeXBox()), 
    maxX = xMax,
    minX = xMin,
    maxY = yMax,
    minY = yMin,
    texLateSetup = lateSetup
  }
  local node = Node:new{
    name = Sys:unescapeTeXNodeName(name), 
    tex = tex, 
    options = string.parse_braces(options)
  }
  self.graph:addNode(node)
  Sys:log("GD:INT: addNode(" .. node.name ..", " .. "maxX = " .. node.tex.maxX .. ", minX = " .. node.tex.minX .. ", maxY = " .. node.tex.maxY.. ", minY = " .. node.tex.minY .. ",...)")
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
function Interface:addEdge(from, to, direction, parameters, tikz_options, aux)
  assert(self.graph, "no graph created")
  Sys:log("GD:INT: Edge " .. tostring(from) .. " " .. tostring(direction) .. " " .. tostring(to))
  local from_node = self.graph:findNode(from)
  local to_node = self.graph:findNode(to)
  assert(from_node and to_node, 'cannot add the edge because its nodes "' .. from .. '" and "' .. to .. '" are missing')
  if direction == Edge.NONE then
    self.graph:deleteEdgeBetweenNodes(from_node, to_node)
  else
    self.graph:createEdge(from_node, to_node, direction, aux, string.parse_braces(parameters), tikz_options)
  end
end



function Interface:addNodeToCluster(node_name, cluster_name)
  assert(self.graph, 'no graph created')
  
  -- find the node
  local node = self.graph:findNode(node_name)

  assert(node, 'cannot add node "' .. node_name .. '" to cluster "' .. cluster_name .. '" because the node does not exist')
  
  -- find the cluster
  local cluster = self.graph:findClusterByName(cluster_name)

  -- if it doesn't exist yet, create it on demand
  if not cluster then
    cluster = Cluster:new(cluster_name)
    self.graph:addCluster(cluster)
  end

  -- add the node to the cluster
  cluster:addNode(node)
end



--- Attempts to load the algorithm with the given \meta{name}.
--
-- This function tries to look up the corresponding algorithm file
-- |pgflibrarygraphdrawing-algorithms-name.lua| and attempts to
-- look up the main function for calling the algorithm.
--
-- @param name Name of the algorithm.
--
-- @return The algorithm function or nil.
--
function Interface:loadAlgorithm(name)
  local function_name = 'drawGraphAlgorithm_' .. name
  
  -- substitute special characters in the function name with
  -- something that Lua can handle
  local substitutions = { ['-'] = '_' }
  for char, replacement in pairs(substitutions) do
    function_name = function_name:gsub(char, replacement)
  end
  
  Sys:log('function_name = ' .. function_name)
  Sys:log('name = ' .. name)
  
  -- try to load the algorithm file
  -- delete the following after renaming of all files
  local filename = "pgfgd-algorithm-" .. name .. ".lua"
  pgf.load(filename, "tex", false, "pgflibrarygraphdrawing-algorithms-" .. name .. ".lua")

  -- look up the main algorithm function
  return pgf.graphdrawing[function_name]
end



-- TODO: Jannis: Document this method.
function Interface:convertFilenameToClassname(filename)
  local pre_substitutions = {
    ['-'] = ' ',
    ['_'] = ' ',
  }
  for char, replacement in pairs(pre_substitutions) do
    filename = filename:gsub(char, replacement)
  end

  filename = filename:gsub("^(%a)", string.upper, 1)
  filename = filename:gsub("%s+(%a)", string.upper)

  local post_substitutions = {
    [' '] = '',
  }
  for char, replacement in pairs(post_substitutions) do
    filename = filename:gsub(char, replacement)
  end

  return filename
end



-- TODO: Jannis: Document this method.
function Interface:convertClassnameToFilename(classname)
  local source = {}
  for n = 1, classname:len() do
    source[n] = classname:sub(n, n)
  end

  local target = {}

  local source_pos = 1
  local target_pos = 1

  for source_pos = 1, #source do
    if source[source_pos]:gsub('%a', '') == '' then
      if source[source_pos] == source[source_pos]:upper() then
        if source_pos == 1 then
          target[target_pos] = source[source_pos]
          target_pos = target_pos + 1
        else
          if source[source_pos-1] == source[source_pos-1]:upper() then
            target[target_pos] = source[source_pos]
            target_pos = target_pos + 1
          else
            target[target_pos] = ' '
            target[target_pos + 1] = source[source_pos]
            target_pos = target_pos + 2
          end
        end
      else
        target[target_pos] = source[source_pos]
        target_pos = target_pos + 1
      end
    else
      target[target_pos] = source[source_pos]
      target_pos = target_pos + 1
    end
  end

  return table.concat(target, '')
end



--- Arranges the current graph using the specified algorithm. 
--
-- The algorithm is derived from the graph options and is loaded on
-- demand from the corresponding algorithm file. For a fictitious algorithm 
-- |simple| this file is per convention called 
-- |pgflibrarygraphdrawing-algorithms-simple.lua|. It is required to define
-- at least one function as an entry point to the algorithm. The name of the
-- function is again predetermined as |drawGraphAlgorithm_simple|.
-- When a graph is to be layed out, this function is called with the graph
-- as its only parameter.
--
function Interface:drawGraph()
  if #self.graph.nodes == 0 then
    Sys:log("GD:INT: no nodes, aborting")
    return
  end

  local name = self:getOption("/graph drawing/algorithm"):gsub('%s', '-')
  local functionName = "drawGraphAlgorithm_" .. name:gsub('-', '_')
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
  Sys:log(string.format("GD:INT: algorithm took %.2f seconds", stop - start))
  Sys:log(' ')
end



--- Passes the current graph back to the \TeX\ layer and removes it from the stack.
--
function Interface:finishGraph()
  assert(self.graph, "no graph created")
  Sys:beginShipout()
  local graph = table.remove(self.graphStack)
  self.graph = self.graphStack[#self.graphStack]
  
  Sys:log("GD:INT: graph = " .. tostring(graph))
  
  Sys:beginNodeShipout()
  for node in table.value_iter(graph.nodes) do
    Sys:log("GD:INT: node = " .. tostring(node))
    self:drawNode(node)
  end
  Sys:endNodeShipout()

  Sys:beginEdgeShipout()
  for edge in table.value_iter(graph.edges) do
    Sys:log("GD:INT: edge = " .. tostring(edge))
    self:drawEdge(edge)
  end
  Sys:endEdgeShipout()
  
  Sys:endShipout()
end



--- Passes a node back to the \TeX\ layer.
--
-- @param node The node to pass back to the \TeX\ layer.
--
function Interface:drawNode(node)
  Sys:putTeXBox(node,
                node.tex.texNode,
                node.tex.minX,
                node.tex.minY,
                node.tex.maxX,
                node.tex.maxY,
                node.pos:x(),
                node.pos:y(),
                node.tex.texLateSetup)
end



--- Passes an edge back to the \TeX\ layer.
--
-- Edges with a direction of |Edge.NONE| are skipped and not passed
-- back to \TeX.
--
-- @param edge The edge to pass back to the \TeX\ layer.
--
function Interface:drawEdge(edge)
  if edge.direction ~= Edge.NONE then
    Sys:putEdge(edge)
  end
end



--- Defines a default value for a graph parameter. 
--
-- Whenever a graph parameter has not been set by the user explicitly,
-- the value that was last set using this function is used instead.
--
-- @param key The commplete path of the to-be-defined key
-- @param value A string containing the value
--
function Interface:setGraphParameterDefault(key,value)
  self.defaultGraphParameters[key] = value
end
