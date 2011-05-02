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
      bend_points = {},
      bend_nodes = {},
      reversed = false,
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

--- Returns all neighbours of a node adjacent to the edge.
--
-- The edge direction is not taken into account, so this method always returns
-- all neighbours even if called on a directed edge.
--
-- @param node A node. Typically but not necessarily adjacent to the edge.
--                     If the node is not an intermediate or end point of the
--                     edge, an empty array is returned.
--
-- @return An array of nodes that are adjacent to the input node via the edge
--         the method is called on.
--
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

--- Counts the nodes on this edge.
--
-- @return The number of nodes on the edge.
--
function Edge:getDegree()
   return table.count_pairs(self.nodes)
end

--- Checks whether a node is the head of the edge. Does not work for hyperedges.
--
-- This method only works for edges with two adjacent nodes.
--
-- For undirected edges or edges that point into both directions, the result
-- will always be true. 
-- Directed edges may be reversed internally, so their head and tail might be 
-- switched. Whether or not this internal reversal is handled by this method 
-- can be specified with the optional second ignore_reversed parameter which 
-- is false by default.
--
-- @param node            The node to check.
-- @param ignore_reversed Optional parameter. Set this to true if reversed edges
--                        should not be considered reversed for this method call.
--
-- @return True if the node is the head of the edge.
--
function Edge:isHead(node, ignore_reversed)
  local result = false

  if self.direction == Edge.UNDIRECTED or self.direction == Edge.BOTH then
    -- undirected edges or edges pointing into both directions do not
    -- distinguish between head and tail nodes, so we always return true
    -- here
    result = true
  else
    -- by default, the head of -> edges is the last node and the head
    -- of <- edges is the first node
    local head_index = (self.direction == Edge.RIGHT) and #self.nodes or 1

    -- if the edge should be assumed reversed, we simply switch head and 
    -- tail positions
    if not ignore_reversed and self.reversed then
      head_index = (head_index == 1) and #self.nodes or 1
    end

    -- check if the head node equals the input node
    if self.nodes[head_index].name == node.name then
      result = true
    end
  end
  return result
end

--- Checks whether a node is the tail of the edge. Does not work for hyperedges.
--
-- This method only works for edges with two adjacent nodes.
--
-- For undirected edges or edges that point into both directions, the result
-- will always be true. 
--
-- Directed edges may be reversed internally, so their head and tail might be 
-- switched. Whether or not this internal reversal is handled by this method 
-- can be specified with the optional second ignore_reversed parameter which 
-- is false by default.
--
-- @param node            The node to check.
-- @param ignore_reversed Optional parameter. Set this to true if reversed edges
--                        should not be considered reversed for this method call.
--
-- @return True if the node is the tail of the edge.
--
function Edge:isTail(node, ignore_reversed)
  local result = false
  if self.direction == Edge.UNDIRECTED or self.direction == Edge.BOTH then
    -- undirected edges or edges pointing into both directions do not
    -- distinguish between head and tail nodes, so we always return true
    -- here
    result = true
  else
    -- by default, the tail of -> edges is the first node and the tail
    -- of <- edges is the last node
    local tail_index = (self.direction == Edge.RIGHT) and 1 or #self.nodes

    -- if the edge should be assumed reversed, we simply switch head
    -- and tail positions
    if not ignore_reversed and self.reversed then
      tail_index = (tail_index == 1) and #self.nodes or 1
    end

    -- check if the tail node equals the input node
    if self.nodes[tail_index].name == node.name then
      result = true
    end
  end
  return result
end

--- Copies an edge (preventing accidental use).
-- @return Shallow copy of the edge.
function Edge:copy()
   local result = copyTable(self, Edge:new())
   result._nodes = {}
   obj.nodes = {}
   return obj
 end

 --- Compares two edges by their adjacent nodes.
-- @return True if self is equal to object.
function Edge:__eq(other)
   if not other.nodes or #self.nodes ~= #other.nodes then
     return false
   end

   local same_nodes = true
   for i = 1,#self.nodes do
     same_nodes = same_nodes and (self.nodes[i] == other.nodes[i])
   end
   return same_nodes
end

--- Returns a readable string representation of the edge.
-- @return String representation of the edge.
-- @ignore This should not appear in the documentation.
function Edge:__tostring()
   local result = "Edge(" .. self.direction .. ", reversed = " .. tostring(self.reversed) .. ", "
   if table.count_pairs(self.nodes) > 0 then
      local node_strings = table.map_values(self.nodes, function (node)
         return node:shortname()
      end)
      result = result .. table.concat(node_strings, ', ')
   end
   return result .. ")"
end
