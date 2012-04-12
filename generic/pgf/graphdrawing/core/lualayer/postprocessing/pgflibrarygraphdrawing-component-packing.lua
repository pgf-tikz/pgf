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

componentpacking = {}



function componentpacking.prepare_bounding_boxes(nodes, angle, sep)

  for _,n in ipairs(nodes) do
    -- Fill the bounding box field,
    local bb = {}
    
    local corners = {
      { x = n.tex.minX + n.pos:x(), y = n.tex.minY + n.pos:y() },
      { x = n.tex.minX + n.pos:x(), y = n.tex.maxY + n.pos:y() },
      { x = n.tex.maxX + n.pos:x(), y = n.tex.minY + n.pos:y() },
      { x = n.tex.maxX + n.pos:x(), y = n.tex.maxY + n.pos:y() },
    }
	
    bb.min_x = math.huge
    bb.max_x = -math.huge
    bb.min_y = math.huge
    bb.max_y = -math.huge
	
    for i=1,#corners do
      local x =  corners[i].x*math.cos(angle) + corners[i].y*math.sin(angle)
      local y = -corners[i].x*math.sin(angle) + corners[i].y*math.cos(angle)
      
      bb.min_x = math.min (bb.min_x, x)
      bb.max_x = math.max (bb.max_x, x)
      bb.min_y = math.min (bb.min_y, y)
      bb.max_y = math.max (bb.max_y, y)
    end

    -- Enlarge by sep:
    bb.min_x = bb.min_x - sep
    bb.max_x = bb.max_x + sep
    bb.min_y = bb.min_y - sep
    bb.max_y = bb.max_y + sep
    
    bb.center_x =  n.pos:x()*math.cos(angle) + n.pos:y()*math.sin(angle)
    bb.center_y = -n.pos:x()*math.sin(angle) + n.pos:y()*math.cos(angle)
    
    n.component_info = bb
  end
end



--- Pack components
--
-- Rearranges 

function componentpacking.pack(graph, components)
  
  -- Step 1: Preparation, rotation to target direction
  local sep = tonumber(graph:getOption('/graph drawing/component sep'))
  local angle = tonumber(graph:getOption('/graph drawing/component direction'))/180*math.pi
  
  for _,c in ipairs(components) do
    componentpacking.prepare_bounding_boxes(c.nodes, angle, sep/2)
  end
  
  local x_shifts = { 0 }
  local y_shifts = {}
  
  -- Step 2: Vertical alignment
  for i,c in ipairs(components) do
    local max_max_y = -math.huge
    local max_center_y = -math.huge
    local min_min_y = math.huge
    local min_center_y = math.huge
    for _,n in ipairs(c.nodes) do
      max_max_y = math.max(n.component_info.max_y, max_max_y)
      max_center_y = math.max(n.component_info.center_y, max_center_y)
      min_min_y = math.min(n.component_info.min_y, min_min_y)
      min_center_y = math.min(n.component_info.center_y, min_center_y)
    end
    
    local valign = graph:getOption('/graph drawing/component align')
    local line
    if valign == "counterclockwise bounding box" then
      line = max_max_y
    elseif valign == "counterclockwise" then
      line = max_center_y
    elseif valign == "center" then
      line = (max_max_y + min_min_y) / 2
    elseif valign == "clockwise" then
      line = min_center_y
    elseif valign == "first node" then
      line = c.nodes[1].component_info.center_y
    else 
      line = min_min_y
    end

    for _,n in ipairs(c.nodes) do
      if n:getOption('/graph drawing/align here') then
	line = n.component_info.center_y
	break
      end
    end
    
    y_shifts[i] = -line

    -- Adjust nodes:
    for _,n in ipairs(c.nodes) do
      local bb = n.component_info
      bb.min_y = bb.min_y - line
      bb.max_y = bb.max_y - line
      bb.center_y = bb.center_y - line
      n.component_info = bb
    end
  end

  -- Step 3: Horizontal alignment
  local y_values = {}

  for _,c in ipairs(components) do
    for _,n in ipairs(c.nodes) do
      y_values[#y_values+1] = n.component_info.min_y
      y_values[#y_values+1] = n.component_info.max_y
      y_values[#y_values+1] = n.component_info.center_y
    end
  end
  
  table.sort(y_values)
  
  local y_ranks = {}
  local right_face = {}
  for i=1,#y_values do
    y_ranks[y_values[i]] = i
    right_face[i] = -math.huge
  end
  
  for i=1,#components-1 do
    -- First, update right_face:
    local touched = {}
    for _,n in ipairs(components[i].nodes) do
      local bb = n.component_info
      local border = bb.max_x

      for i=y_ranks[bb.min_y],y_ranks[bb.max_y] do
	touched[i] = true
	right_face[i] = math.max(right_face[i], border)
      end
    end
    
    -- Fill up the untouched entries:
    local last_touched
    for i=1,#y_values do
      if touched[i] then
	last_touched = i
	break
      end
    end
    for j=1,#y_values do
      if not touched[j] then
	right_face[j] = math.max(right_face[j],right_face[last_touched])
      else
	last_touched = j
      end
    end
    

    -- Second, compute the left face
    local touched = {}
    local left_face = {}
    for i=1,#y_values do
      left_face[i] = math.huge
    end
    for _,n in ipairs(components[i+1].nodes) do
      local bb = n.component_info
      local border = bb.min_x

      for i=y_ranks[bb.min_y],y_ranks[bb.max_y] do
	touched[i] = true
	left_face[i] = math.min(left_face[i], border)
      end
    end
    
    -- Fill up the untouched entries:
    local last_touched
    for i=1,#y_values do
      if touched[i] then
	last_touched = i
	break
      end
    end
    for j=1,#y_values do
      if not touched[j] then
	left_face[j] = math.min(left_face[j],left_face[last_touched])
      else
	last_touched = j
      end
    end

    -- Now, compute the shift.
    local shift = -math.huge

    for i=1,#y_values do
      shift = math.max(shift, right_face[i] - left_face[i])
    end
    
    -- Adjust nodes:
    x_shifts[i+1] = shift
    for _,n in ipairs(components[i+1].nodes) do
      local bb = n.component_info
      bb.min_x = bb.min_x + shift
      bb.max_x = bb.max_x + shift
      bb.center_x = bb.center_x + shift
      n.component_info = bb
    end
  end
  
  -- Now, rotate shifts
  for i,c in ipairs(components) do
    local x =  x_shifts[i]*math.cos(-angle) + y_shifts[i]*math.sin(-angle)
    local y = -x_shifts[i]*math.sin(-angle) + y_shifts[i]*math.cos(-angle)
    
    for _,n in ipairs(c.nodes) do
      n.pos:set{x = n.pos:x() + x, y = n.pos:y() + y}
    end
    for _,edge in ipairs(c.edges) do
      for _,point in ipairs(edge.bend_points) do
	point:set{x = point:x() + x, y = point:y() + y}
      end
    end
  end
end
