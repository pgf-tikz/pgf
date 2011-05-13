-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

pgf.module("pgf.graphdrawing")

orientation = {}



--- Adjusts the orientation of the graph based on TikZ options.
--
-- Based on the TikZ orientation options provided by the graphdrawing
-- library, this method adjusts the orientation of the graph.
--
-- For the different options available please refer to the PGF/TikZ
-- manual.
--
-- @param graph A graph to adjust.
--
function orientation.adjust(graph)
  orientation.rotate(graph)
end



--- Rotates a graph so that its principal axis matches the desired angle.
--
-- The desired axis and angle are specified using TikZ options. For 
-- more information please refer to the PGF/TikZ manual.
--
-- @param graph A graph to rotate.
--
function orientation.rotate(graph)
  local axis_node1, axis_node2, desired_angle, swap = orientation.parse_orientation(graph)

  local angle = 0
  local gaxis_vector = nil
  local gbase_vector = nil

  if axis_node1 and axis_node2 then
    -- try to find the first node
    local node1 = graph:findNodeIf(function (node) 
      return node.name == axis_node1
    end)

    -- try to find the second node
    local node2 = graph:findNodeIf(function (node)
      return node.name == axis_node2
    end)

    if node1 and node2 then
      -- create first node vector
      gbase_vector = node1.pos:copy()

      -- create second node vector
      local vec2 = node2.pos:copy()

      -- compute the difference vector which also is the graph axis vector
      gaxis_vector = vec2:minus(gbase_vector)
    else
      if not node1 then
        Sys:log('axis node ' .. axis_node1 .. ' does not exist')
      end
      if not node2 then
        Sys:log(node2, 'axis node ' .. axis_node2 .. ' deoes not exist')
      end
    end
  end

  -- both base and axis vector have to be set, or none of them
  assert(gbase_vector or not gaxis_vector)

  if gbase_vector and gaxis_vector then
    -- create vector parallel to x axis
    local xaxis_pos = { 10, 0 }
    local xaxis_vector = Vector:new(2, function (n) return xaxis_pos[n] end)

    -- compute the lenghts of these two vectors
    local gaxis_len = gaxis_vector:norm()
    local xaxis_len = xaxis_vector:norm()

    if gaxis_len * xaxis_len > 0 then
      -- compute the angle between the x axis and the graph axis vector
      local angle = math.acos(xaxis_vector:dotProduct(gaxis_vector) / (xaxis_len * gaxis_len))

      -- determine whether the graph axis vector is positively rotated to the x axis
      local direction = gaxis_vector:get(2) * xaxis_vector:get(1) 
                      - xaxis_vector:get(2) * gaxis_vector:get(1)

      -- if it is positively rotated, rotate counter-clockwise
      if direction >= 0 then
        angle = (-1) * angle
      end

      -- perform the rotation
      for node in table.value_iter(graph.nodes) do
        local x, y = node.pos:x(), node.pos:y()
        node.pos:set{x = x * math.cos(angle) - y * math.sin(angle)}
        node.pos:set{y = x * math.sin(angle) + y * math.cos(angle)}
      end
  
      if swap then
        -- flip nodes over the axis
        for node in table.value_iter(graph.nodes) do
          if node.pos:y() > gbase_vector:y() then
            local diff = node.pos:y() - gbase_vector:y()
            node.pos:set{y = gbase_vector:y() - diff}
          elseif node.pos:y() < gbase_vector:y() then
            local diff = gbase_vector:y() - node.pos:y()
            node.pos:set{y = gbase_vector:y() + diff}
          end
        end
      end

      -- rotate by the angle desired by the user
      angle = (desired_angle / 360) * 2 * math.pi
      for node in table.value_iter(graph.nodes) do
        local x, y = node.pos:x(), node.pos:y() 
        node.pos:set{x = x * math.cos(angle) - y * math.sin(angle)}
        node.pos:set{y = x * math.sin(angle) + y * math.cos(angle)}
      end
    end
  end
end



--- Parses the orientation option.
--
-- The syntax of this option is 
--
--   {first axis node}{second axis node}{angle}{normal/swapped}
--
-- @param graph A graph.
--
-- @return TODO
--
function orientation.parse_orientation(graph)
  local option = graph:getOption('/graph drawing/orientation')
  if option then
    local item = '{([^}]*)}'
    local pattern = item .. item .. item .. item
    local node1, node2, angle, swap = option:gmatch(pattern)()
    return node1, node2, tonumber(angle), (swap == 'swapped')
  else
    return nil, nil, 0, false
  end
end
