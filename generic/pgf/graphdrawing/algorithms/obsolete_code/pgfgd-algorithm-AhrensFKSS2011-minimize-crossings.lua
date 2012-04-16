-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

-- This contains an algorithm for drawing a graph using local search.

pgf.module("pgf.graphdrawing")

--- Node positioning with local search algorithm
-- @param graph graph-Structure to generate layout for
function graph_drawing_algorithm_AhrensFKSS2011_minimize_crossings(graph)

   --read options from graph
   local hSpace = graph:getOption("/graph drawing/AhrensFKSS2011 minimize crossings/max width")
   local vSpace = graph:getOption("/graph drawing/AhrensFKSS2011 minimize crossings/max height")
   --determine maxWidth and maxHeigth of all nodes, using math.ceil to avoid broken numbers
   local maxWidth, maxHeight = 0, 0
   for node in table.value_iter(graph.nodes) do
      maxWidth = math.max(maxWidth, math.ceil(node.width))
      maxHeight = math.max(maxHeight, math.ceil(node.height))
   end


   assert(maxHeight > 0, "GD:LSG: max height of all nodes should be greater than zero")
   assert(maxWidth > 0, "GD:LSG: max width of all nodes should be greater than zero")
   --calculate number of rows and cols for the grid
   --if max width or max height is set, then use this limit, else using standard
   local maxRows = vSpace and math.floor(vSpace / maxHeight) or #graph.nodes * 2

   local maxCols = hSpace and math.floor(hSpace / maxWidth) or #graph.nodes * 2

   assert((maxCols * maxRows) >= #graph.nodes, "GD:LSG: Too many Nodes, please adjust size!")
   --create nodes for algorithm-process and position them on the grid
   local midPos = {y = math.floor(maxRows / 2) * maxHeight,
                   x = math.floor(maxCols / 2) * maxWidth}

   -- begin positioning in the middle of the grid
   local nodes, origNodesMap, nodeTable = {}, {}, {}
   local iteration, offset, switchOffset, direction = 0, 1, 0, 1
   local first = true
   for node in table.value_iter(graph.nodes) do
      local newNode = Node:new{name = node.name}
      local positioned = false
      repeat
         newNode.pos:set{x = midPos.x}
         newNode.pos:set{y = midPos.y}
         if iteration == offset then
            iteration = 0
            switchOffset = switchOffset + 1
            if switchOffset == 2 then
               switchOffset = 0
               offset = offset + 1
            end
            if switchOffset == 0 then
               direction = direction * -1
            end
         end
         if not first then
            local temp
            if switchOffset == 1 then
               newNode.pos:set{x = newNode.pos:x() + (direction * maxWidth)}
            else
               newNode.pos:set{y = newNode.pos:y() + (direction * maxHeight)}
            end
            iteration = iteration + 1
         end
         first = false
         midPos.x, midPos.y = newNode.pos:x(), newNode.pos:y()
         local x, y = (newNode.pos:x() / maxWidth), (newNode.pos:y() / maxHeight)
         if(x <= maxCols-1 and y <= maxRows-1) then
            positioned = true
         end
      until positioned

      nodes[node.name] = newNode
      origNodesMap[node.name] = node
      table.insert(nodeTable, newNode);
   end
   --create paths
   local paths = {}
   for edge in table.value_iter(graph.edges) do
      local newPath = Path:createPath(nodes[edge.nodes[1].name].pos,
         nodes[edge.nodes[2].name].pos) 
      table.insert(paths, newPath)
   end
   --instantiate startstate
   local start = {cols = maxCols,
      rows = maxRows,
      offsetX = maxWidth,
      offsetY = maxHeight,
      nodes = nodeTable,
      paths = paths,
      edges = graph.edges}
   --calculate endstate
   assert(#start.nodes == table.count_pairs(graph.nodes),
      "GD:LSG: Number of Nodes is not equal!")
   local endState = localSearch(start, simpleNeighbour, simpleCost)
   --write nodes in original graph
   for node in table.value_iter(endState.nodes) do

      origNodesMap[node.name].pos:set{x = node.pos:x()}
      origNodesMap[node.name].pos:set{y = node.pos:y()}
   end
end

--- generic local search algorithm
-- @param start State of Solution
-- @param neighbour Function for Calculation of Neigbhours of current State
-- @param cost Function for Calculation Cost of an Solutionstate
-- @param deep Deepness of Search
-- @param steps Counter, how long the algorithm should accept no better solution
function localSearch(start, neighbour, cost, deep, steps)
   deep = deep or 0
   steps = steps or 0
   local current, currentCost = start, cost(start)
   local planeCurrent
   local startCost = currentCost

   --looking at all possible neighbour-solutions
   for n in neighbour(start) do
     local c = cost(n)
     --we want the best solution
     if c < currentCost then
       current, currentCost = n, c
     elseif c == startCost then
        planeCurrent = n
     end
   end
   --the found neighbour should be better than the solution
   if currentCost > 0 and currentCost < startCost then
      return localSearch(current, neighbour, cost, deep+1, steps)
   elseif planeCurrent and steps > 0 and currentCost > 0 then
      return localSearch(planeCurrent, neighbour, cost, deep+1, steps-1)
   else
      return start
   end
end

--- Clones Solutionstate for an Graph
-- @param state current State
function cloneState(state)
   local nodeMap = {}
   ret = {cols = state.cols, --#state.nodes,
      rows = state.rows, --#state.paths,
      offsetX = state.offsetX,
      offsetY = state.offsetY,
      nodes = {},
      paths = {},
      edges = state.edges}
   for idx, val in pairs(state.nodes) do
      ret.nodes[idx] = val:copy()
      ret.nodes[idx].pos = ret.nodes[idx].pos:copy()
      nodeMap[val.name] = ret.nodes[idx]
   end
   for val in table.value_iter(state.edges) do
      local newPath = Path:createPath(
         nodeMap[val.nodes[1].name].pos,
         nodeMap[val.nodes[2].name].pos,
         false)
      table.insert(ret.paths, newPath)
   end
   return ret
end


--- Calculates all Neigbourstate to an Solutionstate
-- @param state current State
-- @return Return Function which iterates over all Neighbours
function simpleNeighbour(state)
   local nodeIdx, cx, cy = 1, 0, 0
   return
   --return function, which is called until it returns nil
   function()
      repeat
        repeat
          repeat
            if cy > ((state.rows-1) * state.offsetY) then
               break
            end
            local reserved = false
            for idx, node in ipairs(state.nodes) do
               -- if there is already a node an this position, switch them
               if tostring(node.pos:x()) == tostring(cx) and tostring(node.pos:y()) == tostring(cy) then
                  local nState = cloneState(state)
                  nState.nodes[idx].pos:set{x = nState.nodes[nodeIdx].pos:x()}
                  nState.nodes[idx].pos:set{y = nState.nodes[nodeIdx].pos:y()}
                  nState.nodes[nodeIdx].pos:set{x = tonumber(tostring(cx))}
                  nState.nodes[nodeIdx].pos:set{y = tonumber(tostring(cy))}
                  cy = cy + state.offsetY
                  return nState
               end
            end
            if not reserved then
               --on a free position, place node there
               local nState = cloneState(state)
               nState.nodes[nodeIdx].pos:set{x = tonumber(tostring(cx))}
               nState.nodes[nodeIdx].pos:set{y = tonumber(tostring(cy))}
               cy = cy + state.offsetY
               return nState
            else
               cy = cy + state.offsetY
            end
            until cy > ((state.rows-1) * state.offsetY)
          cy = 0
          cx = cx + state.offsetX
        until cx > (state.cols-1) * state.offsetX
        cx = 0
        nodeIdx = nodeIdx + 1
      until nodeIdx > #state.nodes
   end
end

--- Calculates Cost of an Solutionstate
-- counts all intersections of paths between nodes
-- @param state current Solutionstate
function simpleCost(state)
   --Cost= Intersections + average length of 33% of the longest paths
   return countIntersections(state) + (pathLength(state, math.floor(#state.paths/3)) / 1000)
end

--- Counts all path-intersections
-- @param state current solutionstate
-- @param debug activate debug output
function countIntersections(state, debug)
   local result = 0
   --local ct = 0
   --count intersections
   for i= 1, #state.paths do
      for y = 1, #state.paths do
         --ct = ct + 1
         if i ~= y then
            if state.paths[i]:intersects(state.paths[y]) then
               result = result + 1
            end
         end
      end
   end
   return result / 2
end

--- Gets the maximal path lenght
-- @param state solutionstate
function maxPath(state)
   --aggregate length of all paths
   local pLength = 0
   for path in table.value_iter(state.paths) do
      pLength = math.max(pLength, path:getLength())
   end
   assert(pLength > 0, "LSG:GD: Path-length should be greater than zero!")
   return pLength
end

--- average length of x paths
---@param state solutionstate
function pathLength(state, count)
   count = count or 1
   local temp = {}
   for path in table.value_iter(state.paths) do
      table.insert(temp, path:getLength())
   end
   table.sort(temp, function(a,b) return a > b end)
   local sum = 0
   for i = 1, count do
      sum = sum + temp[i]
   end
   return sum / count
end

--Testmethods

--- Neighbourhood-relation which only places a node in its direct neighbourhood
-- @param state Solutionstate
function nearestNeighbour(state)
   local nodeIdx, cy, cx = 1, -2, -2
   return
   function()
      repeat
      repeat
         repeat
            if cx > 2 then
            	break
            end
            --print(cx, cy, nodeIdx)
            local row, col = (state.nodes[nodeIdx].pos:y() / state.offsetY), (state.nodes[nodeIdx].pos:x() / state.offsetX)
            if ((row+cy) >= 0 and (row+cy) < state.rows) and ((col+cx) >= 0 and (col+cx) < state.cols) then
               --print "drinne"
               local reserved = false
               for node in table.value_iter(state.nodes) do
                  if node.pos:x() == ((col+cx) * state.offsetX) and node.pos:y() == ((row+cy) * state.offsetY) then
                     reserved = true
                     --print "belegt"
                     break
                  end
               end
               if not reserved then
            	   local nState = cloneState(state)
            	   local node = nState.nodes[nodeIdx]
            	   node.pos:set{x = (col + cx) * state.offsetX}
            	   node.pos:set{y = (row + cy) * state.offsetY}
            	   cx = cx + 1
            	   return nState
               end
            end
            cx = cx + 1
            until cx > 2
            cx = -1
            cy = cy + 1
         until cy > 2
      cy = -1
      nodeIdx = nodeIdx + 1
      until nodeIdx > #state.nodes
   end
end
