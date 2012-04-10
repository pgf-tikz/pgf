-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

pgf.module("pgf.graphdrawing")



CycleRemovalBergerS1990b = {}
CycleRemovalBergerS1990b.__index = CycleRemovalBergerS1990b



function CycleRemovalBergerS1990b:new(main_algorithm, graph)
  local algorithm = {
    main_algorithm = main_algorithm,
    graph = graph,
  }
  setmetatable(algorithm, CycleRemovalBergerS1990b)
  return algorithm
end



function CycleRemovalBergerS1990b:run()
  -- remember edges that were removed
  local removed = {}

  -- remember edges that need to be reversed
  local reverse = {}

  -- iterate over all nodes of the graph
  for node in table.randomized_value_iter(self.graph.nodes) do
    -- get all outgoing edges that have not been removed yet
    local out_edges = table.filter_values(node:getOutgoingEdges(), function (edge)
      return not removed[edge]
    end)

    -- get all incoming edges that have not been removed yet
    local in_edges = table.filter_values(node:getIncomingEdges(), function (edge)
      return not removed[edge]
    end)

    if #out_edges >= #in_edges then
      -- we have more outgoing than incoming edges, reverse all incoming 
      -- edges and mark all incident edges as removed
      
      for edge in table.value_iter(out_edges) do
        removed[edge] = true
      end
      for edge in table.value_iter(in_edges) do
        reverse[edge] = true
        removed[edge] = true
      end
    else
      -- we have more incoming than outgoing edges, reverse all outgoing
      -- edges and mark all incident edges as removed

      for edge in table.value_iter(out_edges) do
        reverse[edge] = true
        removed[edge] = true
      end
      for edge in table.value_iter(in_edges) do
        removed[edge] = true
      end
    end
  end

  -- mark edges as reversed
  for edge in table.key_iter(reverse) do
    edge.reversed = true
  end
end

