-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file contains a number of standard graph algorithms such as Dijkstra.

pgf.module("pgf.graphdrawing")



anchoring = {}



--- Performs a post-layout anchoring of a graph
--
-- Performs the graph anchoring procedure described in
-- Section~\ref{subsection-library-graphdrawing-anchoring} of the pgf manual.
-- 
-- @param algorithm An algorithm object.

function anchoring.perform_post_layout_steps(algorithm)
   
   -- Step 1: Search for a node with a desired position.
   local anchor_node

   local anchor_node_name = algorithm.graph:getOption('/graph drawing/anchor node')
   if anchor_node_name then
      anchor_node = algorithm.graph:findNodeIf(
	 function (node) 
	    return node.name == anchor_node_name
	 end)
   end

   if not anchor_node then
      anchor_node = algorithm.graph:findNodeIf(
	 function (node) 
	    return node:getOption('/graph drawing/anchor here') == 'true'
	 end) or
         algorithm.graph:findNodeIf(
	 function (node) 
	    return node:getOption('/graph drawing/desired at')
	 end) or
         algorithm.graph.nodes[1]
   end
   
   
   -- Step 2: Compute vector
   local anchor_x = anchor_node.pos:x()
   local anchor_y = anchor_node.pos:y()
   
   local desired = anchor_node:getOption('/graph drawing/desired at') or algorithm.graph:getOption('/graph drawing/anchor at') 

   local target_x
   local target_y

   target_x, target_y = desired:gmatch('{([%d.-]+)}{([%d.-]+)}')()

   local delta_x = target_x - anchor_x
   local delta_y = target_y - anchor_y
   
   -- Step 3: Shift nodes
   for node in table.value_iter(algorithm.graph.nodes) do
      node.pos:set{
	 x = node.pos:x() + delta_x,
	 y = node.pos:y() + delta_y
      }
   end
   for edge in table.value_iter(algorithm.graph.edges) do
      for point in table.value_iter(edge.bend_points) do
	 point:set{
	    x = point:x() + delta_x,
	    y = point:y() + delta_y
	 }
      end
   end
end


