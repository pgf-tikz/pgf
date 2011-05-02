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
  local function shortname(node)
    return string.sub(node.name, string.len('not yet positioned@') + 1)
  end

  local axis_node1, axis_node2, desired_angle, flip = orientation.parse(graph)

  local angle = 0
  local gaxis_vector = nil
  local gbase_vector = nil

  if axis_node1 and axis_node2 then
    -- try to find the first node
    local node1 = graph:findNodeIf(function (node) 
      return shortname(node) == axis_node1
    end)

    assert(node1, 'axis node ' .. axis_node1 .. ' does not exist')

    -- try to find the second node
    local node2 = graph:findNodeIf(function (node)
      return shortname(node) == axis_node2
    end)

    assert(node2, 'axis node ' .. axis_node2 .. ' deoes not exist')

    -- create first node vector
    local pos1 = { node1.pos.x, node1.pos.y }
    gbase_vector = Vector:new(2, function (n) return pos1[n] end)

    -- create second node vector
    local pos2 = { node2.pos.x, node2.pos.y }
    local vec2 = Vector:new(2, function (n) return pos2[n] end)

    -- compute the difference vector which also is the graph axis vector
    gaxis_vector = vec2:subtract(gbase_vector)
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
      local x, y = node.pos.x, node.pos.y
      node.pos.x = x * math.cos(angle) - y * math.sin(angle)
      node.pos.y = x * math.sin(angle) + y * math.cos(angle)
    end
  
    if flip then
      -- flip nodes over the axis
      for node in table.value_iter(graph.nodes) do
        if node.pos.y > gbase_vector:get(2) then
          local diff = node.pos.y - gbase_vector:get(2)
          node.pos.y = gbase_vector:get(2) - diff
        elseif node.pos.y < gbase_vector:get(2) then
          local diff = gbase_vector:get(2) - node.pos.y
          node.pos.y = gbase_vector:get(2) + diff
        end
      end
    end

    -- rotate by the angle desired by the user
    angle = (desired_angle / 360) * 2 * math.pi
    for node in table.value_iter(graph.nodes) do
      local x, y = node.pos.x, node.pos.y 
      node.pos.x = x * math.cos(angle) - y * math.sin(angle)
      node.pos.y = x * math.sin(angle) + y * math.cos(angle)
    end
  end
end



--- Parses an orientation or orientation' option.
--
-- The syntax of this option is either (foo):90:(bar) or (foo):(bar),
-- where "foo" and "bar" are the names of two nodes and 90 is the
-- desired angle by which the graph should be rotated relatively to
-- the x axis.
--
-- @param graph A graph.
--
-- @return TODO
--
function orientation.parse(graph)
  local function stripParentheses(name)
    return name:gsub('[%(%)]', '')
  end

  local option = graph:getOption('orientation') or graph:getOption('orientation\'') or ''
  local flip = graph:getOption('orientation\'') ~= nil
  local params = {}

  -- split string into components separated by a ':'
  option:gsub('([^:]+)', function (param) table.insert(params, param) end)

  local node1 = nil
  local node2 = nil
  local angle = 0

  -- strip parentheses from node names
  if #params == 2 then
    node1 = stripParentheses(params[1])
    node2 = stripParentheses(params[2])
  elseif #params == 3 then
    node1 = stripParentheses(params[1])
    node2 = stripParentheses(params[3])
    angle = tonumber(params[2])
  end

  return node1, node2, angle, flip
end
