local PhylogeneticTree = pgf.gd.new_algorithm_class {
  properties = {},
  growth_direction = 90,
}

require("pgf.gd.trees").PhylogeneticTree = PhylogeneticTree

local UPGMA = require "pgf.gd.trees.UPGMA1958"
local BME = require "pgf.gd.trees.BalancedMinimumEvolution2002"
local Maeusle2012 = require "pgf.gd.trees.Maeusle2012"

---
-- The edge length between two vertices should be stored in vertex.storage.length[vertex2]
--

--- Computes a phylogenetic tree and/or visualizes it
--	- computes a phylogenetic tree according to what the "phylogenetic algorithm" key is set to
--	- invokes a graph drawing algorithm according to what the "phylogenetic layout" key is set to
--	@return The complete phylogenetic tree
function PhylogeneticTree:run()
  local g = self.digraph
  -- get the distance scaling factor
  g.storage.factor = g.options['/graph drawing/distance scaling factor'] 

  -- get phylogenetic algorithm from user input
  local p_a = g.options['/graph drawing/phylogenetic algorithm']
  -- run BME
  if (p_a == 'BME' or p_a == 'bme' or
      p_a == 'balanced minimum evolution' or
      p_a == 'Balanced Minimum Evolution' or
      p_a == 'BME without BNNI') then
  	g.storage.bme = true
    BME:run(self)
  -- run UPGMA
  elseif (p_a == 'UPGMA' or
          p_a == 'upgma') then
		g.storage.upgma = true
    UPGMA:run(self)
  elseif (not p_a or p_a == 'none') then
    -- tree topology must be specified by the user
  else
    assert(false, "Phylogenetic algorithm does not exist.")
	end

  -- get graph drawing options from user input
  g.storage.layout = g.options['/graph drawing/phylogenetic layout']
  local layout = g.storage.layout

  -- run phylogenetic graph drawing algorithm: Maeusle2012
  if (layout == 'rectangular phylogram' or
      layout == 'rooted rectangular phylogram' or
      layout == 'rooted straight phylogram' or
      layout == 'straight phylogram' or
      layout == 'unrooted rectangular phylogram' or
      layout == 'unrooted straight phylogram') then
    Maeusle2012:run(self)
  else
    assert(false, "No layout specified.")
  end
end

return PhylogeneticTree
