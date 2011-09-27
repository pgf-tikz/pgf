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
    subparticles = {},
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
    center_of_mass = nil,
    mass = 0,
  }
  setmetatable(cell, CubicalCell)
  return cell
end



function CubicalCell:containsParticle(particle)
  return particle.pos:x() >= self.x and particle.pos:x() <= self.x + self.width
     and particle.pos:y() >= self.y and particle.pos:y() <= self.y + self.height
end



function CubicalCell:findSubcell(particle)
  return table.find(self.subcells, function (cell)
    return cell:containsParticle(particle)
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
    -- we already have a particle at the same position; splitting the cell
    -- up makes no sense; instead we add the new particle as a
    -- subparticle of the existing one
    table.insert(existing.subparticles, particle)
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
  self:updateCenterOfMass()
end



function CubicalCell:updateMass()
  -- reset mass to zero
  self.mass = 0

  if #self.subcells == 0 then
    -- the mass is the number of particles of the cell
    self.mass = table.combine_values(self.particles, function (mass, particle)
      local subparticle_masses = table.combine_values(particle.subparticles, function (mass, subparticle)
        return mass + subparticle.mass
      end, 0)
      return mass + particle.mass + subparticle_masses
    end, 0)
  else
    -- the mass is the sum of the masses of the subcells
    self.mass = table.combine_values(self.subcells, function (sum, cell)
      return sum + cell.mass
    end, 0)
  end
end



function CubicalCell:updateCenterOfMass()
  -- reset center of mass, assuming the cell is empty
  self.center_of_mass = nil

  if #self.subcells == 0 then
    -- the center of mass is the average position of the particles
    -- weighted by their masses
    self.center_of_mass = table.combine_values(self.particles, function (pos, particle)
      for subparticle in table.value_iter(particle.subparticles) do
        pos = pos:plus(subparticle.pos:timesScalar(subparticle.mass))
      end
      return pos:plus(particle.pos:timesScalar(particle.mass))
    end, Vector:new(2, function (n) return 0 end))
    self.center_of_mass = self.center_of_mass:dividedByScalar(self.mass)
  else
    -- the center of mass is the average of the weighted centers of mass 
    -- of the subcells
    self.center_of_mass = table.combine_values(self.subcells, function (pos, cell)
      if cell.center_of_mass then
        return pos:plus(cell.center_of_mass:timesScalar(cell.mass))
      else
        assert(cell.mass == 0)
        return pos:copy()
      end
    end, Vector:new(2, function (n) return 0 end))
    self.center_of_mass = self.center_of_mass:dividedByScalar(self.mass)
  end
end



function CubicalCell:findInteractionCells(particle, test_func, cells)
  -- FIXME TODO We also need to return leaf cells here, otherwise the forces
  -- are not computed correctly!!!

  if #self.subcells == 0 or test_func(self, particle) then
    table.insert(cells, self)
  else
    for subcell in table.value_iter(self.subcells) do
      if subcell.mass > 0 and subcell.center_of_mass then
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
      .. (self.center_of_mass and ' mass ' .. self.mass .. ' at ' .. tostring(self.center_of_mass) or '')
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
