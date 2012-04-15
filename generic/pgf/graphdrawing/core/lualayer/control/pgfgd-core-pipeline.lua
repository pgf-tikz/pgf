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
    pipeline.order_components (graph, subgraphs)    
  else
    subgraphs = { graph }
  end
  
  for _,subgraph in ipairs(subgraphs) do
    -- Reset random number generator
    math.randomseed(graph:getOption('/graph drawing/random seed'))
    
    local algorithm = algorithm_class:new(subgraph)    
    pipeline.prepare_graph_for_algorithm(algorithm)
    
    -- If requested, remove loops
    if algorithm_class.works_only_for_loop_free_graphs then
      pipeline.remove_loops(algorithm)
    end
    
    -- If requested, collapse multiedges
    if algorithm_class.works_only_for_simple_graphs then
      pipeline.collapse_multiedges(algorithm)
    end
    
    -- Compute anchor_node
    anchoring.compute_anchor_node(subgraph)

    -- Compute growth-adjusted sizes
    growth_adjust.prepare_post_layout_orientation(algorithm)
    growth_adjust.compute_bounding_boxes(algorithm)

    -- Compute a spanning tree, if necessary
    if algorithm_class.needs_a_spanning_tree then
      pipeline.run_spanning_algorithm(algorithm)
    end

    if #subgraph.nodes > 1 or algorithm_class.run_also_for_single_node then
      -- Main run of the algorithm:
      algorithm:run ()
    end
    
    -- If requested, expand multiedges
    if algorithm_class.works_only_for_simple_graphs then
      pipeline.expand_multiedges(algorithm)
    end

    -- If requested, restore loops
    if algorithm_class.works_only_for_loop_free_graphs then
      pipeline.restore_loops(algorithm)
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




function pipeline.run_spanning_algorithm(algorithm)
  local name = algorithm.graph:getOption("/graph drawing/spanning tree algorithm"):gsub(' ', '')
  
  -- if not defined, try to load the corresponding file
  if not pgf.graphdrawing[name] then
    pgf.load("pgfgd-subalgorithm-" .. name .. ".lua", "tex", false)
  end
  
  local spanning_algorithm_class = pgf.graphdrawing[name]

  assert(spanning_algorithm_class, "No subalgorithm named '" .. name .. "' was found. " ..
	 "Either the file does not exist or the class declaration is wrong.")
  
  local spanning_algorithm = spanning_algorithm_class:new(algorithm.graph, algorithm)    
  pipeline.prepare_graph_for_algorithm(spanning_algorithm)
  
  spanning_algorithm:run()
end


--- Prepare a graph for an algorithm
--
-- This function will add an empty table to each edge, node, of the 
-- algorithm's graph as well as to the algorithm's graph itself. These
-- empty tables can be indexed via the algorithm. The idea is that in
-- this way, multiple algorithm objects can store information at
-- nodes, edges, and graphs without interfering. 
--
-- @param algorithm An algorithm

function pipeline.prepare_graph_for_algorithm(algorithm)
  local g = algorithm.graph
  g[algorithm] = {}

  -- Add an algorithm field to all nodes, all edges, and the graph:
  for _,n in pairs(g.nodes) do
    n[algorithm] = {}
  end
  for _,e in pairs(g.edges) do
    e[algorithm] = {}
  end
end





--- Handling of loops
--
--

function pipeline.remove_loops(algorithm)
  local graph = algorithm.graph
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



function pipeline.restore_loops(algorithm)
  local graph = algorithm.graph

  for _,edge in ipairs(graph[algorithm].loops) do
    graph:addEdge(edge)
    edge:getTail():addEdge(edge)
  end
  
  graph[algorithm].loops = nil
end




function pipeline.collapse_multiedges(algorithm, collapse_action)
  local graph = algorithm.graph
  local collapsed_edges = {}
  local node_processed = {}

  for _,node in ipairs(graph.nodes) do
    node_processed[node] = true

    local multiedge = {}

    local function handle_edge (edge)
      
      local neighbour = edge:getNeighbour(node)

      if not node_processed[neighbour] then
        if not multiedge[neighbour] then
          multiedge[neighbour] = Edge:new{ direction = Edge.RIGHT }
          collapsed_edges[multiedge[neighbour]] = {}
        end

	if collapse_action then
	  collapse_action(multiedge[neighbour], edge, graph)
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





function pipeline.expand_multiedges(algorithm)
  local graph = algorithm.graph
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




--- Handling of component order
--
-- Components are ordered according to a function that is stored in
-- a key of the pipeline.component_ordering_functions table (subject
-- to change...) whose name is the graph option /graph
-- drawing/component order. 

function pipeline.order_components(graph, subgraphs)
  local component_order = graph:getOption('/graph drawing/component order')

  if component_order then
    local f = pipeline.component_ordering_functions[component_order]
    if f then
      table.sort (subgraphs, f)
    end
  end
end


-- Right now, we hardcode the functions here. Perhaps make this
-- dynamic in the future. Could easily be done on the tikzlayer,
-- acutally. 

pipeline.component_ordering_functions = {
  ["increasing node number"] = 
    function (g,h) 
      if #g.nodes == #h.nodes then
	return g.nodes[1].index < h.nodes[1].index
      else
	return #g.nodes < #h.nodes 
      end
    end,
  ["decreasing node number"] = 
    function (g,h) 
      if #g.nodes == #h.nodes then
	return g.nodes[1].index < h.nodes[1].index
      else
	return #g.nodes > #h.nodes 
      end
    end,
  ["by first specified node"] = nil,
}

