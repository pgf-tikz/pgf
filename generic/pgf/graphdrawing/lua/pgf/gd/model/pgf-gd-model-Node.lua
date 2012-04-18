-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$





--- The Node class ...
--
--

local Node = pgf.graphdrawing.Node
Node.__index = Node


-- Namespace

local model   = require "pgf.gd.model"
model.Node = Node



-- Done

return Node