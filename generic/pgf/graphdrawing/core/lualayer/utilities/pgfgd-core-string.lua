-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file includes extensions to the standard string module.

pgf.module("pgf.graphdrawing")



--- Parses a string with |{key}{value}| pairs and returns a table
--- mapping the keys to the corresponding values.
--
-- @param str     The string to parse.
-- @param default Currently unused.
--
-- @return A table mapping the keys found in the string to their
--         values.
--
function string.parse_braces(str, default)
  local options = {}

  if str then
    local level = 0
    local key = nil
    local value = ''
    local in_key = false
    local in_value = false
    local skip_char = false

    for i = 1,str:len() do
      skip_char = false

      local char = string.sub(str, i, i)

      if char == '{' then
        if level == 0 then
          if not key then
            in_key = true
          else
            in_value = true
          end
          skip_char = true
        end
        level = level + 1
      elseif char == '}' then
        level = level - 1

        assert(level >= 0) -- otherwise there's a bug in the parsing algorithm

        if level == 0 then
          if in_key then
            in_key = false
          else 
            options[key] = value

            key = nil
            value = ''

            in_value = false
          end
          skip_char = true
        end
      end

      if not skip_char then
        if in_key then
          key = (key or '') .. char
        else
          value = (value or '') .. char
        end
      end

      assert(not (in_key and in_value))
    end
  end

  return options
end
