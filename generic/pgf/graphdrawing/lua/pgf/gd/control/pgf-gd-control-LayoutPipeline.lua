-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local control = require "pgf.gd.control"
local lib     = require "pgf.gd.lib"


--- The LayoutPipeline class is a singleton object.
-- Its methods implement the steps that are applied 
-- to all graphs prior and after a graph drawing algorithm is
-- called.

control.LayoutPipeline = {}



--- The main "graph drawing pipeline" that handles the pre- and 
-- postprocessing for a graph

function control.LayoutPipeline:run(graph, algorithm_class)
  
  self:prepareEvents(graph.events)
  
  -- Decompose the graph into connected components, if necessary:
  local subgraphs

  if algorithm_class.works_only_on_connected_graphs then
    subgraphs = lib.Components:decompose(graph)
    lib.Components:sort(graph, subgraphs)    
  else
    subgraphs = { graph }
  end
  
  for _,subgraph in ipairs(subgraphs) do
    -- Reset random number generator
    math.randomseed(graph:getOption('/graph drawing/random seed'))
    
    local algorithm = algorithm_class:new(subgraph)    
    subgraph:registerAlgorithm(algorithm)
    
    -- If requested, remove loops
    if algorithm_class.works_only_for_loop_free_graphs then
      lib.Simplifiers:removeLoops(algorithm)
    end
    
    -- If requested, collapse multiedges
    if algorithm_class.works_only_for_simple_graphs then
      lib.Simplifiers:collapseMultiedges(algorithm)
    end
    
    -- Compute anchor_node
    lib.Anchoring:computeAnchorNode(subgraph)

    -- Compute growth-adjusted sizes
    lib.Orientation:prepareRotateAround(algorithm)
    lib.Orientation:prepareBoundingBoxes(algorithm)

    -- Compute a spanning tree, if necessary
    if algorithm_class.needs_a_spanning_tree then
      lib.Simplifiers:runSpanningTreeAlgorithm(algorithm)
    end

    if #subgraph.nodes > 1 or algorithm_class.run_also_for_single_node then
      -- Main run of the algorithm:
      algorithm:run ()
    end
    
    -- If requested, expand multiedges
    if algorithm_class.works_only_for_simple_graphs then
      lib.Simplifiers:expandMultiedges(algorithm)
    end

    -- If requested, restore loops
    if algorithm_class.works_only_for_loop_free_graphs then
      lib.Simplifiers:restoreLoops(algorithm)
    end
    
    lib.Orientation:orient(algorithm)
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
  
  lib.Components:pack (graph, unanchored)
  lib.Anchoring:anchor(graph)

  for _,subgraph in ipairs(anchored) do
    lib.Anchoring:anchor(subgraph)
  end
end



--- Store for each begin/end event the index of
-- its corresponding end/begin event
--
-- @param events An event list

function control.LayoutPipeline:prepareEvents(events)

  local stack = {}

  for i=1,#events do
    if events[i].kind == "begin" then
      stack[#stack + 1] = i
    elseif events[i].kind == "end" then
      local tos = stack[#stack]
      stack[#stack] = nil -- pop

      events[tos].end_index = i
      events[i].begin_index = tos
    end
  end
end


-- Done

return control.LayoutPipeline