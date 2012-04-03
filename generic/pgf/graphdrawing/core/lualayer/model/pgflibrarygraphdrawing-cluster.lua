-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

--- This file defines a simple interface for clustering nodes. Every cluster
--- constists of a set of nodes and may have options that determine how 
--- algorithms treat the cluster. A layered drawing algorithm, for instance,
--- could use a cluster property to place a cluster at the minimum or maximum
--- rank in the final drawing.

pgf.module('pgf.graphdrawing')



Cluster = {}
Cluster.__index = Cluster



--- TODO Jannis: Add documentation for this class.
--
function Cluster:new(name)
  local cluster = {
    name = name,
    nodes = {},
    contains_node = {},
    options = {},
  }
  setmetatable(cluster, Cluster)
  return cluster
end



function Cluster:getName()
  return self.name
end



function Cluster:addNode(node)
  if not self:findNode(node) then
    self.contains_node[node] = true
    table.insert(self.nodes, node)
  end
end



function Cluster:findNode(node)
  return self.contains_node[node]
end



function Cluster:setOption(name, value)
  self.options[name] = value
end



function Cluster:getOption(name)
  return self.options[name]
end
