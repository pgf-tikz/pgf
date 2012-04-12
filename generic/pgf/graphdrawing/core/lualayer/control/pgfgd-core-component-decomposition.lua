-- Copyright 2012 by Till Tantau
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



--- Decompose a graph into its components
--
-- @param graph A to-be-decomposed graph
--
-- @result An array of graph objects that represent the connected components of the graph. 

function compute_component_decomposition (graph)

   -- The list of connected components (node sets)
   local components = {}

   -- Remember, which graphs have already been visited
   local visited = {}
   
   for i,n in ipairs(graph.nodes) do
      if not visited[n] then
	 -- Start a depth-first-search of the graph, starting at node n:
	 local stack = { n }
	 local nodes = {}
	 
	 while #stack >= 1 do
	    local tos = stack[#stack]
	    stack[#stack] = nil -- pop

	    if not visited[tos] then
	       -- Visit pos:
	       nodes[#nodes+1] = tos
	       visited[tos] = true
	       
	       for _,e in ipairs(tos.edges) do
		  for _,neighbor in ipairs(e.nodes) do
		     if not visited[neighbor] then
			stack[#stack+1] = neighbor
		     end
		  end
	       end
	    end
	 end

	 -- Ok, nodes will now contain all vertices reachable from n.
	 components[#components+1] = nodes
      end
   end

   -- Case 1: Only one components -> do not do anything
   if #components < 2 then
      return { graph }
   end

   -- Case 2: Multiple components
   local graphs = {}
      
   for i = 1,#components do
      -- Build a graph containing only the nodes in the components
      local subgraph = graph:copy()
      
      subgraph.nodes = components[i]
      
      -- add edges
      local edges = {}
      for _,n in ipairs(subgraph.nodes) do
	 for _,e in ipairs(n.edges) do
	    edges[e] = true
	 end
      end
      
      for e in pairs(edges) do
	 subgraph.edges[#subgraph.edges + 1] = e
      end
      
      table.sort (subgraph.nodes, function (a, b) return a.index < b.index end)
      table.sort (subgraph.edges, function (a, b) return a.index < b.index end)
      
      graphs[#graphs + 1] = subgraph
   end
   
   return graphs
end