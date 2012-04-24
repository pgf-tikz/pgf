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
-- by default: s and t, which stand for source and target.
--
-- You may not create an arc by yourself, which is why there is no new
-- method, arc creation is done by the Digraph class.
--
-- You may read the s and t fields, but you may not write them. You
-- may, however, use any other field of the Arc's table. However,
-- algorithms typically should use private fields.
--
-- Every arc belongs to exactly one graph. If you want the same arc in
--another graph, you need to newly connect s and t in the other graph.

local Arc = {}
Arc.__index = Arc


-- Namespace

require("pgf.gd.model").Arc = Arc


-- Done

return Arc