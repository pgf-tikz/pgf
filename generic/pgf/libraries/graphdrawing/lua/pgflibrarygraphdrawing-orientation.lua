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

  local axis_node1, axis_node2, desired_angle = orientation.parse(graph)

  if axis_node1 and axis_node2 then
    -- try to find the first node
    local node1 = graph:findNodeIf(function (node) 
      return shortname(node) == axis_node1
    end)

    -- try to find the second node
    local node2 = graph:findNodeIf(function (node)
      return shortname(node) == axis_node2
    end)

    assert(node1 and node2, 'the axis nodes ' .. axis_node1 .. ' and ' .. axis_node2 .. ' do not exist')

    -- create first node vector
    local pos1 = { node1.pos.x, node1.pos.y }
    local vec1 = Vector:new(2, function (n) return pos1[n] end)

    -- create second node vector
    local pos2 = { node2.pos.x, node2.pos.y }
    local vec2 = Vector:new(2, function (n) return pos2[n] end)

    -- create difference vector 
    local vec_diff = vec2:subtract(vec1)

    -- create vector parallel to x axis
    local pos_axis = { 10, 0 }
    local vec_axis = Vector:new(2, function (n) return pos_axis[n] end)

    -- compute the lenghts of these two vectors
    local len_diff = vec_diff:norm()
    local len_axis = vec_axis:norm()

    -- compute the angle between the x axis and the difference vector
    local angle = math.acos(vec_axis:dotProduct(vec_diff) / (len_diff * len_axis))

    -- determine whether the difference vector is positively 
    -- rotated to the x axis
    local direction = vec_diff:get(2) * vec_axis:get(1) - vec_axis:get(2) * vec_axis:get(1)

    -- if it is positively rotated, rotate counter-clockwise
    if direction >= 0 then
      angle = (-1) * angle
    end

    -- add the angle desired by the user
    local user_angle = (desired_angle / 360) * 2 * math.pi
    angle = angle + user_angle

    -- perform the rotation
    for node in table.value_iter(graph.nodes) do
      local x, y = node.pos.x, node.pos.y
      node.pos.x = x * math.cos(angle) - y * math.sin(angle)
      node.pos.y = x * math.sin(angle) + y * math.cos(angle)
    end
  end
end



--- Parses an orientation option.
--
-- The syntax of this option is either (foo):90:(bar) or (foo):(bar),
-- where "foo" and "bar" are the names of two nodes and 90 is the
-- desired angle by which the graph should be rotated relatively to
-- the x axis.
--
-- @param graph A graph.
--
function orientation.parse(graph)
  local function stripParentheses(name)
    return name:gsub('[%(%)]', '')
  end

  local option = graph:getOption('orientation') or ''
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

  return node1, node2, angle
end
