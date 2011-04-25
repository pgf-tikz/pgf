-- Copyright 2011 by Christophe Jorssen
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License.
--
-- See the file doc/generic/pgf/licenses/LICENSE for more details.

module("pgfluamath.functions", package.seeall)

function round(x)
  if x<0 then
    return -math.ceil(math.abs(x)) 
  else 
    return math.ceil(x) 
  end
end