-------------------------------------------------------------------------------
-- LuaDoc main function.
-- @release $Id$
-------------------------------------------------------------------------------

local require = require

local util = require "luadoc.util"

logger = {}

module ("luadoc")

-------------------------------------------------------------------------------
-- LuaDoc version number.

_COPYRIGHT = "Copyright (c) 2003-2007 The Kepler Project"
_DESCRIPTION = "Documentation Generator Tool for the Lua language"
_VERSION = "LuaDoc 3.0.1"

-------------------------------------------------------------------------------
-- Main function
-- @see luadoc.doclet.html, luadoc.doclet.formatter, luadoc.doclet.raw
-- @see luadoc.taglet.standard

function main (files)
  local options = require "luadoc.config"

  logger = util.loadlogengine(options)
  
  local taglet = require(options.taglet)
  local doclet = require(options.doclet)
  
  -- analyze input
  taglet.options = options
  taglet.logger = logger
  local doc = taglet.start(files)
  
  -- generate output
  doclet.options = options
  doclet.logger = logger
  doclet.start(doc)
end
