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



pgf.module("pgf.graphdrawing")


--- The main "graph drawing pipeline" that handles the pre- and 
--- postprocessing for a graph

function run_graph_drawing_pipeline(graph, algorithm_class)
  
  event_handling.prepare_event_list(graph.events)
  

  -- Decompose the graph into connected components, if necessary:
  local graphs
  
  if algorithm_class.works_only_on_connected_graphs then
    subgraphs = compute_component_decomposition(graph)
  else
    subgraphs = { graph }
  end
  
  for _,subgraph in ipairs(subgraphs) do
    -- Reset random number generator
    math.randomseed(graph:getOption('/graph drawing/random seed'))
    
    local algorithm = algorithm_class:new(subgraph)

    -- Add an algorithm field to all nodes, all edges, and the graph:
    for _,n in pairs(graph.nodes) do
      n[algorithm] = {}
    end
    for _,e in pairs(graph.edges) do
      e[algorithm] = {}
    end
    subgraph[algorithm] = {}
    
    -- Compute anchor_node
    anchoring.compute_anchor_node(subgraph)

    -- Compute growth-adjusted sizes
    growth_adjust.prepare_post_layout_orientation(subgraph, algorithm)
    growth_adjust.compute_bounding_boxes(subgraph, algorithm)

    -- Compute a spanning tree, if necessary
    if algorithm_class.needs_a_spanning_tree then
      compute_spanning_tree(subgraph,algorithm)
    end

    if #subgraph.nodes > 1 or algorithm_class.run_also_for_single_node then
      -- Main run of the algorithm:
      algorithm:run ()
    end
    
    orientation.perform_post_layout_steps(algorithm)
  end
  
  -- Find unanchored subgraphs
  local unanchored = {}
  local anchored = {}
  local flag = true
  for _,subgraph in ipairs(subgraphs) do
    if subgraph.anchor_node then
      if flag then
	unanchored[#unanchored + 1] = subgraph
	flag = false
      else
	anchored[#anchored + 1] = subgraph
      end
    else
      unanchored[#unanchored + 1] = subgraph
    end
  end
  
  componentpacking.pack (graph, unanchored)
  anchoring.perform_post_layout_steps(graph)

  for _,subgraph in ipairs(anchored) do
    anchoring.perform_post_layout_steps(subgraph)
  end
end

