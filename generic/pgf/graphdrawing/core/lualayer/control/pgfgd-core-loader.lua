-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$

-- This file is the main entry point from the TeX part of the
-- library.  It defines a module system, which is used in all other Lua
-- sources, prepares the pgf namespace and loads registered files at
-- startup.
--
-- Every other file using the module system has a call to pgf.module as
-- first statement.  This also sets up the various metatables for symbol
-- lookup.
--
-- As stated later, logical parent namespaces aren't imported
-- automatically, so have to be imported manually using pgf.import.


local preload_these_files = {
  "module",
  "table",
  "stack",
  "iter",
  "string",
  "sys",
  "vector",
  "quadtree",
  "node",
  "edge",
  "cluster",
  "graph",
  "manipulation",
  "depth-first-search",
  "traversal",
  "fibonacci-heap",
  "priority-queue",
  "algorithms",
  "coarsen-graph",
  "component-packing",
  "tex-interface",
  "orientation",
  "positioning-helpers",
  "ranking",
  "network-simplex",
  "anchoring",
  "component-decomposition",
  "pipeline",
  "spanning-tree",
  "spacing",
  "growth-adjust",
  "event-handling",
}






--- Creates a function to be used as the __tostring() method of a module.
--
local function moduleToString(name)
  return function(module)
    local meta = getmetatable(module)
    local tmp = meta.__tostring
    meta.__tostring = nil
    local result = "<module '" .. name .. "', " .. tostring(module) .. ">"
    meta.__tostring = tmp
    return result
   end
end



--- Prepares the current environment to use the module '_M'.
--
-- @param level Used for setfenv to assign the environment at the appropriate level.
--
local function setupEnvironment(_M, level)
  assert(_M and level)
  local privateEnvironment = {}
  local privateMetatable = {}
  
  local meta = getmetatable(_M)
  
  -- we need an order in the packages, so numerically
  meta.importedPackages = meta.importedPackages or {}
  
  -- (old) values are retrieved (in order) from the imported packages,
  -- _M or the global environment _G
  privateMetatable.__index = function(table, k)
    if _M[k] ~= nil then
      return _M[k]
    end
    for _, name in ipairs(meta.importedPackages) do
      local result = package.loaded[name][k]
      if result ~= nil then
        return result
      end
    end
    local meta = getmetatable(_M)
    if meta.globalVisible then
      return _G[k]
    else
      return nil
    end
  end

  -- new values are stored in the _M module
  privateMetatable.__newindex = _M
  
  setmetatable(privateEnvironment, privateMetatable)
  setfenv(level, privateEnvironment)
end



--- Ensures that a module with the given name exists.
--
-- Although two additional parameters are implemented, they aren't available via
-- the pgf.module function.
--
-- @param assignGlobal  The module is assigned in the parent or global namespace; 
--                      the default is true.
-- @param globalVisible If true, the variable lookup includes the global namespace; 
--                      the default is true.
--
local function ensureModule(name, assignGlobal, globalVisible)
  if assignGlobal == nil then
    assignGlobal = true
  end
  if globalVisible == nil then
    globalVisible = true
  end
  
  local _M = package.loaded[name]
  if not _M then
    -- create the module with the given name
    _M = {}
    local meta = {}
    meta.__tostring = moduleToString(name)
    meta.globalVisible = globalVisible
    setmetatable(_M, meta)
    package.loaded[name] = _M
  end
  if assignGlobal then
    local fragments = {}
    -- TODO: switch direction of parsing ... insert 1 -> n
    string.gsub(name, "[^%.]+",
    function(atom)
      table.insert(fragments, 1, atom)
    end)
    local remove = table.remove
    local table = _G
    local i = #fragments
    while i > 1 do
      local fragment = fragments[i]
      table = rawget(table, fragment)
      if not table then
        error("GD:LOADER: unknown name " .. tostring(fragment))
      end
      i = i - 1
    end
    rawset(table, fragments[1], _M)
  end
  return _M
end



--- Enables the module for the current context.
--
-- @see ensureModule
--
local function module(name, level)
  -- level or one above this function
  level = level or 2
  local _M = ensureModule(name)
  setupEnvironment(_M, level + 1)
end



--- Dynamically imports the package 'name' into the package 'package'.
local function dynamicImport(_M, name)
  local package = package.loaded[name]
  if not package then
    error("GD:LOADER: unknown package " .. tostring(name))
  end
  -- if already imported, skip
  local meta = getmetatable(_M)
  for _, importedName in ipairs(meta.importedPackages) do
    if name == importedName then
      return
    end
  end

  -- lookup here first, packages are prepended to load order
  table.insert(meta.importedPackages, 1, name)
end



--- Statically imports the package 'name' into the package 'package'.
--
local function staticImport(_M, name)
  local package = package.loaded[name]
  if not package then
    error("GD:LOADER: unknown package " .. tostring(name))
  end
  for k, v in pairs(package) do
    _M[k] = v
  end
end



--- Returns the current module on the given level.
--
local function getCurrentModule(level)
  level = level or 2
  return getmetatable(getfenv(level)).__newindex
end



--- Converts all dynamic imports into static ones.
--
local function statifyImports()
  local _M = getCurrentModule(3)
  local meta = getmetatable(_M)
  for _, name in ipairs(meta.importedPackages) do
    staticImport(_M, name)
  end
  meta.importedPackages = {}
end



--- Use either resolvers or kpse to locate files.
--
local function find_file(filename, format)
  if resolvers then
    return resolvers.find_file(filename, format)
  else
    return kpse.find_file(filename, format)
  end
end   



--- Loads a file using the given patterns.
--
local function load(filename, format, prefix, suffix)
  filename = prefix and prefix .. filename or filename
  filename = suffix and filename .. suffix or filename
  local path = find_file(filename, format)
  if path then
    return dofile(path)
  else
    error("GD:LOADER: didn't find file " .. filename)
  end
end



local prefix = "pgfgd-core-"
local suffix = ".lua"
local format = "tex"




ensureModule("pgf")



--- Caches files loaded manually by the user.
--
-- @see userLoad
--
local userLoaded = {}



--- Small wrapper around find_file. 
--
-- Remembers if files were loaded; use the third parameter to force reloading.
--
local function userLoad(filename, format, reload)
  if userLoaded[filename] == true and not reload then
    -- file is already loaded, skip it
    return
  end
  local path = find_file(filename, format)
  if path and path:len() > 0 then
    userLoaded[filename] = true
    -- load the file
    return dofile(path)
  else
    error('GD:LOADER: could not find the file ' .. filename)
  end
end



pgf.debug = debug
pgf.module = module
pgf.getCurrentModule = getCurrentModule
pgf.statifyImports = statifyImports
pgf.import = function(name, static)
  local _M = getCurrentModule(3)
  if static then
    staticImport(_M, name)
  else
    dynamicImport(_M, name)
  end
end
pgf.load = userLoad



-- load the Lua core files of the graph drawing library
for _, file in ipairs(preload_these_files) do
  load(file, format, prefix, suffix)
end



-- Helping functions for declaring a graph drawing class
function graph_drawing_algorithm(info)

  pgf.module("pgf.graphdrawing", 3)

  local _M = getfenv(2)

  local class = info.properties or {}

  _M[info.name] = class
  _M[info.name].__index = class

  _M[info.name].new = 
    function (self, g, algo) 

      -- Create new object
      local obj = { graph = g, parent_algorithm = algo }
      setmetatable(obj, class)

      -- Setup graph_options
      for k,v in pairs(info.graph_parameters or {}) do
	if type(v) == "table" then
	  obj[k] = v[2](g:getOption('/graph drawing/' .. v[1]))
	else
	  obj[k] = g:getOption('/graph drawing/' .. v)
	end
      end

      return obj
    end
end


function toboolean(string)
  return string == "true"
end