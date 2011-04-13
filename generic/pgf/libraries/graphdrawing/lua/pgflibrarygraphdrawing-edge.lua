-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
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
      _nodes = {},
      options = {},
      direction = Edge.DIRECTED,
   }
   setmetatable(defaults, Edge)
   local result = mergeTable(values, defaults)
   return result
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

--- Returns the nodes of an edge.
-- @return Array of nodes of the edge.
function Edge:getNodes()
   return self._nodes
end

--- Tests if edge contains a node.
-- @return True if the edge contains a node.
function Edge:containsNode(node)
   return not findTable(self._nodes) == nil
end

--- Adds node to the edge.
-- @param node The node to be added to the edge.
function Edge:addNode(node)
   if not findTable(self._nodes, node) then
      table.insert(self._nodes, node)
      node:addEdge(self)
   end
end

--- Returns all neighbours of a node.
-- @param node The node which neighbours should be returned.
-- @return Array of neighbour nodes.
function Edge:getNeighbours(node)
   local result = copyTable(self._nodes)
   local index = findTable(result, node)
   if index then
      table.remove(result, index)
   end
   return result
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
   return #self._nodes
end

--- Copies an edge (preventing accidental use).
-- @return Shallow copy of the edge.
function Edge:copy()
   local result = copyTable(self, Edge:new())
   result._nodes = {}
   return result
 end

--- Returns a readable string representation of the edge.
-- @return String representation of the edge.
-- @ignore This should not appear in the doc
function Edge:__tostring()
   local tmp = Edge.__tostring
   Edge.__tostring = nil
   local result = "Edge<" .. tostring(self) .. ">(" .. self.direction .. ", "
   Edge.__tostring = tmp

   local first = true
   for node in values(self._nodes) do
      if first then first = false else result = result .. ", " end
      result = result .. tostring(node)
   end 
   return result .. ")"
end
