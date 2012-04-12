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


pipeline = {}






--- The main "graph drawing pipeline" that handles the pre- and 
--- postprocessing for a graph

function pipeline.run_graph_drawing_pipeline(graph, algorithm_class)
  
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

    
    -- If requested, remove loops
    if algorithm_class.works_only_for_loop_free_graphs then
      pipeline.remove_loops(algorithm, subgraph)
    end
    
    -- If requested, collapse multiedges
    if algorithm_class.works_only_for_simple_graphs then
      pipeline.collapse_multiedges(algorithm, subgraph)
    end
    
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
    
    -- If requested, expand multiedges
    if algorithm_class.works_only_for_simple_graphs then
      pipeline.expand_multiedges(algorithm, subgraph)
    end

    -- If requested, restore loops
    if algorithm_class.works_only_for_loop_free_graphs then
      pipeline.restore_loops(algorithm, subgraph)
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










--- Handling of loops
--
--

function pipeline.remove_loops(algorithm, graph)
  local loops = {}

  for _,edge in ipairs(graph.edges) do
    if edge:getHead() == edge:getTail() then
      loops[#loops+1] = edge
    end
  end

  for i=1,#loops do
    graph:deleteEdge(loops[i])
  end
  
  graph[algorithm].loops = loops
end



function pipeline.restore_loops(algorithm, graph)

  for _,edge in ipairs(graph[algorithm].loops) do
    graph:addEdge(edge)
    edge:getTail():addEdge(edge)
  end
  
  graph[algorithm].loops = nil
end




function pipeline.collapse_multiedges(algorithm, graph)
  local collapsed_edges = {}
  local node_processed = {}

  for _,node in ipairs(graph.nodes) do
    node_processed[node] = true

    local multiedge = {}

    local function handle_edge (edge)
      
      local neighbour = edge:getNeighbour(node)

      if not node_processed[neighbour] then
        if not multiedge[neighbour] then
          multiedge[neighbour] = Edge:new{
            direction = Edge.RIGHT,
          }

          collapsed_edges[multiedge[neighbour]] = {}
        end

        table.insert(collapsed_edges[multiedge[neighbour]], edge)
      end
    end      
    
    for _,edge in ipairs(node:getIncomingEdges()) do
      handle_edge(edge)
    end
    
    for _,edge in ipairs(node:getOutgoingEdges()) do
      handle_edge(edge)
    end

    for neighbour, multiedge in pairs(multiedge) do

      if #collapsed_edges[multiedge] <= 1 then
        collapsed_edges[multiedge] = nil
      else
        for _,subedge in ipairs(collapsed_edges[multiedge]) do
          graph:deleteEdge(subedge)
        end

        multiedge:addNode(node)
        multiedge:addNode(neighbour)
        
        graph:addEdge(multiedge)
      end
    end
  end

  graph[algorithm].collapsed_edges = collapsed_edges
end





function pipeline.expand_multiedges(algorithm, graph)
  for multiedge, subedges in pairs(graph[algorithm].collapsed_edges) do
    assert(#subedges >= 2)

    graph:deleteEdge(multiedge)

    for _,edge in ipairs(subedges) do
      
      -- Copy bend points 
      for _,p in ipairs(multiedge.bend_points) do
	edge.bend_points[#edge.bend_points+1] = p:copy()
      end

      -- Copy options
      for k,v in pairs(multiedge.algorithmically_generated_options) do
	edge.algorithmically_generated_options[k] = v
      end

      for node in table.value_iter(edge.nodes) do
        node:addEdge(edge)
      end

      graph:addEdge(edge)
    end
  end

  graph[algorithm].collapsed_edges = nil
end

