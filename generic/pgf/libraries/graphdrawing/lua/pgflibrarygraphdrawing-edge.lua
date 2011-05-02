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

-- This file defines an edge class, used in the graph representation.

pgf.module("pgf.graphdrawing")

Edge = {}
Edge.__index = Edge

Edge.UNDIRECTED = "--"
Edge.LEFT = "<-"
Edge.RIGHT = "->"
Edge.BOTH = "<->"
Edge.NONE = "-!-"

--- Creates an edge between nodes of a graph.
-- @param values Values (e.g. direction) to be merged with the default-metatable of an edge.
-- @return The new edge.
function Edge:new(values)
   local defaults = {
      nodes = {},
      edge_nodes = '',
      options = {},
      tikz_options = {},
      direction = Edge.DIRECTED,
   }
   setmetatable(defaults, Edge)
   local result = mergeTable(values, defaults)
   return result
end

function Edge:setOption(name, value)
   self.options[name] = value
end

function Edge:getOption(name)
   return self.options[name]
end

--- Merges options.
function Edge:mergeOptions(options)
   self.options = table.merge(options, self.options)
end

--- Sets the path of an edge.
-- @param path The path the edge belongs to.
function Edge:setPath(path)
   self._path = path
end

--- Returns the path of an edge.
-- @return The path the edge belongs to.
function Edge:getPath()
   return self._path
end

--- Returns a boolean whether the edge is a hyperedge.
-- @return True if the edge is a hyperedge.
function Edge:isHyperedge()
   return self:getDegree() > 2
end

--- Tests if edge contains a node.
-- @return True if the edge contains a node.
function Edge:containsNode(node)
   local result = table.find(self.nodes, function (other) 
      return other.name == node.name 
   end)
   return not (result == nil)
end

--- Adds node to the edge.
-- @param node The node to be added to the edge.
function Edge:addNode(node)
   if not self:containsNode(node) then
      table.insert(self.nodes, node)
      node:addEdge(self)
   end
end

--- Returns all neighbours of a node.
-- @param node The node which neighbours should be returned.
-- @return Array of neighbour nodes.
function Edge:getNeighbours(node)
   return table.filter_values(self.nodes, function (other)
      return other.name ~= node.name
   end)
end

--- Gets first neighbour of the node (disregarding hyperedges).
-- @param node The node which first neighbour should be returned.
-- @return The first neighbour of the node.
function Edge:getNeighbour(node)
   return self:getNeighbours(node)[1]
end

--- Returns number of nodes on the edge.
-- @return Number of nodes of the edge.
function Edge:getDegree()
   return table.count_pairs(self.nodes)
end

--- Copies an edge (preventing accidental use).
-- @return Shallow copy of the edge.
function Edge:copy()
   local result = copyTable(self, Edge:new())
   result._nodes = {}
   obj.nodes = {}
   return obj
 end

--- Returns a readable string representation of the edge.
-- @return String representation of the edge.
-- @ignore This should not appear in the documentation.
function Edge:__tostring()
   local tmp = Edge.__tostring
   if table.count_pairs(self.nodes) > 0 then
      local node_strings = table.map_values(self.nodes, function (node)
         return tostring(node)
      end)
      result = result .. table.concat(node_strings, ', ')
   end
   return result .. ")"
end
