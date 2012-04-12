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


--- Pre layout step:
--
-- Determine the anchor node of the graph
--
-- @param A graph, in which the anchor_node key will be set
--        if a user-specified anchor node is found.

function anchoring.compute_anchor_node(graph)
  
  local anchor_node
  
  local anchor_node_name = graph:getOption('/graph drawing/anchor node')
  if anchor_node_name then
    anchor_node = graph:findNodeIf(
      function (node) 
	return node.name == anchor_node_name
      end)
  end
  
  if not anchor_node then
    anchor_node = graph:findNodeIf(
      function (node) 
	return node:getOption('/graph drawing/anchor here') == 'true'
      end) or
      graph:findNodeIf(
      function (node) 
	return node:getOption('/graph drawing/desired at')
      end)
  end
  
  graph.anchor_node = anchor_node   
end


--- Performs a post-layout anchoring of a graph
--
-- Performs the graph anchoring procedure described in
-- Section~\ref{subsection-library-graphdrawing-anchoring} of the pgf manual.
-- 
-- @param graph A graph object.

function anchoring.perform_post_layout_steps(graph)
   
  local anchor_node = graph.anchor_node or graph.nodes[1]
   
  local anchor_x = anchor_node.pos.x
  local anchor_y = anchor_node.pos.y
  
  local desired = anchor_node:getOption('/graph drawing/desired at') or graph:getOption('/graph drawing/anchor at') 
  
  local target_x
  local target_y
  
   target_x, target_y = desired:gmatch('{([%d.-]+)}{([%d.-]+)}')()
   
   local delta_x = target_x - anchor_x
   local delta_y = target_y - anchor_y
   
   -- Step 3: Shift nodes
   for node in table.value_iter(graph.nodes) do
     node.pos.x = node.pos.x + delta_x
     node.pos.y = node.pos.y + delta_y
   end
   for edge in table.value_iter(graph.edges) do
     for point in table.value_iter(edge.bend_points) do
       point.x = point.x + delta_x
       point.y = point.y + delta_y
     end
   end
end


