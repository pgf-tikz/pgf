-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare

-- The algorithm class
local Tantau2012 = {}

---
declare {
  key       = "simple necklace layout",
  algorithm = Tantau2012,
  
  postconditions = {
    upward_oriented = true
  },

  summary = [["
      This simple layout arranges the nodes in a circle, which is especially 
      useful for drawing, well, circles of nodes.
      "]],
  
  documentation = [["
     The name
     |simple necklace layout| is reminiscent of the more general
     ``necklace layout,'' a term coined by Speckmann and Verbeek in
     their paper
     \begin{itemize}
     \item
       Bettina Speckmann and Kevin Verbeek,
       \newblock Necklace Maps,
       \newblock \emph{?,}
       ?, 2010.
     \end{itemize}
    
     For a |simple necklace layout|, the centers of the nodes
     are placed on a counter-clockwise circle, starting with the first
     node at the |grow| direction (for |grow'|, the circle is
     clockwise). The order of the nodes is the order in which they appear
     in the graph, the edges are not taken into consideration, unless the
     |componentwise| option is given.
    
\begin{codeexample}[]
\tikz[>=spaced stealth']
  \graph [simple necklace layout, grow'=down, node sep=1em,
          nodes={draw,circle}, math nodes]
  {
    x_1 -> x_2 -> x_3 -> x_4 ->
    x_5 -> "\dots"[draw=none] -> "x_{n-1}" -> x_n -> x_1
  };    
\end{codeexample}
     
     When you give the |componentwise| option, the graph will be
     decomposed into connected components, which are then laid out
     individually and packed using the usual component packing
     mechanisms:
    
\begin{codeexample}[]
\tikz \graph [simple necklace layout] {
  a -- b -- c -- d -- a,
  1 -- 2 -- 3 -- 1
};    
\end{codeexample}
\begin{codeexample}[]
\tikz \graph [simple necklace layout, componentwise] {
  a -- b -- c -- d -- a,
  1 -- 2 -- 3 -- 1
};    
\end{codeexample}
    
     The nodes are placed in such a way that
     \begin{enumerate}
     \item The (angular) distance between the centers of consecutive
       nodes is at least  |node distance|,
     \item the distance between the borders of consecutive nodes is at
       least |node sep|, and
     \item the radius is at least |radius|.
     \end{enumerate}
     The radius of the circle is chosen near-minimal such that the above
     properties are satisfied. To be more precise, if all nodes are
     circles, the radius is chosen optimally while for, say, rectangular
     nodes there may be too much space between the nodes in order to
     satisfy the second condition.
   "]],

   examples = {
     [["
     \tikz \graph [simple necklace layout,
                   node sep=0pt, node distance=0pt,
                   nodes={draw,circle}]
       { 1 -- 2 [minimum size=30pt] -- 3 --
         4 [minimum size=50pt] -- 5 [minimum size=40pt] -- 6 -- 7 };
     "]],
     [[" 
     \begin{tikzpicture}[radius=1.25cm]
       \graph [simple necklace layout,
               node sep=0pt, node distance=0pt,
               nodes={draw,circle}]
       { 1 -- 2 [minimum size=30pt] -- 3 --
         4 [minimum size=50pt] -- 5 [minimum size=40pt] -- 6 -- 7 }; 
      
       \draw [red] (0,-1.25) circle [];
     \end{tikzpicture}
     "]],
     [[" 
     \tikz \graph [simple necklace layout,
         node sep=0pt, node distance=1cm,
         nodes={draw,circle}]
       { 1 -- 2 [minimum size=30pt] -- 3 --
         4 [minimum size=50pt] -- 5 [minimum size=40pt] -- 6 -- 7 }; 
     "]],
     [[" 
     \tikz \graph [simple necklace layout,
         node sep=2pt, node distance=0pt,
         nodes={draw,circle}]
       { 1 -- 2 [minimum size=30pt] -- 3 --
         4 [minimum size=50pt] -- 5 [minimum size=40pt] -- 6 -- 7 }; 
     "]],
     [[" 
     \tikz \graph [simple necklace layout,
         node sep=0pt, node distance=0pt,
         nodes={rectangle,draw}]
       { 1 -- 2 [minimum size=30pt] -- 3 --
         4 [minimum size=50pt] -- 5 [minimum size=40pt] -- 6 -- 7 }; 
    "]]      
  } 
}



-- Imports

local Coordinate = require "pgf.gd.model.Coordinate"

local lib = require "pgf.gd.lib"


-- The implementation

function Tantau2012:run()
  local g = self.digraph
  local vertices = g.vertices
  local n = #vertices
  
  local sib_dists = self:computeNodeDistances ()
  local radii = self:computeNodeRadii()
  local diam, adjusted_radii = self:adjustNodeRadii(sib_dists, radii)

  -- Compute total necessary length. For this, iterate over all 
  -- consecutive pairs and keep track of the necessary space for 
  -- this node. We imagine the nodes to be aligned from left to 
  -- right in a line. 
  local carry = 0
  local positions = {}
  local function wrap(i) return (i-1)%n + 1 end
  local ideal_pos = 0
  for i = 1,n do
    positions[i] = ideal_pos + carry
    ideal_pos = ideal_pos + sib_dists[i]
    local node_sep =
      lib.lookup_option('node post sep', vertices[i], g) +
      lib.lookup_option('node pre sep', vertices[wrap(i+1)], g)
    local arc = node_sep + adjusted_radii[i] + adjusted_radii[wrap(i+1)] 
    local needed = carry + arc
    local dist = math.sin( arc/diam ) * diam
    needed = needed + math.max ((radii[i] + radii[wrap(i+1)]+node_sep)-dist, 0)
    carry = math.max(needed-sib_dists[i],0)    
  end
  local length = ideal_pos + carry

  local radius = length / (2 * math.pi)
  for i,vertex in ipairs(vertices) do
    vertex.pos.x = radius * math.cos(2 * math.pi * (positions[i] / length + 1/4))
    vertex.pos.y = -radius * math.sin(2 * math.pi * (positions[i] / length + 1/4))
  end
end


function Tantau2012:computeNodeDistances()
  local sib_dists = {}
  local sum_length = 0
  local vertices = self.digraph.vertices
  for i=1,#vertices do
    sib_dists[i] = lib.lookup_option('node distance', vertices[i], self.digraph)
    sum_length = sum_length + sib_dists[i]
  end

  local missing_length = self.digraph.options['radius'] * 2 * math.pi - sum_length
  if missing_length > 0 then
     -- Ok, the sib_dists to not add up to the desired minimum value. 
     -- What should we do? Hmm... We increase all by the missing amount:
     for i=1,#vertices do
	sib_dists[i] = sib_dists[i] + missing_length/#vertices
     end
  end

  sib_dists.total = math.max(self.digraph.options['radius'] * 2 * math.pi, sum_length)
  
  return sib_dists
end


function Tantau2012:computeNodeRadii()
  local radii = {}
  for i,v in ipairs(self.digraph.vertices) do
    local min_x, min_y, max_x, max_y = Coordinate.boundingBox(v.hull)
    local w, h = max_x-min_x, max_y-min_y
    if v.shape == "circle" or v.shape == "ellipse" then
      radii[i] = math.max(w,h)/2
    else
      radii[i] = math.sqrt(w*w + h*h)/2
    end
  end
  return radii
end


function Tantau2012:adjustNodeRadii(sib_dists,radii)
  local total = 0
  local max_rad = 0
  for i=1,#radii do
    total = total + 2*radii[i] 
            + lib.lookup_option('node post sep', self.digraph.vertices[i], self.digraph)
            + lib.lookup_option('node pre sep', self.digraph.vertices[i], self.digraph)
    max_rad = math.max(max_rad, radii[i])  
  end
  total = math.max(total, sib_dists.total, max_rad*math.pi)
  local diam = total/(math.pi)
  
  -- Now, adjust the radii:
  local adjusted_radii = {}
  for i=1,#radii do
    adjusted_radii[i] = (math.pi - 2*math.acos(radii[i]/diam))*diam/2
  end
  
  return diam, adjusted_radii
end


-- done

return Tantau2012