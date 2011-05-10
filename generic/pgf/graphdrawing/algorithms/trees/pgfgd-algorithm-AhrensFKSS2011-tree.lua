-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This file contains an algorithm for drawing arbitrary shaped trees.

pgf.module("pgf.graphdrawing")

--- Initialising options for positioning the given graph
-- @param graph The tree-graph to be drawn
function drawGraphAlgorithm_AhrensFKSS2011_tree(graph)
   Sys:log("GD:AT: drawGraphAlgorithm_AhrensFKSS2011_tree")

   -- determine the root of the tree
   graph.root = graph:findNodeIf(function (node) return node:getOption("/graph drawing/root") end) or graph.nodes[1]
   if graph.root == nil then
      error("there is no root node, aborting")
   end
   Sys:log("GD:AT: root node is " .. tostring(graph.root))  

   -- check if the given graphstructure is really a tree
   if not isTree(graph, graph.root) then
      error("the given graph is not a tree")
   end
   for n in table.value_iter(graph.nodes) do
      Sys:log("GD:AT " .. n.name)
   end  
   -- read TEX-options
   -- leveldistance: determines the vertical space between the nodes
   local leveldistance = graph:getOption("/graph drawing/level distance") 
   local siblingdistance = graph:getOption("/graph drawing/sibling distance")
   treePositioning(graph, advancedPlace, simpleCompare, nil, leveldistance, siblingdistance)
end

--- Test if the given graph is a Tree
-- @param graph The graph to be tested
-- @return false if the graph isn't a tree, true otherwise
function isTree(graph, node)
   local result = true
   local visitedNodes = {node.name}
   if checkNodes(graph, node, visitedNodes, root) == false then
      result = false
   end   
   return result
end

--- Checks if a node has already been visited
-- @param graph The graph to be tested
-- @param node Current Node to be checked
-- @param visitedNodes Nodes that have already bee visited
-- @param parent Last checked Node
-- @return false if node has already been visited
function checkNodes(graph, node, visitedNodes, parent)
   local visited = false
   if node:getDegree() > 1 then
      for edge in table.value_iter(node.edges) do   
        --check if all nodes of the edge have already been visited
	     for node in table.value_iter(edge.nodes) do
           if table.find(visitedNodes, function (name) return name == node.name end) then
              visited = true
           else
              visited = false
           end --endif         
        end --end for node  
         
        if visited then
           --if the child has already been visited return false
          if table.find(visitedNodes, function (name) return name == edge:getNeighbour(node).name end) and edge:getNeighbour(node).name ~= parent.name then 
             return false
          end  
       else 
          --mark child as visited  
          table.insert(visitedNodes, edge:getNeighbour(node).name)                
          if checkNodes(graph, edge:getNeighbour(node), visitedNodes, node) == false then 
             return false
          end                
        end 
      end --end for egde
      else 
         --if leaf return true
         return true
   end
end

--- Positioning of an arbitary trees
-- @param tree The tree to be drawn as Graph-Object
-- @param placeBoxes Function to place root-node and childs, usage: placeBoxes(root, boxes)
--        Without, all nodes share the same place.
-- @param compareBoxes Function to sort childboxes of a root-node, usage: compareBoxes(box1, box2)
--        Without, no sorting of boxes
-- @param drawPath Function to draw a path from root to childnode, usage: drawPath(root, child) 
--        Without, edge will be direct path from center of a root to center of child
-- @return Box, containing all nodes of tree-object
function treePositioning(tree, placeBoxes, compareBoxes, drawPath, leveldistance, siblingdistance)
   drawPath = drawPath or function(r, c)
                        return Path:createPath(r:getPosAt(Box.CENTER),
                                 c:getPosAt(Box.CENTER), false)
                     end
    local resultBox
   local boxes = {}
   local edges = {}
	if(tree.root:getDegree() == 0) then
      resultBox = tree.root
   else
      resultBox = Box:new{}
		for edge in table.value_iter(tree.root.edges) do
         local node = edge:getNeighbour(tree.root)
         edges[node.name] = edge
         local box = treePositioning(tree:subGraphParent(node, tree.root),
                     placeBoxes, compareBoxes, drawPath, leveldistance, siblingdistance)
         --collect all subboxes            
         resultBox:addBox(box)
         table.insert(boxes, box)
      end
      --compare the current boxes
      if compareBoxes then
         table.sort(boxes, compareBoxes)
      end
      resultBox:addBox(tree.root)
      --final placement of the current boxes
      if placeBoxes then
         placeBoxes(tree.root, boxes, leveldistance, siblingdistance)
      end
      for box in table.value_iter(boxes) do
         local path = drawPath(tree.root, box.root)
         resultBox._paths[box.root.name] = path
      end
      resultBox:recalculateSize()
   end
   resultBox.root = tree.root
   return resultBox
end

--- Compares the Width of box1 and box2
-- @param box1 First box for Comparision
-- @param box2 Second box for Comparision
function compareWidth(box1, box2)
   return box1.width < box2.width
end

--- Compares the Height of box1 and box2
-- @param box1 First box for Comparision
-- @param box2 Second box for Comparision
function simpleCompare(box1, box2)
   return box1.height > box2.height
end

--- Places the boxes in a vertical way (similar to a filestructure)
-- @param root The rootnode of the tree
-- @param boxes The boxes to be positioned
function verticalPlace(root, boxes)
   local x = root.width
   local y = 0
   for box in table.value_iter(boxes) do
      box.pos:set{x = x}
      box.pos:set{y = y}
      y = y + 1 + box.height
   end
   root.pos:set{x = 0}
   root.pos:set{y = y}
end

--- Creates a path from root to box, useful if the boxes are positioned vertically
-- @param root Current rootnode of a treelayer, start of the path
-- @param box The box where the path should end
-- @return a path which leads not directly form root to box, but in a right angle
function verticalPathPlacement(root, box)
   local path = Path:new()
   path:addPoint(root:getPosAt(Box.CENTER, true))
   path:move(0, box:getPosAt(Box.CENTER, true):y() - root:getPosAt(Box.CENTER, true):y())
   path:addPoint(box:getPosAt(Box.CENTER, true))
   return path
end

--- Places the boxes in a simple way
-- @param root The rootnode of the tree
-- @param boxes The boxes to be positioned
-- The function places the boxes of each layer of the tree horizontally beside each other. 
-- The root of each treelayer is positioned above the left box of the layer.
function simplePlace(root, boxes)
   local lastbox
   for box in table.value_iter(boxes) do      
      if not lastbox then
         box.pos:set{x = 0}
         box.pos:set{y = 0}
         local pos = box:getPosAt(Box.UPPERRIGHT, false)
         root.pos:set{x = pos:x()}
         root.pos:set{y = pos:y() + 1}
      else
          local pos = lastbox:getPosAt(Box.UPPERRIGHT, false)
         box.pos:set{y = 0}
         box.pos:set{x = pos:x() + 1}
      end
      lastbox = box
   end
end

--- Places the boxes
-- @param root The rootnode of the tree
-- @param boxes The boxes to be positioned, the boxes are supposed to be ordered by size
-- @param leveldistance The factor to determine the vertical space between the boxes
-- @param siblingdistance The factor to determine the horizontal space between the boxes
-- The function places the boxes of each layer of the tree as follows:
-- The biggest/smallest box (depending if the boxes are ordered descending or ascending) is positioned in the middle
-- and the following boxes are positioned alternately left/right horizontally beside. 
-- The root of each layer of the tree is positioned in the middle above the layer.
function advancedPlace(root, boxes, leveldistance, siblingdistance)
   local lastbox, lastbox2
   local maxY = 0
   local width = 0
   local tempboxes = {}
   local bs = #boxes
   local i, j
   --first loop sorts the boxes
   for box in table.value_iter(boxes) do
      if not lastbox2 then
         if bs%2 == 0 then
            i = bs/2
            j = 1
         else
            i = bs/2 + 0.5
            j = 1
         end
      end   
      tempboxes[i] = box
      i = i + j   
      if j%2 == 0 then
         j = j * (-1)
         j = math.abs(j) + 1
      else
         j = math.abs(j) + 1
         j = j * (-1)    
      end
      lastbox2 = box
      if box.height >= maxY then
         maxY = box.height
      end
   end   
   boxes = tempboxes
   --second loop computes the positions of each box
   for box in table.value_iter(boxes) do      
      if not lastbox then
         box.pos:set{y = maxY - box.height}
         box.pos:set{x = 0}
         local pos = box:getPosAt(Box.UPPERRIGHT, false)
         width = width + box.width

      else
          local pos = lastbox:getPosAt(Box.UPPERRIGHT, false)
         box.pos:set{y = maxY - box.height}
         box.pos:set{x = pos:x() + siblingdistance}
         width = width + box.width + siblingdistance   
      end   
      lastbox = box
   end
   root.pos:set{y = maxY + leveldistance}
   root.pos:set{x = width/2 - root.width/2}
end

