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

-- This file defines a node class, used in the graph representation.

pgf.module("pgf.graphdrawing")

Node = Box:new{}
Node.__index = Node

--- Creates a new node.
-- @param values Values (e.g. position) to be merged with the default-metatable of a node
-- @return A newly allocated node object.
function Node:new(values)
   local defaults = {
      name = "node",
      tex = { texNode = nil,
      		  maxX = 0,
      		  minX = 0,
      		  maxY = 0,
      		  minY = 0 },
      edges = {},
      pos = Position:new(),
      options = {},
   }
   setmetatable(defaults, Node)
   local result = mergeTable(values, defaults)
   return result
end

--- Sets the option name to value.
-- @param name Name of the option to be set.
-- @param value Value for the option defined by name.
function Node:setOption(name, value)
   self.options[name] = value
end

--- Returns the value of option name or nil.
-- @param name Name of the option.
-- @return The stored value of the option or nil.
function Node:getOption(name)
   return self.options[name]
end

--- Merges options.
-- @param options The options to be merged.
-- @see mergeTable
function Node:mergeOptions(options)
   self.options = mergeTable(options, self.options)
end

--- Computes the Width of the Node.
-- @return Width of the Node.
function Node:getTexWidth()
	return self.tex.maxX - self.tex.minX
end

--- Computes the Heigth of the Node.
-- @return Height of the Node.
function Node:getTexHeight()
	return self.tex.maxY - self.tex.minY
end

--- Adds new Edge to the Node.
-- @param edge The edge to be added.
function Node:addEdge(edge)
   if not table.find(self.edges, function (other) return other == edge end) then
      table.insert(self.edges, edge)
   end
end

--- Removes an edge from the node.
-- @param edge The edge to remove.
function Node:removeEdge(edge)
   table.remove_values(self.edges, function (other) return other == edge end)
end

--- Computes the number of neighbour nodes.
-- @return Number of neighbours.
function Node:degree()
	return table.count_pairs(self.edges)
end

--- Returns the incoming edges of the node. Undefined result for hyperedges.
--
-- @param ignore_reversed Optional parameter to consider reversed edges not 
--                        reversed for this method call. Defaults to false.
--
-- @return Incoming edges of the node. This includes undirected edges
--         and directed edges pointing to the node.
--
function Node:getIncomingEdges(ignore_reversed)
  return table.filter_values(self.edges, function (edge) 
    return edge:isHead(self, ignore_reversed)
  end)
end

--- Returns the outgoing edges of the node. Undefined result for hyperedges.
--
-- @param ignore_reversed Optional parameter to consider reversed edges not 
--                        reversed for this method call. Defaults to false.
--
-- @return Outgoing edges of the node. This includes undirected edges
--         and directed edges leaving the node.
--
function Node:getOutgoingEdges(ignore_reversed)
  return table.filter_values(self.edges, function (edge)
    return edge:isTail(self, ignore_reversed)
  end)
end

--- Returns the number of incoming edges of the node.
--
-- @see Node:getIncomingEdges(reversed)
--
-- @param ignore_reversed Optional parameter to consider reversed edges not 
--                        reversed for this method call. Defaults to false.
--
-- @return The number of incoming edges of the node.
--
function Node:getInDegree(ignore_reversed)
  return table.count_pairs(self:getIncomingEdges(ignore_reversed))
end

--- Returns the number of edges starting at the node.
--
-- @see Node:getOutgoingEdges()
--
-- @param ignore_reversed Optional parameter to consider reversed edges not 
--                        reversed for this method call. Defaults to false.
--
-- @return The number of outgoing edges of the node.
--
function Node:getOutDegree(ignore_reversed)
  return table.count_pairs(self:getOutgoingEdges(ignore_reversed))
end

--- Creates a shallow copy of a node.
-- @return Copy of the node.
function Node:copy()
   obj = Node:new()
   local result = copyTable(self, obj)
   obj.edges = {}
   --obj.pos = self.pos:copy()
   return obj
end

--- Compares two nodes by name.
-- @param object The node to be compared to self
-- @return True if self is equal to object.
function Node:__eq(object)
   Sys:logMessage('LAY: node eq function called')
   return self.name == object.name;
end

--- Returns a formated string representation of the node.
-- @return String represenation of the node.
-- @ignore This should not appear in the documentation.
function Node:__tostring()
   local tmp = Node.__tostring
   Node.__tostring = nil
   local result = "Node<" .. tostring(self) .. ">(" .. self.name .. ")"
   Node.__tostring = tmp

   return result
end
