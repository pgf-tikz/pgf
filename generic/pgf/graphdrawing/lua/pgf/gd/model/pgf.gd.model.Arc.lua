-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- The Arc class
--
-- An arc is an extremely light-weight object. It just has two fields,
-- by default: head and tail.
--
-- You may not create an arc by yourself, which is why there is no new
-- method, arc creation is done by the Digraph class.
--
-- You may read the head and tail fields, but you may not write them. You
-- may, however, use other field of the Arc's table. Algorithms are
-- kindly requested to use private fields.  
--
-- Every arc belongs to exactly one graph. If you want the same arc in
-- another graph, you need to newly connect s and t in the other graph.

local Arc = {}
Arc.__index = Arc


-- Namespace

require("pgf.gd.model").Arc = Arc



--- Returns a string representation of an arc. This is mainly for debugging
--
-- @return The Arc as string.
--
function Arc:__tostring()
  return tostring(self.tail) .. "->" .. tostring(self.head);
end


-- Done

return Arc