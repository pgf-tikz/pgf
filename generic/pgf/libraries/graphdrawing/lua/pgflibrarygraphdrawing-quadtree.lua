-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file contains a class for defining arbitrary vectors and
--- perform operations on them.

pgf.module('pgf.graphdrawing')



CubicalCell = {}
CubicalCell.__index = CubicalCell



--- Creates a new cubicle cell.
--
-- @return a newly-allocated cubicle cell.
--
function CubicalCell:new(x, y, width, height)
  local cell = {
    x = x,
    y = y,
    width = width,
    height = height,
    subcells = {},
    particle = nil,
    centre_of_mass = nil,
  }
  setmetatable(cell, CubicalCell)
  return cell
end



function CubicalCell:findSubcell(node)
  return table.find(self.subcells, function (cell)
    return node.pos:x() >= cell.x and node.pos:x() <= cell.x + cell.width
       and node.pos:y() >= cell.y and node.pos:y() <= cell.y + cell.height
  end)
end



function CubicalCell:insert(node)
  if not self.particle and #self.subcells == 0 then
    self.particle = node
    self.centre_of_mass = self.particle.pos:copy()
  else
    -- create four subcells on demand
    if #self.subcells == 0 then
      for x in table.value_iter({self.x, self.x + self.width/2}) do
        for y in table.value_iter({self.y, self.y + self.height/2}) do
          local cell = CubicalCell:new(x, y, self.width/2, self.height/2)
          table.insert(self.subcells, cell)
        end
      end
    end

    -- we also need to move the particle to a subcell
    local nodes = { node, self.particle or nil }

    -- move both nodes into the correct subcells
    for node in table.value_iter(nodes) do
      -- find the cell to insert the node in
      local cell = self:findSubcell(node)
      
      -- there HAS to be one, otherwise there is a bug in either
      -- the initial position and size of the root cell or any
      -- of the subcells
      assert(cell)

      -- recursively insert the node into the subcell
      cell:insert(node)
    end

    -- drop the particle, it was moved to a subcell
    self.particle = nil
    
    -- recompute the centre of mass:
    
    -- first determine the cells with a centre of mass set
    local non_empty_cells = table.filter_values(self.subcells, function (cell)
      return cell.centre_of_mass
    end)

    -- compute the average position of all centres of mass
    self.centre_of_mass = table.combine_values(non_empty_cells, function (centre, cell)
      if cell.centre_of_mass then
        return centre:plus(cell.centre_of_mass)
      else
        return centre
      end
    end, Vector:new(2, function (n) return 0 end))
    self.centre_of_mass = self.centre_of_mass:dividedByScalar(#non_empty_cells)
  end
end



function CubicalCell:dump(indent)
  local indent = indent or ''
  Sys:log(indent .. tostring(self))
  for subcell in table.value_iter(self.subcells) do
    subcell:dump(indent .. '  ')
  end
end



function CubicalCell:__tostring()
  return '((' .. self.x .. ', ' .. self.y .. ') '
      .. 'to (' .. self.x + self.width .. ', ' .. self.y + self.height .. '))' 
      .. (self.particle and ' => ' .. self.particle.name or '')
      .. (self.centre_of_mass and ' mass ' .. tostring(self.centre_of_mass) or '')
end



QuadTree = {}
QuadTree.__index = QuadTree



--- Creates a new quad tree.
--
-- @return A newly-allocated quad tree.
--
function QuadTree:new(x, y, width, height)
  local tree = {
    root_cell = CubicalCell:new(x, y, width, height)
  }
  setmetatable(tree, QuadTree)
  return tree
end



function QuadTree:insert(node)
  self.root_cell:insert(node)
end



function QuadTree:dump(indent)
  self.root_cell:dump(indent)
end
