-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The NodeDistances class is a singleton object.
--
-- Its methods are used to compute and/or set the ideal distances between
-- nodes of a graph. The methods take parameters like sibling distance or
-- layer sep into account.

local NodeDistances = {}

-- Namespace
local lib     = require "pgf.gd.lib"
lib.NodeDistances = NodeDistances



--- Compute the ideal distance between two siblings
--
-- @param algorithm The algorithm object
-- @param graph The graph object
-- @param n1 The first node
-- @param n2 The second node

function NodeDistances:idealSiblingDistance (algorithm, graph, n1, n2)
  local ideal_distance
  local sep

  local n1_is_node = n1.kind == "node"
  local n2_is_node = n2.kind == "node"

  if not n1_is_node and not n2_is_node then
    ideal_distance = tonumber(graph:getOption('/graph drawing/sibling distance'))
    sep =   tonumber(graph:getOption('/graph drawing/sibling post sep'))
          + tonumber(graph:getOption('/graph drawing/sibling pre sep'))
  else
    if n1_is_node then
      ideal_distance = tonumber(n1:getOption('/graph drawing/sibling distance', graph))
    else
      ideal_distance = tonumber(n2:getOption('/graph drawing/sibling distance', graph))
    end
    sep =   tonumber(n1_is_node and n1:getOption('/graph drawing/sibling post sep', graph) or 0)
          + tonumber(n2_is_node and n2:getOption('/graph drawing/sibling pre sep', graph) or 0)
  end
  
  return math.max(ideal_distance, sep + 
		  ((n1_is_node and n1[algorithm].adjusted_bounding_box.sibling_post) or 0) -
  		  ((n2_is_node and n2[algorithm].adjusted_bounding_box.sibling_pre) or 0))
end



--- Compute the baseline distance between two layers
--
-- The "baseline" distance is the distance between two layers that
-- corresponds to the distance of the two layers if the nodes where
-- "words" on two adjacent lines. In this case, the distance is
-- normally the layer_distance, but will be increased such if we draw a
-- horizontal line below the deepest character on the first line and a
-- horizontal line above the highest character on the second line, the
-- lines will have a minimum distance of layer sep.
--
-- Since each node on the lines might have a different layer sep and
-- layer distance specified, the maximum over all the values is taken.
--
-- @param algorithm The algorithm object
-- @param graph The graph in which the nodes reside
-- @param l1 An array of the nodes of the first layer
-- @param l2 An array of the nodes of the second layer

function NodeDistances:baselineDistance (algorithm, graph, l1, l2)

  if #l1 == 0 or #l2 == 0 then
    return 0
  end
  
  local layer_distance = -math.huge
  local layer_pre_sep  = -math.huge
  local layer_post_sep = -math.huge

  local max_post = -math.huge
  local min_pre = math.huge

  for _,n in ipairs(l1) do
    layer_distance = math.max(layer_distance,
			      tonumber(n:getOption('/graph drawing/level distance', graph)))
    layer_post_sep = math.max(layer_post_sep,
			      tonumber(n:getOption('/graph drawing/level post sep', graph)))
    if n.kind == "node" then
      max_post = math.max(max_post, n[algorithm].adjusted_bounding_box.layer_post)
    end
  end

  for _,n in ipairs(l2) do
    layer_pre_sep = math.max(layer_pre_sep,
			     tonumber(n:getOption('/graph drawing/level pre sep', graph)))
    if n.kind == "node" then
      min_pre = math.min(min_pre, n[algorithm].adjusted_bounding_box.layer_pre)
    end
  end
  
  return math.max(layer_distance, layer_post_sep + layer_pre_sep + max_post - min_pre)
end



--- Position nodes in layers using baselines
--
-- @param algorithm The algorithm object
-- @param graph The graph in which the nodes reside

function NodeDistances:arrangeLayersByBaselines (algorithm, graph)

  local layers = {}
  
  -- Decompose into layers:
  for _,n in ipairs(graph.nodes) do
    local y = n[algorithm].y
    if not layers[y] then
      layers[y] = {}
    end
    table.insert(layers[y], n)
  end
  
  if #layers > 0 then -- sanity check
    -- Now compute ideal distances and store
    local height = 0

    for _,n in ipairs(layers[1]) do
      n.pos.y = 0
    end
    
    for i=2,#layers do
      height = height + self:baselineDistance(algorithm, graph, layers[i-1], layers[i])

      for _,n in ipairs(layers[i]) do
	n.pos.y = height 
      end
    end
  end
end



-- Done

return NodeDistances