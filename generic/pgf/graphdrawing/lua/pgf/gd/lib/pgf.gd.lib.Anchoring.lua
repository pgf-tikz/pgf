-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The Anchoring class is a singleton object.
--
-- It provide methods for anchoring a graph.

local Anchoring = {}



-- Namespace
local lib = require("pgf.gd.lib")
lib.Anchoring = Anchoring



--- Pre layout step:
--
-- Determine the anchor node of the graph
--
-- @param graph A graph whose anchor_node key will be set
--        if a user-specified anchor node is found in the algorithm's graph.

function Anchoring:computeAnchorNode(graph)

  local anchor_node
  
  local anchor_node_name = graph.options['/graph drawing/anchor node']
  if anchor_node_name then
    anchor_node = graph.scope.node_names[anchor_node_name]
  end
  
  if not graph:contains(anchor_node) then
    anchor_node =
      lib.find (graph.vertices, function (v) return v.options['/graph drawing/anchor here'] end) or
      lib.find (graph.vertices, function (v) return v.options['/graph drawing/desired at'] end)
  end

  if graph:contains(anchor_node) then
    graph.storage[Anchoring].anchor_node = anchor_node
  end
end



--- Performs a post-layout anchoring of a graph
--
-- Performs the graph anchoring procedure described in
-- Section~\ref{subsection-library-graphdrawing-anchoring} of the pgf manual.
-- 
-- @param graph A graph

function Anchoring:anchor(graph)

  local anchor_node = graph.storage[Anchoring].anchor_node or graph.vertices[1]
  
  local anchor_x = anchor_node.pos.x
  local anchor_y = anchor_node.pos.y

  local desired = anchor_node.options['/graph drawing/desired at'] or graph.options['/graph drawing/anchor at']
  
  local target_x = desired[1]
  local target_y = desired[2]
     
  local delta_x = target_x - anchor_x
  local delta_y = target_y - anchor_y
  
  -- Step 3: Shift nodes
  for _,v in ipairs(graph.vertices) do
    v.pos:shift(delta_x,delta_y)
  end
  for _,a in ipairs(graph.arcs) do
    for _,m in ipairs(a.storage.syntactic_edges) do
      for _,p in ipairs(m.path) do
	p:shift(delta_x, delta_y)
      end
    end
  end
end




-- Done

return Anchoring