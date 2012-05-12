-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Import
local layered = require "pgf.gd.layered"
local LayoutPipeline = require "pgf.gd.control.LayoutPipeline"

--- A not-quite trivial implementation of a Huffman tree. Each node
--- must have a field "probability" set. They will be connected
--- according to the Huffman method. No attempt is made at creating a
--- good positioning of the tree nodes in this simple example.

local SimpleHuffman = pgf.gd.new_algorithm_class {
  properties = {
    growth_direction = 90
  }
}

function SimpleHuffman:run()
  -- Construct a Huffman tree on top of the vertices...

  -- Shorthand
  local function prop (v) return v.storage[self].prop or v.options['/graph drawing/probability'] end
  
  -- Copy the vertex table, since we are going to modify it:
  local vertices = {}
  for i,v in ipairs(self.ugraph.vertices) do
    vertices[i] = v
  end
  
  -- Now, arrange the nodes in a line:
  vertices [1].pos.x = 0
  vertices [1].storage[self].layer = #vertices
  for i=2,#vertices do
    local d = layered.ideal_sibling_distance(self, self.ugraph, vertices[i-1], vertices[i])
    vertices [i].pos.x = vertices[i-1].pos.x + d
    vertices [i].storage[self].layer = #vertices
  end
  
  -- Now, do the Huffman thing...
  while #vertices > 1 do
    -- Find two minimum probabilities
    local min1, min2

    for i=1,#vertices do
      if not min1 or prop(vertices[i]) < prop(vertices[min1]) then
	min2 = min1
	min1 = i
      elseif not min2 or prop(vertices[i]) < prop(vertices[min2]) then
	min2 = i
      end
    end

    -- Create new node:
    local p = prop(vertices[min1]) + prop(vertices[min2])
    local v = LayoutPipeline.generateNode(self, { generated_options = {"HuffmanNode"}})
    v.storage[self].prop = p
    v.storage[self].layer = #vertices-1
    v.pos.x = (vertices[min1].pos.x + vertices[min2].pos.x)/2
    vertices[#vertices + 1] = v
    
    LayoutPipeline.generateEdge (self, v, vertices[min1],
				 {generated_options = {HuffmanLabel = "0"}})
    LayoutPipeline.generateEdge (self, v, vertices[min2],
				 {generated_options = {HuffmanLabel = "1"}})

    table.remove(vertices, math.max(min1, min2))
    table.remove(vertices, math.min(min1, min2))
  end
  
  layered.arrange_layers_by_baselines(self, self.ugraph)
end

return SimpleHuffman