-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



---
-- This class provides the core functionality of the interface between
-- all the different layers (display layer, binding layer, and
-- algorithm layer). The two classes |InterfaceToAlgorithms| and
-- |InterfaceToDisplay| use, in particular, the data structures
-- provided by this class.
--
-- @field binding This field stores the ``binding.'' The graph drawing
-- system is ``bound'' to the display layer through such a binding (a
-- subclass of |Binding|). Such a binding can be thought of as a
-- ``driver'' in operating systems terminology: It is a small set of
-- functions needed to adapt the functionality to one specific display
-- system. Note that the whole graph drawing scope is bound to exactly
-- one display layer; to use several bindings you need to setup a
-- completely new Lua instance.
--
-- @field scopes This is a stack of graph drawing scopes. All
-- interface methods refer to the top of this stack. 
--
-- @field collection_kinds This table stores which collection kinds
-- have been defined together with their properties.
--
-- @field algorithm_classes A table that maps algorithm keys (like
-- |tree layout| to class objects).
--
-- @field keys A lookup table of all declared keys. Each entry of this
-- table consists of the original entry passed to the |declare|
-- method. Each of these tables is both index at a number (so you can
-- iterate over it using |ipairs|) and also via the key's name.

local InterfaceCore = {
  -- The main binding. Set by |InterfaceToDisplay.bind| method.
  binding             = nil,

  -- The stack of Scope objects.
  scopes              = {},

  -- The collection kinds.
  collection_kinds    = {},

  -- The algorithm classes
  algorithm_classes   = {},

  -- The declared keys
  keys                = {},

  -- Internals for handling the options stack
  option_stack        = {},
  option_cache_height = nil,
  option_initial      = {
    algorithm_phases = {}
  },

  -- Constant strings for special collection kinds.
  sublayout_kind      = "INTERNAL_sublayout_kind",
  subgraph_node_kind  = "INTERNAL_subgraph_node_kind",
}

-- Namespace
require("pgf.gd.interface").InterfaceCore = InterfaceCore


InterfaceCore.option_initial.__index = InterfaceCore.option_initial
InterfaceCore.option_initial.algorithm_phases.__index = InterfaceCore.option_initial.algorithm_phases



--- Returns the top scope
--
-- @return The current top scope, which is the scope in which
--         everything should happen right now.

function InterfaceCore.topScope()
  return assert(InterfaceCore.scopes[#InterfaceCore.scopes], "no graph drawing scope open")
end




-- Done 

return InterfaceCore