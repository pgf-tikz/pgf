-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$



---
-- This table provides two utility functions for managing ``lookup
-- tables.'' Such a table is a mixture of an array and a hashtable:
-- It stores (only) tables. Each table is stored once in a normal
-- array position. Additionally, the lookup table is also indexed at
-- the position of the table (used as a key) and this position is set
-- to |true|. This means that you can test whether a table |t| is in the
-- lookup table |l| simply by testing whether |l[t]| is true.
local LookupTable = {}

-- Namespace
require("pgf.gd.lib").LookupTable = LookupTable



---
-- Add tables to a lookup table
--
-- This operation takes time $O(|\verb!array!|)$.
--
-- @param l Lookup table
-- @param array An array of to-be-added tables.

function LookupTable.add(l, array)
  for i=1,#array do
    local t = array[i]
    if not l[t] then
      l[t] = true
      l[#l + 1] = t
    end
  end
end


---
-- Remove tables from a lookup table.
--
-- Note that this operation is pretty expensive insofar as it will
-- always cost a traversal of the whole lookup table. However, this is
-- also the maximum cost, even when a lot of entries need to be
-- deleted. Thus, it is much better to ``pool'' multiple remove
-- operations in a single one.
--
-- This operation takes time $O(\max\{|\verb!array!|, |\verb!l!|\})$.
--
-- @param l Lookup table
-- @param t An array of to-be-removed tables.

function LookupTable.remove(l, array)
  -- Step 1: Mark all to-be-deleted entries
  for i=1,#array do
    local t = array[i]
    if l[t] then
      l[t] = false
    end
  end

  -- Step 2: Collect garbage...
  local target = 1
  for i=1,#l do
    local t = l[i]
    if l[t] == false then
      l[t] = nil
    elseif target < i then
      l[target] = t
      target = target + 1
    end
  end
  for i=#l,target,-1 do
    l[i] = nil
  end
end



-- Done

return LookupTable