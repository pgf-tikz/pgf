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
-- A storage is an object that, as the name suggests, allows you to
-- ``store stuff concerning objects.'' Basically, it behaves like
-- table having weak keys, which means that once the objects for which
-- you ``store stuff'' go out of scope, they are also removed from the
-- storage. Also, you can specify that for each object of the storage
-- you store a table. In this case, there is no need to initialize
-- this table for each object; rather, when you write into such a
-- table and it does not yet exist, it is created ``on the fly''. 
--
-- The typical way you use storages is best explained with the
-- following example: Suppose you want to write a depth-first search
-- algorithm for a graph. This algorithm might wish to mark all nodes
-- it has visisted. It could just say |v.marked = true|, but this might
-- clash with someone else also using the |marked| key. The solution is
-- to create a |marked| storage. The algorithm can first say
--\begin{codeexample}[code only, tikz syntax=false]
--local marked = Storage.new()
--\end{codeexample}
-- and then say
--\begin{codeexample}[code only, tikz syntax=false]
--marked[v] = true
--\end{codeexample}
-- to mark its objects. The |marked| storage object does not need to
-- be created locally inside a function, you can declare it as a local
-- variable of the whole file; nevertheless, the entries for vertices
-- no longer in use get removed automatically. You can also make it a
-- member variable of the algorithm class, which allows you make the
-- information about which objects are marked globally
-- accessible. 
--
-- Now suppose the algorithm would like to store even more stuff in
-- the storage. For this, we might use a table and can use the fact
-- that a storage will automatically create a table when necessary:
--\begin{codeexample}[code only, tikz syntax=false]
--local info = Storage.newTableStorage() 
--
--info[v].marked = true  -- the "info[v]" table is
--                       -- created automatically here
--
--info[v].foo    = "bar"
--\end{codeexample}
-- Again, once |v| goes out of scope, both it and the info table will
-- removed.

local Storage = {}

-- Namespace
require("pgf.gd.lib").Storage = Storage


-- The simple metatable

local SimpleStorageMetaTable = { __mode = "k" }

-- The adcanved metatable for table storages:

local TableStorageMetaTable = {
  __mode = "k",
  __index =
    function(t, k)
      local new = {}
      rawset(t, k, new)
      return new
    end
}


---
-- Create a new storage object.
--
-- @return A new |Storage| instance.

function Storage.new()
  return setmetatable({}, SimpleStorageMetaTable)
end


---
-- Create a new storage object which will install a table for every
-- entry automatilly.
--
-- @return A new |Storage| instance.

function Storage.newTableStorage()
  return setmetatable({}, TableStorageMetaTable)
end







-- Done

return Storage
