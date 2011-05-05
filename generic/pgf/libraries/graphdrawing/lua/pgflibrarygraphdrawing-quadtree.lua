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



Particle = {}
Particle.__index = Particle



--- Creates a new particle.
--
-- @return A newly-allocated particle.
--
function Particle:new(pos, mass)
  local particle = {
    pos = pos:copy(),
    mass = mass or 1,
    amount = 1,
  }
  setmetatable(particle, Particle)
  return particle
end



CubicalCell = {}
CubicalCell.__index = CubicalCell



--- Creates a new cubicle cell.
--
-- @return a newly-allocated cubicle cell.
--
function CubicalCell:new(x, y, width, height, max_particles)
  local cell = {
    x = x,
    y = y,
    width = width,
    height = height,
    max_particles = max_particles or 1,
    subcells = {},
    particles = {},
    centre_of_mass = nil,
    mass = 0,
  }
  setmetatable(cell, CubicalCell)
  return cell
end



function CubicalCell:findSubcell(particle)
  return table.find(self.subcells, function (cell)
    return particle.pos:x() >= cell.x and particle.pos:x() <= cell.x + cell.width
       and particle.pos:y() >= cell.y and particle.pos:y() <= cell.y + cell.height
  end)
end



function CubicalCell:createSubcells()
  assert(type(self.subcells) == 'table' and #self.subcells == 0)
  assert(type(self.particles) == 'table' and #self.particles <= self.max_particles)

  if #self.subcells == 0 then
    for x in table.value_iter({self.x, self.x + self.width/2}) do
      for y in table.value_iter({self.y, self.y + self.height/2}) do
        local cell = CubicalCell:new(x, y, self.width/2, self.height/2, self.max_particles)
        table.insert(self.subcells, cell)
      end
    end
  end
end



function CubicalCell:insert(particle)
  -- check if we have a particle with the exact same position already
  local existing = table.find(self.particles, function (other)
    return other.pos:equals(particle.pos)
  end)

  if existing then
    -- we already have a particle at the same position; spliting the cell
    -- up makes no sense; instead we increase the particle count to make
    -- it weigh stronger (and to to be able to compute the force to other
    -- particles as many times as necessary later)
    existing.amount = existing.amount + 1
  else
    if #self.subcells == 0 and #self.particles < self.max_particles then
      table.insert(self.particles, particle)
    else
      if #self.subcells == 0 then
        self:createSubcells()
      end
        
      --Sys:log(' ')
      --Sys:log('parent cell after creating subcells:')
      --self:dump('  ')
      --Sys:log(' ')

      -- move particles to the new subcells
      for existing in table.value_iter(self.particles) do
        local cell = self:findSubcell(existing)
        assert(cell, 'failed to find a cell for particle ' .. tostring(existing.pos))
        cell:insert(existing)
      end

      self.particles = {}

      local cell = self:findSubcell(particle)
      assert(cell)
      cell:insert(particle)
    end
  end

  self:updateMass()
  self:updateCentreOfMass()
end



function CubicalCell:updateMass()
  -- reset mass to zero
  self.mass = 0

  if #self.subcells == 0 then
    -- the mass is the number of particles of the cell
    self.mass = table.combine_values(self.particles, function (mass, particle)
      return mass + (particle.mass * particle.amount)
    end, 0)
  else
    -- the mass is the sum of the masses of the subcells
    self.mass = table.combine_values(self.subcells, function (sum, cell)
      return sum + cell.mass
    end, 0)
  end
end



function CubicalCell:updateCentreOfMass()
  -- reset centre of mass, assuming the cell is empty
  self.centre_of_mass = nil

  if #self.subcells == 0 then
    -- the centre of mass is the average position of the particles
    self.centre_of_mass = table.combine_values(self.particles, function (pos, particle)
      return pos:plus(particle.pos:timesScalar(particle.mass * particle.amount))
    end, Vector:new(2, function (n) return 0 end))
    self.centre_of_mass = self.centre_of_mass:dividedByScalar(self.mass)
  else
    -- the centre of mass is the average of the weighted centres of mass of the subcells
    self.centre_of_mass = table.combine_values(self.subcells, function (pos, cell)
      if cell.centre_of_mass then
        return pos:plus(cell.centre_of_mass:timesScalar(cell.mass))
      else
        assert(cell.mass == 0)
        return pos:copy()
      end
    end, Vector:new(2, function (n) return 0 end))
    self.centre_of_mass = self.centre_of_mass:dividedByScalar(self.mass)
  end
end



function CubicalCell:findInteractionCells(particle, test_func, cells)
  if test_func(self, particle) then
    table.insert(cells, self)
  else
    for subcell in table.value_iter(self.subcells) do
      if subcell.mass > 0 and subcell.centre_of_mass then
        subcell:findInteractionCells(particle, test_func, cells)
      end
    end
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
      .. (self.centre_of_mass and ' mass ' .. self.mass .. ' at ' .. tostring(self.centre_of_mass) or '')
end



QuadTree = {}
QuadTree.__index = QuadTree



--- Creates a new quad tree.
--
-- @return A newly-allocated quad tree.
--
function QuadTree:new(x, y, width, height, max_particles)
  local tree = {
    root_cell = CubicalCell:new(x, y, width, height, max_particles)
  }
  setmetatable(tree, QuadTree)
  return tree
end



function QuadTree:insert(particle)
  assert(particle.__index == Particle)

  self.root_cell:insert(particle)
end



function QuadTree:dump(indent)
  self.root_cell:dump(indent)
end



function QuadTree:findInteractionCells(particle, test_func, cells)
  local test_func = test_func or function (cell, particle) return true end
  cells = cells or {}

  self.root_cell:findInteractionCells(particle, test_func, cells)

  return cells
end
