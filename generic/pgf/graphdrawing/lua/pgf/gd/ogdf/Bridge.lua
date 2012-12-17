-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



local Bridge = {}


-- Namespace
require("pgf.gd.trees").Bridge = Bridge


-- Imports
local Coordinate = require "pgf.gd.model.Coordinate"


---
-- Prepares a graph for use in C. The native data structures used in
-- Lua to represent graphs are not ideally suited for use in C, so a
-- bit of simplification and adaption is done to facilitate the
-- interface between Lua and C. This function gets a |Digraph| object
-- as input and outputs a new table |t| that is understood by the
-- |AdaptorToPGF| C++ class for use in \textsc{ogdf}.
--
-- Let us start with the graph's |vertices| array. For this array, the
-- table |t| will contain an field |vertices_for_c| which is an array
-- of tables with the following fields:
--
-- \begin{itemize}
-- \item |vertex| A |Vertex| object.
-- \item |vertex_index| The index of the object in the graph's
-- |vertices| array.
-- \item |pos| The |vertex| object's |pos| (a |Coordinate|).
-- \item |width| The width of the vertex. In the graph drawing system,
-- we use a ``richer'' notion of node shape (we work with a whole
-- convex hull), while \textsc{ogdf} only uses |width| and |height|
-- fields. We do a best effort job to translate here.
-- \item |height| The vertex's height.
-- \item |shape| The vertex's shape.
-- \item |kind| The vertex's kind.
-- \item |weight| The value of the |weight| field of the |options| table.
-- \item |options_index| The index of the vertex's option table. See the
-- explanation on option tables later on.
-- \end{itemize}
--
-- The next array is the |syntactic_edges_for_c| array. As the name
-- suggests, it stores all syntatic edges of the graph in a manner
-- useful for C. Each entry is a table with the following fields:
--
-- \begin{itemize}
-- \item |syntatic_edge| The |Edge| object.
-- \item |syntatic_edge_index| The index of the |Edge| object inside
-- the |Arc|'s array of syntactic edges.
-- \item |arc| The |Arc| object (which contains the |Edge| object).
-- \item |arc_index| The index of the arc object in the graph's |arcs|
-- array. 
-- \item |tail_index| An index into the |vertices_for_c| array of the
-- edge's tail object.
-- \item |head_index| Similar, but for the head.
-- \item |path| The path array of the edge.
-- \item |direction| The edge's kind (one of the strings |"--"|, |"->"|,
-- |"<-"|, |"<->"|, |"-!-"|).
-- \item |weight| The value of the |weight| field of the |options| table.
-- \item |options_index| The index of the edge's option table. See
-- below.
-- \end{itemize}
--
-- The next field, |options_for_c|, is an array of options
-- tables. In Lua, the vertices and edges just store pointers to their
-- option tables and many vertices or edges can share the same
-- table. We also want these vertices and edges to share the
-- reflection of these tables in C, but for this we need to know which
-- tables are the same. This array provides this information by
-- storing each table just once.
--
-- The final fields of |t| are |syntactic_digraph|, which just stores
-- the |graph| object, and |options|, which stores the graph's options
-- table. 
--
-- @param graph The input graph.
-- @param algorithm Optionally, an algorithm object. If non |nil|, we
-- attempt to get the bounding box information of the vertices from
-- the storage object attached to the vertices (this is important only
-- for algorithms that draw layered graphs and wish to profit from the
-- automatic node rotation).
-- @return The table |t| as decribed above.

function Bridge.bridgeGraph(graph, algorithm)
  
  local vertices_for_c = {}
  local syntactic_edges_for_c = {}
  local options_for_c = {}
  
  -- Build options_for_c array:
  local function update(obj)
    local o = obj.options
    if not options_for_c[o] then
      options_for_c[#options_for_c + 1] = o
      options_for_c[o]                  = #options_for_c
    end
  end
    
  for _,v in ipairs(graph.vertices) do
    update(v)
  end

  for _,a in ipairs(graph.arcs) do
    for _,s in ipairs(a.syntactic_edges) do
      update(s)
    end
  end
  
  -- Build vertices_for_c array:
  local lookup = {}
  for i,v in ipairs(graph.vertices) do

    local min_x, min_y, max_x, max_y
    
    -- Construct bounding box:
    if not algorithm or not v.storage[algorithm].sibling_pre then
      min_x, min_y, max_x, max_y = Coordinate.boundingBox(v.hull)
    else
      local bb = v.storage[algorithm]
      min_x = bb.sibling_pre
      max_x = bb.sibling_post
      min_y = bb.layer_pre
      max_y = bb.layer_post
    end
    
    vertices_for_c[i] = {
      vertex        = v,
      vertex_index  = i,
      pos           = v.pos,
      shape         = v.shape,
      kind          = v.kind,
      width         = max_x - min_x,
      height        = max_y - min_y,
      weight        = v.options.weight,
      options_index = options_for_c[v.options],
    }

    lookup[v] = i
  end
  
  -- Build vertices_for_c array:
  local syntactic_digraph = graph.syntactic_digraph
  
  for ai,a in ipairs(graph.arcs) do
    local arc = syntactic_digraph:arc(a.tail, a.head)

    if arc then
      for si,s in ipairs(arc.syntactic_edges) do
	syntactic_edges_for_c[#syntactic_edges_for_c + 1] = {
	  syntactic_edge       = s,
	  syntactic_edge_index = si,
	  arc                  = a,
	  arc_index            = ai,
	  tail_index           = lookup[s.tail],
	  head_index           = lookup[s.head],
	  direction            = s.direction,
	  weight               = s.options.weight,
	  path                 = s.path,
	  options_index        = options_for_c[s.options]
	}
      end
    end
  end
  
  return {
    vertices_for_c        = vertices_for_c,
    syntactic_edges_for_c = syntactic_edges_for_c,
    options_for_c         = options_for_c,
    options               = graph.options,
    syntactic_digraph     = graph
  }
end



---
-- Update the data structure of a graph from values returned from C.
--
-- This method is called after \textsc{ogdf} has run an updated its C
-- data structures. The gathered information will then have
-- accumulated in a number of arrays, which are stored in the second
-- parameter and which are used to update the graph object.
--
-- The first three array fields are used to update the vertex array:
--
-- \begin{itemize}
-- \item |vertex_indices| Each entry stores the index of a
-- to-be-updated vertex in the |vertices| array.
-- \item |x| This array contains the computed $x$-coordinates of the
-- corresponding vertices.
-- \item |y| The array of |y| coordinates.
-- \end{itemize}
--
-- The next arrays are used to update the edges:
-- \begin{itemize}
-- \item |arc_indices| An array of the indices of the arc objects in
-- the graph's |arcs| array to which these entries refer.
-- \item |syntactic_edge_indices| The subentries in the arc object's
-- array of syntactic edges.
-- \item |bends| An array of ``path objects,'' which contain the edge
-- paths. Each entry of this array must either be a string object or a
-- table with the two fields |x| and |y| (but need not be a
-- |Coordinate| object, to make things a bit simpler for C). The array
-- will be copied.
-- \end{itemize}
--
-- Currently, this function will neither produce new edges nor new
-- vertices, but this will change.
--
-- @param graph The syntactic digraph that should be updated.
-- @param t The table that contains the above arrays as fields.

function Bridge.unbridgeGraph(graph, t)
  local x,y,syntactic_edge_indices,bends = t.x, t.y, t.syntactic_edge_indices,t.bends
  
  for i,index in ipairs(t.vertex_indices) do
    local p = graph.vertices[index].pos

    p.x = x[i]
    p.y = y[i]
  end
  
  local syntactic_digraph = graph.syntactic_digraph
  
  for i,ai in ipairs(t.arc_indices) do
    local a = graph.arcs[ai]
    local arc = syntactic_digraph:arc(a.tail, a.head)
    local e = arc.syntactic_edges[syntactic_edge_indices[i]]
    local b = {}
    for j,entry in  ipairs(bends[i]) do
      if type(entry) == "string" then
	b[j] = t
      else
	b[j] = Coordinate.new(entry.x - a.tail.pos.x, entry.y - a.tail.pos.y)
      end
    end
    e.path = b
  end
end


-- Done

return Bridge