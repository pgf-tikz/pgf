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
--
-- @param values Values to override default edge settings.
--               The following parameters can be set:\par
--               |nodes|: TODO \par
--               |edge_nodes|: TODO \par
--               |options|: TODO \par
--               |tikz_options|: TODO \par 
--               |direction|: TODO \par
--               |bend_points|: TODO \par
--               |bend_nodes|: TODO \par
--               |reversed|: TODO \par
--
-- @return A newly-allocated edge.
--
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
    algorithmically_generated_options = {},
    index = nil,
  }
  setmetatable(defaults, Edge)
  local result = table.custom_merge(values, defaults)
  return result
end



--- Sets the edge option \meta{name} to \meta{value}.
--
-- @param name Name of the option to be changed.
-- @param value New value for the edge option \meta{name}.
--
function Edge:setOption(name, value)
  self.options[name] = value
end



--- Returns the value of the edge option \meta{name}.
--
-- @param name Name of the option.
--
-- @return The value of the edge option \meta{name} or |nil|.
--
function Edge:getOption(name)
   return self.options[name] or Interface.defaultGraphParameters[name]
end



--- Checks whether or not the edge is a loop edge.
--
-- An edge is a loop if it one node multiple times and no other node.
--
-- @return |true| if the edge is a loop, |false| otherwise.
--
function Edge:isLoop()
  local nodes_equal = table.combine_values(self.nodes, function (nodes_equal, node)
    return nodes_equal and node == self.nodes[1]
  end, true)
  return nodes_equal
end



--- Returns whether or not the edge is a hyperedge.
--
-- A hyperedge is an edge with more than two adjacent nodes.
--
-- @return |true| if the edge is a hyperedge. |false| otherwise.
--
function Edge:isHyperedge()
  return self:getDegree() > 2
end



--- Returns all nodes of the edge.
--
-- Instead of calling |edge:getNodes()| the nodes can alternatively be 
-- accessed directly with |edge.nodes|.
--
-- @return All edges of the node.
--
function Edge:getNodes()
  return self.nodes
end



--- Returns whether or not a node is adjacent to the edge.
--
-- @param node The node to check.
--
-- @return |true| if the node is adjacent to the edge. |false| otherwise.
--
function Edge:containsNode(node)
  return table.find(self.nodes, function (other) return other == node end) ~= nil
end



--- If possible, adds a node to the edge.
--
-- @param node The node to be added to the edge.
--
function Edge:addNode(node)
  --if not self:containsNode(node) then
    table.insert(self.nodes, node)
    node:addEdge(self)
  --end
end



--- Gets first neighbour of the node (disregarding hyperedges).
--
-- @param node The node which first neighbour should be returned.
--
-- @return The first neighbour of the node.
--
function Edge:getNeighbour(node)
  if node == self.nodes[1] then
    return self.nodes[#self.nodes]
  else
    return self.nodes[1]
  end
end



--- Counts the nodes on this edge.
--
-- @return The number of nodes on the edge.
--
function Edge:getDegree()
  return table.count_pairs(self.nodes)
end



function Edge:getHead()
  -- by default, the head of -> edges is the last node and the head
  -- of <- edges is the first node
  local head_index = (self.direction == Edge.LEFT) and 1 or #self.nodes

  -- if the edge should be assumed reversed, we simply switch head and 
  -- tail positions
  if not ignore_reversed and self.reversed then
    head_index = (head_index == 1) and #self.nodes or 1
  end

  return self.nodes[head_index]
end



function Edge:getTail()
  -- by default, the tail of -> edges is the first node and the tail
  -- of <- edges is the last node
  local tail_index = (self.direction == Edge.LEFT) and #self.nodes or 1

  -- if the edge should be assumed reversed, we simply switch head
  -- and tail positions
  if not ignore_reversed and self.reversed then
    tail_index = (tail_index == 1) and #self.nodes or 1
  end

  return self.nodes[tail_index]
end



--- Checks whether a node is the head of the edge. Does not work for hyperedges.
--
-- This method only works for edges with two adjacent nodes.
--
-- Edges may be reversed internally, so their head and tail might be switched. 
-- Whether or not this internal reversal is handled by this method 
-- can be specified with the optional second \meta{ignore\_reversed} parameter 
-- which is |false| by default.
--
-- @param node            The node to check.
-- @param ignore_reversed Optional parameter. Set this to true if reversed edges
--                        should not be considered reversed for this method call.
--
-- @return True if the node is the head of the edge.
--
function Edge:isHead(node, ignore_reversed)
  local result = false

  -- by default, the head of -> edges is the last node and the head
  -- of <- edges is the first node
  local head_index = (self.direction == Edge.LEFT) and 1 or #self.nodes

  -- if the edge should be assumed reversed, we simply switch head and 
  -- tail positions
  if not ignore_reversed and self.reversed then
    head_index = (head_index == 1) and #self.nodes or 1
  end

  -- check if the head node equals the input node
  if self.nodes[head_index].name == node.name then
    result = true
  end

  return result
end



--- Checks whether a node is the tail of the edge. Does not work for hyperedges.
--
-- This method only works for edges with two adjacent nodes.
--
-- Edges may be reversed internally, so their head and tail might be switched.
-- Whether or not this internal reversal is handled by this method 
-- can be specified with the optional second \meta{ignore\_reversed} parameter 
-- which is |false| by default.
--
-- @param node            The node to check.
-- @param ignore_reversed Optional parameter. Set this to true if reversed edges
--                        should not be considered reversed for this method call.
--
-- @return True if the node is the tail of the edge.
--
function Edge:isTail(node, ignore_reversed)
  local result = false
  
  -- by default, the tail of -> edges is the first node and the tail
  -- of <- edges is the last node
  local tail_index = (self.direction == Edge.LEFT) and #self.nodes or 1

  -- if the edge should be assumed reversed, we simply switch head
  -- and tail positions
  if not ignore_reversed and self.reversed then
    tail_index = (tail_index == 1) and #self.nodes or 1
  end

  -- check if the tail node equals the input node
  if self.nodes[tail_index].name == node.name then
    result = true
  end

  return result
end



--- Copies an edge (preventing accidental use).
--
-- The nodes of the edge are not preserved and have to be added
-- to the copy manually if necessary.
--
-- @return Shallow copy of the edge.
--
function Edge:copy()
  local result = table.custom_copy(self, Edge:new())
  result.nodes = {}
  return result
 end



----- Returns whether or not the two edges have the same adjacent nodes.
----
---- @ignore This should not appear in the documentation.
----
---- @param other Another edge to compare with.
----
---- @return |true| if the two edges have exactly the same adjacent nodes.
----
--function Edge:__eq(other)
--  if not other or not other.nodes or #self.nodes ~= #other.nodes then
--    return false
--  end
--  
--  local same_nodes = true
--  for i = 1,#self.nodes do
--    same_nodes = same_nodes and (self.nodes[i] == other.nodes[i])
--  end
--  return same_nodes
--end



--- Returns a readable string representation of the edge.
--
-- @ignore This should not appear in the documentation.
--
-- @return String representation of the edge.
--
function Edge:__tostring()
  local result = "Edge(" .. self.direction .. ", reversed = " .. tostring(self.reversed) .. ", "
  if table.count_pairs(self.nodes) > 0 then
    local node_strings = table.map_values(self.nodes, function (node)
      return node.name
    end)
    result = result .. table.concat(node_strings, ', ')
  end
  --return result .. ")"
  
  -- Note: the following lines generate a shorter string representation
  -- of the edge that is more readable and can be used for debugging.
  -- So please don't remove this:
  --
  local node_strings = table.map_values(self.nodes, function (node)
    return node.name
  end)
  if self.reversed then
    return table.concat(table.reverse_values(node_strings), ' ' .. self.direction .. ' ')
  else
    return table.concat(node_strings, ' ' .. self.direction .. ' ')
  end
end
