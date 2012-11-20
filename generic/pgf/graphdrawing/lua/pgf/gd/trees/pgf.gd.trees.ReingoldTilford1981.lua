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
-- @section subsubsection {The Reingold--Tilford Layout}
--
local ReingoldTilford1981 = {}

-- Imports
local layered = require "pgf.gd.layered"
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare



---
declare {
  key       = "tree layout",
  algorithm = ReingoldTilford1981,
  
  preconditions = {
    connected = true,
    tree      = true
  },

  postconditions = {
    upward_oriented = true
  },

  summary = [["
      This layout uses the Reingold--Tilform method for drawing trees. 
  "]],  
  documentation = [["
     The Reingold--Tilford method is a standard method for drawing
     trees. It is described in:
     \begin{itemize}
     \item
       E.~M.\ Reingold and J.~S.\ Tilford,
       \newblock Tidier drawings of trees,
       \newblock \emph{IEEE Transactions on Software Engineering,}
       7(2), 223--228, 1981.
     \end{itemize}
     My implementation in |graphdrawing.trees| follows the following paper, which
     introduces some nice extensions of the basic algorithm:
     \begin{itemize}
     \item
       A.\ Br\"uggemann-Klein, D.\ Wood,
       \newblock Drawing trees nicely with \TeX,
       \emph{Electronic Publishing,} 2(2), 101--115, 1989.
     \end{itemize}
     As a historical remark, Br\"uggemann-Klein and Wood have implemented
     their version of the Reingold--Tilford algorithm directly in \TeX\
     (resulting in the Tree\TeX\ style). With the power of Lua\TeX\ at
     our disposal, the 2012 implementation in the |graphdrawing.tree|
     library is somewhat more powerful and cleaner, but it really was an
     impressive achievement to implement this algorithm back in 1989
     directly in \TeX. 
    
     The basic idea of the Reingold--Tilford algorithm is to use the
     following rules to position the nodes of a tree (the following
     description assumes that the tree grows downwards, other growth
     directions are handled by the automatic orientation mechanisms of
     the graph drawing library): 
     \begin{enumerate}
     \item For a node, recursively compute a layout for each of its children.
     \item Place the tree rooted at the first child somewhere on the page.
     \item Place the tree rooted at the second child to the right of the
       first one as near as possible so that no two nodes touch (and such
       that the |sibling sep| padding is not violated).
     \item Repeat for all subsequent children.
     \item Then place the root above the child trees at the middle
       position, that is, at the half-way point between the left-most and
       the right-most child of the node.
     \end{enumerate}
     The standard keys |level distance|, |level sep|, |sibling distance|,
     and |sibling sep|, as well as the |pre| and |post| versions of these
     keys, as taken into consideration when nodes are positioned. See also
     Section~\ref{subsection-gd-dist-pad} for details on these keys. 
    
     \noindent\textbf{Handling of Missing Children.}
     As described in Section~\ref{section-gd-missing-children}, you can
     specify that some child nodes are ``missing'' in the tree, but some
     space should be reserved for them. This is exactly what happens:
     When the subtrees of the children of a node are arranged, each
     position with a missing child is treated as if a zero-width,
     zero-height subtree were present at that positions:
\begin{codeexample}[]
\tikz [tree layout, nodes={draw,circle}]
  \node {r}
    child { node {a}
      child [missing]
      child { node {b} }
    }
    child[missing];
\end{codeexample}
     or in |graph| syntax:
\begin{codeexample}[]
  \tikz \graph [tree layout, nodes={draw,circle}]
  {
    r -> {
      a -> {
        , %missing
        b},
      % missing
    }
  };
\end{codeexample}
     More than one child can go missing:
\begin{codeexample}[]
\tikz \graph [tree layout, nodes={draw,circle}, sibling sep=0pt]
  { r -> { a, , ,b -> {c,d}, ,e} };
\end{codeexample}
     Although missing children are taken into consideration for the
     computation of the placement of the children of a root node relative
     to one another and also for the computation of the position of the
     root node, they are usually \emph{not} considered as part of the
     ``outline'' of a subtree (the \texttt{minimum number of children}
     key ensures that |b|, |c|, |e|, and |f| all have a missing right
     child): 
\begin{codeexample}[]
\tikz \graph [tree layout, minimum number of children=2,
              nodes={draw,circle}]
  { a -> { b -> c -> d, e -> f -> g } };
\end{codeexample}
     This behaviour of ``ignoring'' missing children in later stages of
     the recursion can be changed using the key |missing nodes get space|. 
    
     \noindent\textbf{Significant Pairs of Siblings.}
     Br\"uggemann-Klein and Wood have proposed an extension of the
     Reingold--Tilford method that is intended to better highlight the
     overall structure of a tree. Consider the following two trees:
     
\begin{codeexample}[]
\tikz [baseline=(a.base), tree layout, minimum number of children=2,
       sibling distance=5mm, level distance=5mm]
  \graph [nodes={circle, inner sep=0pt, minimum size=2mm, fill, as=}]{
    a -- { b -- c -- { d -- e, f -- { g, h }}, i -- j -- k[second] }
  };\quad
\tikz [baseline=(a.base), tree layout, minimum number of children=2,
       sibling distance=5mm, level distance=5mm]
  \graph [nodes={circle, inner sep=0pt, minimum size=2mm, fill, as=}]{
    a -- { b -- c -- d -- e, i -- j -- { f -- {g,h}, k } }
  };
\end{codeexample}  
     As observed by Br\"uggemann-Klein and Wood, the two trees are
     structurally quite different, but the Reingold--Tilford method
     places the nodes at exactly the same positions and only one edge
     ``switches'' positions. In order to better highlight the differences
     between the trees, they propose to add a little extra separation
     between siblings that form a \emph{significant pair}. They define
     such a pair as follows: Consider the subtrees of two adjacent
     siblings. There will be one or more levels where these subtrees have
     a minimum distance. For instance, the following two trees the
     subtrees of the nodes |a| and |b| have a minimum distance only at
     the top level in the left example, and in all levels in the second
     example. A \emph{significant pair} is a pair of siblings where the
     minimum distance is encountered on any level other than the first
     level. Thus, in the first example there is no significant pair,
     while in the second example |a| and |b| form such a pair.
\begin{codeexample}[]
\tikz \graph [tree layout, minimum number of children=2,
               level distance=5mm, nodes={circle,draw}]
  { / -> { a -> / -> /, b -> /[second] -> /[second] }};
  \quad
\tikz \graph [tree layout, minimum number of children=2,
              level distance=5mm, nodes={circle,draw}]
  { / -> { a -> / -> /, b -> / -> / }};
\end{codeexample}
     Whenever the algorithm encounters a significant pair, it adds extra
     space between the siblings as specified by the |significant sep|
     key.
  "]],
  examples = {
    [["
     \tikz [tree layout, sibling distance=8mm]
     \graph [nodes={circle, draw, inner sep=1.5pt}]{
       1 -- { 2 -- 3 -- { 4 -- 5, 6 -- { 7, 8, 9 }}, 10 -- 11 -- { 12, 13 } }
     };
    "]],
    [["
     \tikz [tree layout, grow=-30,
            sibling distance=0mm, level distance=0mm,]
     \graph [nodes={circle, draw, inner sep=1.5pt}]{
       1 -- { 2 -- 3 -- { 4 -- 5, 6 -- { 7, 8, 9 }}, 10 -- 11 -- { 12, 13 } }
     };
    "]]
   }
}




---
declare {
  key    = "missing nodes get space",
  type   = "boolean",
  
  summary = [["
      When set to true, missing children are treated as if they
      where zero-width, zero-height nodes during the whole tree layout
      process.
  "]],
  examples = [["
      \tikz \graph [tree layout, missing nodes get space,
                    minimum number of children=2, nodes={draw,circle}]
      { a -> { b -> c -> d, e -> f -> g } };
  "]]
}



---
declare {
  key     = "significant sep",
  type    = "length",
  initial = "0",
  
  summary = [["
      This space is added to signifcant pairs by the modified
      Reingold--Tilford algorithm.
  "]],
  examples = [["
      \tikz [baseline=(a.base), tree layout, significant sep=1em,
             minimum number of children=2,
             sibling distance=5mm, level distance=5mm]
      \graph [nodes={circle, inner sep=0pt, minimum size=2mm, fill, as=}]{
        a -- { b -- c -- { d -- e, f -- { g, h }}, i -- j -- k[second] }
      };\quad
      \tikz [baseline=(a.base), tree layout, significant sep=1em,
             minimum number of children=2,
             sibling distance=5mm, level distance=5mm]
      \graph [nodes={circle, inner sep=0pt, minimum size=2mm, fill, as=}]{
        a -- { b -- c -- d -- e, i -- j -- { f -- {g,h}, k } }
      };
  "]]      
}


---
declare {
  key  = "binary tree layout",
  { key = "tree layout" },
  { key = "minimum number of children" , value=2 },
  { key = "significant sep", value = 10 },

  summary = [["
      A layout based on the Reingold--Tilford method for drawing binary trees. 
  "]],
  documentation = [["
    This key executes:
    \begin{enumerate}
    \item |tree layout|, thereby selecting the Reingold--Tilford method,
    \item |minimum number of children=2|, thereby ensuring the all nodes
      have (at least) two children or none at all, and
    \item |significant sep=10pt| to highlight significant pairs.
    \end{enumerate}
    In the examples, the last one is taken from the paper of
    Br\"uggemann-Klein and Wood. It demonstrates nicely the
    advantages of having the full power of \tikzname's anchoring and the
    graph drawing engine's orientation mechanisms at one's disposal.
  "]],
  examples = {
    [["
    \tikz [grow'=up, binary tree layout, sibling distance=7mm, level distance=7mm]
      \graph {
        a -- { b -- c -- { d -- e, f -- { g, h }}, i -- j -- k[second] }
      };
    "]],
    [["
    \tikz \graph [binary tree layout] {
      Knuth -> {
        Beeton -> Kellermann [second] -> Carnes,
        Tobin -> Plass -> { Lamport, Spivak } 
      }
    };\qquad
    \tikz [>=spaced stealth']
      \graph [binary tree layout, grow'=right, level sep=1.5em,
              nodes={right, fill=blue!50, text=white, chamfered rectangle},
              edges={decorate,decoration={snake, post length=5pt}}] 
    {
      Knuth -> {
        Beeton -> Kellermann [second] -> Carnes,
        Tobin -> Plass -> { Lamport, Spivak } 
      }
    };
    "]]
  }
}


    
---
declare {
  key = "extended binary tree layout",
  { key = "tree layout" },
  { key = "minimum number of children" , value=2 },
  { key = "missing nodes get space" },
  { key = "significant sep", value = 0 },

  summary = [["
     This algorithm is similar to |binary tree layout|, only the option
     \texttt{missing nodes get space} is executed and the
     \texttt{significant sep} is zero.
  "]],
  examples = [["
     \tikz [grow'=up, extended binary tree layout,
            sibling distance=7mm, level distance=7mm]
     \graph {
       a -- { b -- c -- { d -- e, f -- { g, h }}, i -- j -- k[second] }
     };
  "]]      
}




-- Now comes the implementation:
  
function ReingoldTilford1981:run()
  
  local root = self.spanning_tree.storage.root
  
  self.extended_version = self.digraph.options['missing nodes get space']
  
  self:precomputeDescendants(root, 1)
  self:computeHorizontalPosition(root)
  layered.arrange_layers_by_baselines(self, self.ugraph)

end


function ReingoldTilford1981:precomputeDescendants(node, depth)
  local descendants = { node }

  for _,arc in ipairs(self.spanning_tree:outgoing(node)) do
    local head = arc.head
    self:precomputeDescendants(head, depth+1)
    for _,d in ipairs(head.storage[self].descendants) do
      descendants[#descendants + 1] = d
    end
  end

  node.storage[self].layer = depth
  node.storage[self].descendants = descendants
end



function ReingoldTilford1981:computeHorizontalPosition(node)
  
  local children = self.spanning_tree:outgoing(node)

  node.pos.x = 0

  local child_depth = node.storage[self].layer + 1

  if #children > 0 then
    -- First, compute positions for all children:
    for i=1,#children do
      self:computeHorizontalPosition(children[i].head)
    end
    
    -- Now, compute minimum distances and shift them
    local right_borders = {}

    for i=1,#children-1 do
      
      local local_right_borders = {}
      
      -- Advance "right border" of the subtree rooted at
      -- the i-th child
      for _,d in ipairs(children[i].head.storage[self].descendants) do
        local layer = d.storage[self].layer
        local x     = d.pos.x          
        if self.extended_version or not (layer > child_depth and d.kind == "dummy") then
          if not right_borders[layer] or right_borders[layer].pos.x < x then
            right_borders[layer] = d
          end
          if not local_right_borders[layer] or local_right_borders[layer].pos.x < x then
            local_right_borders[layer] = d
          end
        end
      end

      local left_borders = {}
      -- Now left for i+1 st child
      for _,d in ipairs(children[i+1].head.storage[self].descendants) do
        local layer = d.storage[self].layer
        local x     = d.pos.x          
        if self.extended_version or not (layer > child_depth and d.kind == "dummy") then
          if not left_borders[layer] or left_borders[layer].pos.x > x then
            left_borders[layer] = d
          end
        end
      end

      -- Now walk down the lines and try to find out what the minimum
      -- distance needs to be.

      local shift = -math.huge
      local first_dist = left_borders[child_depth].pos.x - local_right_borders[child_depth].pos.x
      local is_significant = false

      for layer,n2 in pairs(left_borders) do
        local n1 = right_borders[layer]
        if n1 then
          shift = math.max(
            shift, 
            layered.ideal_sibling_distance(self, self.ugraph, n1, n2) + n1.pos.x - n2.pos.x
          )
        end
        if local_right_borders[layer] then
          if layer > child_depth and
            (left_borders[layer].pos.x - local_right_borders[layer].pos.x <= first_dist) then 
            is_significant = true
          end
        end
      end

      if is_significant then
        shift = shift + self.ugraph.options['significant sep']
      end

      -- Shift all nodes in the subtree by shift:
      for _,d in ipairs(children[i+1].head.storage[self].descendants) do
        d.pos.x = d.pos.x + shift
      end
    end
    
    -- Finally, position root in the middle:
    node.pos.x = (children[1].head.pos.x + children[#children].head.pos.x) / 2
  end
end



return ReingoldTilford1981