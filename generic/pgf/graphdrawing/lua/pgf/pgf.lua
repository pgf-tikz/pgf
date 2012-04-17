-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$


-- Declare the pgf namespace:
-- (Skip, till old module stuff has been replaced)

-- pgf = {}



-- Declare a search function for pgf, which just substitutes dots by hyphens, because this
-- is more compatible with tex:

local function searcher_function(modulename)

  -- Find source
  local actual_modulename = string.gsub(modulename, "%.", "-")

  --- Use either resolvers or kpse to locate files.
  local filename
  if resolvers then
    filename = resolvers.find_file(actual_modulename .. ".lua", "tex")
  else
    filename = kpse.find_file(actual_modulename .. ".lua", "tex")
  end

  if filename and filename ~= "" then
    return function () return dofile(filename) end
  else
    return nil
  end
end


-- Install the loader so that it's called just before the normal Lua loader
if package.loaders then
  table.insert(package.loaders, 3, searcher_function)
else
  table.insert(package.searchers, 3, searcher_function)
end



return pgf