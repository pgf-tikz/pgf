local BalancedMinimumEvolution2002 = {}
BalancedMinimumEvolution2002.__index = BalancedMinimumEvolution2002

require("pgf.gd.trees").BalancedMinimumEvolution2002 = BalancedMinimumEvolution2002

local LayoutPipeline = require "pgf.gd.control.LayoutPipeline"
local distance_key = '/graph drawing/distances'

-- set outprints to true to enable informative outprints 
local outprints = false

function BalancedMinimumEvolution2002:run(phylogenetic_tree)
	self.phy_tree = phylogenetic_tree
   
	local p_a = self.phy_tree.digraph.options['/graph drawing/phylogenetic algorithm']
	self:runBME()
	if not (p_a == 'BME without BNNI') then
  	self:runBNNI()
	end
 	self:computeFinalLengths()
  -- the following allows the calculation and display of the tree length
  --[[ 
	local l = self:calculateTreeLength()
	print("\nThe tree length is "..l..".\n")--]]
  self:createFinalEdges()
end

---------------------------------
--- the BME (Balanced Minimum Evolution) algorithm
--  [DESPER and GASCUEL: Fast and Accurate Phylogeny Reconstruction Algorithms Based on the Minimum-Evolution Principle, 2002]
-- 
--  The tree is built in a way that minimizes the total tree length.
--  The leaves are inserted into the tree one after another, creating new edges and new nodes.
--  After every insertion the distance matrix has to be updated.
function BalancedMinimumEvolution2002:runBME()
  local g = self.phy_tree.digraph
  g.storage.leaves = {}
  local leaves = g.storage.leaves
  -- get user input
  for i, vertex in ipairs (g.vertices) do
    leaves[i] = vertex
    vertex.leaf = true
    -- remove any preexisting edges
    g:disconnect(vertex)
    self.phy_tree.scope.syntactic_digraph:disconnect(vertex)
  end

  -- initialize for k=3:
  assert (#leaves > 3, "Algorithm needs at least 4 leaves.")

  -- create the new node which will be connected to the first three leaves 
  local new_node = LayoutPipeline.generateNode( self.phy_tree, { name = "BMEnode"..#g.vertices+1, generated_options = {"phylogenetic inner node"} } )
  new_node.storage.distance = {}
  -- set the distances of new_node to subtrees
  local distance_1_2 = self:distance(leaves[1],leaves[2])
  local distance_1_3 = self:distance(leaves[1],leaves[3]) 
  local distance_2_3 = self:distance(leaves[2],leaves[3]) 
  new_node.storage.distance[leaves[1]] = 0.5*(distance_1_2 + distance_1_3)
  new_node.storage.distance[leaves[2]] = 0.5*(distance_1_2 + distance_2_3) 
  new_node.storage.distance[leaves[3]] = 0.5*(distance_1_3 + distance_2_3) 
  
  --connect the first three leaves to the new node
  for i = 1,3 do
    g:connect(new_node, leaves[i])
    g:connect(leaves[i], new_node)
  end

  for k = 4,#leaves do
    if outprints then
      print("computing leaf # "..k.."!\n")
    end
    g.storage.k = k
    
    -- compute distance from k to any subtree
    g.storage.k_dists = {}
    for i = 1,k-1 do
      -- note that the function called stores the k_dists before they are overwritten
      g.storage.k_dists = self:computeAverageDistancesToAllSubtreesForK(g.vertices[i])
    end
    
    -- find the best insertion point
    local best_arc = self:findBestEdge(g.vertices[1])
    if outprints then
      print("inserting leaf "..k.." (", leaves[k], ") on", best_arc)
    end
    local head = best_arc.head
    local tail = best_arc.tail

    -- remove the old arc
    g:disconnect(tail, head)
    g:disconnect(head, tail)
    
    -- create the new node 
    local new_node = LayoutPipeline.generateNode( self.phy_tree, { name = "BMEnode"..#g.vertices+1, generated_options = {"phylogenetic inner node"} } )
  
    -- gather the vertices that will be connected to the new node...
    local vertices_to_connect = { head, tail, leaves[k] }
    
    -- ...and connect them
    for _, vertex in pairs (vertices_to_connect) do
      g:connect(new_node, vertex)
      g:connect(vertex, new_node)
    end
   
		if not tail.leaf then
    	if not leaves[k].storage.distance then leaves[k].storage.distance = {} end
			leaves[k].storage.distance[tail] = g.storage.k_dists[head][tail] 
		end
		if not head.leaf then
    	if not leaves[k].storage.distance then leaves[k].storage.distance = {} end
			leaves[k].storage.distance[head] = g.storage.k_dists[tail][head] 
		end
    -- insert distances from k to subtrees into actual matrix...
    self:setAccurateDistancesForK(new_node)
   
    -- set the distance from k to the new node, which was created by inserting k into the graph
    if not leaves[k].storage.distance then leaves[k].storage.distance = {} end
    leaves[k].storage.distance[new_node] = 0.5*( self:distance(leaves[k], head) + self:distance(leaves[k],tail)) 
    
    -- update the average distances
    local values = {}
    values.s = head -- s--u is the arc into which k has been inserted
    values.u = tail
    values.new_node = new_node -- the new node created by inserting k
    self:updateAverageDistances(new_node, values)
  end
end

--- 
--  Updates the average distances from k to all subtrees
--  
--  @param vertex The starting point of the recursion
--  @param values The values needed for the recursion
--           - s, u     The nodes which span the edge into which k has been
--                      inserted
--           - new_node The new_node which has been created to insert k
--           - l        (l-1) is the number of edges between the
--                      new_node and the current subtree Y
--              
--    values.new_node, values.u and values.s must be set
--    the depth first search must begin at the new node, thus vertex
--    must be set to the newly created node 
function BalancedMinimumEvolution2002:updateAverageDistances(vertex, values)
  local g = self.phy_tree.digraph
  local k = g.storage.k
  local leaf_k = g.storage.leaves[k]
  local y, z, x
  if not values.visited then
    values.visited = {}
    values.visited[leaf_k] = leaf_k -- we don't want to visit k! 
  end
  -- there are (l-1) edges between new_node and y
  if not values.l then values.l = 1 end
  if not values.new_node then values.new_node = g:outgoing(leaf_k)[1].head end
  --values.s and values.u must be set
  
  -- the two nodes which connect the edge on which k was inserted: s,u

  local new_node = values.new_node
  local l = values.l 
  local visited = values.visited

  visited[vertex] = vertex

  -- computes the distances to Y{k} for all subtrees X of Z
  function loop_over_x( x, y, values )
    local l = values.l
    local y1= values.y1

    -- calculate distance between Y{k} and X 
    local old_distance -- the distance between Y{/k} and X needed for calculating the new distance
    if y == new_node then -- this y didn't exist in the former tree; so use y1 (see below)
       old_distance = self:distance(x,y1)
    else
      old_distance = self:distance(x,y)
    end

    local new_distance = old_distance + math.pow(2,-l) * ( self:distance(leaf_k,x) - self:distance(x,y1) )
    if not x.storage.distance then x.storage.distance = {} end
    x.storage.distance[y] = new_distance

    if not y.storage.distance then y.storage.distance = {} end
    y.storage.distance[x] = new_distance -- symmetric matrix
    
    values.x_visited[x] = x
    --go deeper to next x
    for _, x_arc in ipairs (self.phy_tree.digraph:outgoing(x)) do
      if not values.x_visited[x_arc.head] then
        local new_x = x_arc.head
        loop_over_x( new_x, y, values )
      end
    end
  end

  --loop over Z's
  for _, arc in ipairs (self.phy_tree.digraph:outgoing(vertex)) do
    if not visited[arc.head] then
      -- set y1, which is the node which was pushed further away from
      -- subtree Z by inserting k
      if arc.head == values.s then
        values.y1 = values.u
      elseif arc.head == values.u then
        values.y1 = values.s
      else
        assert(values.y1,"no y1 set!")
      end
      
      z = arc.head -- root of the subtree we're looking at
      y = arc.tail -- the root of the subtree-complement of Z

      x = z -- the first subtree of Z is Z itself
      values.x_visited = {}
      values.x_visited[y] = y -- we don't want to go there, as we want to stay within Z
      loop_over_x( z,y, values ) -- visit all possible subtrees of Z
      
      -- go to next Z
      values.l = values.l+1 -- moving further away from the new_node
      self:updateAverageDistances(z,values)
      values.l = values.l-1 -- moving back to the new_node
    end
  end
end


---
-- Computes the average distances of a node, which does not yet belong
-- to the graph, to all subtrees. This is done using a depth first
-- search
--
-- @param vertex The starting point of the depth first search
-- @param values The values for the recursion
--              - distances The table in which the distances are to be
--                stored
--              - outgoing_arcs The table containing the outgoing arcs
--                of the current vertex
-- 
-- note: self.phy_tree.digraph.storage.k must be set.
--
-- @return The average distance of the new node #k to any subtree
--    The distances are stored as follows:
--    example: distances[center][a]
--             center is any vertex, thus if center is an inner vertex
--             it has 3 neighbours a,b and c, which can all be seen as the
--             roots of subtrees A,B,C.
--             distances[center][a] gives us the distance of the new
--             node k to the subtree A.
--             if center is a leaf, it has only one neighbour, which
--             can also be seen as the root of the subtree T\{center}
--             
function BalancedMinimumEvolution2002:computeAverageDistancesToAllSubtreesForK(vertex, values)
  local k = self.phy_tree.digraph.storage.k -- number of new leaf
  local arcs = self.phy_tree.digraph.arcs
  local vertices = self.phy_tree.digraph.vertices
  if not values then
    values = {
      distances = self.phy_tree.digraph.storage.k_dists or {}, 
    }
  end
  local dist = values.distances
  local center_vertex = vertex
  -- for every vertex a table is created, in which the distances to all
  -- its subtrees will be stored
  if not values.distances[center_vertex] then values.distances[center_vertex] = {} end
  
  values.outgoing_arcs = values.outgoing_arcs or self.phy_tree.digraph:outgoing(center_vertex)
  for _, arc in ipairs (values.outgoing_arcs) do
    local root = arc.head -- this vertex can be seen as the root of a subtree
    if root.leaf then -- we know the distance of k to the leaf!
      dist[center_vertex][root] = self:distance(vertices[k], root)
      
    else -- to compute the distance we need the root's neighbouring vertices, which we can access by its outgoing arcs
      local arc1, arc2
      local arc_back -- the arc we came from
      for _, next_arc in ipairs (self.phy_tree.digraph:outgoing(root)) do
        if next_arc.head ~= center_vertex then
          arc1 = arc1 or next_arc
          arc2 = next_arc
        else
          arc_back = next_arc
        end
      end 
      
      values.outgoing_arcs = { arc1, arc2, arc_back }

      -- go deeper, if the distances for the next center node haven't been set yet
      if (not dist[root]) or ( dist[root] and not (dist[root][arc1.head] and dist[root][arc2.head]) ) then 
        self:computeAverageDistancesToAllSubtreesForK(root, values)
      end
        
      -- set the distance between k and subtree
      dist[center_vertex][root] = 1/2 * (dist[root][arc1.head] + dist[root][arc2.head])  
    end    
  end
  return values.distances 
end


--- Sets the distances from k to subtrees
--  In computeAverageDistancesToAllSubtreesForK the distances to ALL possbile
--  subtrees are computed. Once k is inserted many of those subtrees don't
--  exist  for k, as k is now part of them. In this  function all
--  still accurate subtrees and their distances to k are
--  extracted.
--
--  @param center The vertex serving as the starting point of the depth-first search;
--  should be the new_node
--  self.phy_tree.digraph.storage.k and self.phy_tree.digraph.storage.k_dists must be set
function BalancedMinimumEvolution2002:setAccurateDistancesForK(center,visited)
  local leaves = self.phy_tree.digraph.storage.leaves
  local visited = visited or {}
  local k = self.phy_tree.digraph.storage.k
  local k_dists = self.phy_tree.digraph.storage.k_dists
  visited[center] = center
  local outgoings = self.phy_tree.digraph:outgoing(center)
  for _,arc in ipairs (outgoings) do
    local vertex = arc.head
    if vertex ~= leaves[k] then
      local distance
      --make sure options fields exist for leaf k and the other vertex
      if not leaves[k].storage.distance then
        leaves[k].storage.distance = {}
      end
      if not vertex.storage.distance then
        vertex.storage.distance = {}
      end
      -- set the distance
      if not leaves[k].storage.distance[vertex] and k_dists[center] then
        distance = k_dists[center][vertex] -- use previously calculated distance 
        leaves[k].storage.distance[vertex] = distance
        vertex.storage.distance[leaves[k]] = distance
      end
      -- go deeper 
      if not visited[vertex] then
        self:setAccurateDistancesForK(vertex,visited)
      end
    end
  end
end


---
--  Find the best edge for the insertion of leaf #k, such that the
--  total tree length is minimized. This function uses a depth first
--  search.
--
--  @param vertex The vertex where the depth first search is
--                started; must be a leaf
--  @param values The values needed for the recursion
--              - visited: The vertices that already have been visited
--              - tree_length: The current tree_length
--              - best_arc: The current best_arc, such that the tree
--                length is minimzed
--              - min_length: The smallest tree_length found so far
function BalancedMinimumEvolution2002:findBestEdge(vertex, values)
  local k_dists = self.phy_tree.digraph.storage.k_dists
  local arcs = self.phy_tree.digraph.arcs
  local vertices = self.phy_tree.digraph.vertices
  if not values then
    values = {
      visited = {}, -- all nodes that have already been visited
  }
  end
  values.visited[vertex] = vertex

  local c -- the arc we came from
  local unvisited_arcs = {} --unvisited arcs
  --identify arcs
  for _, arc in ipairs (self.phy_tree.digraph:outgoing(vertex)) do
    if not values.visited[arc.head] then
      table.insert (unvisited_arcs, arc)
    else
      c = arc.head--last visited arc
    end
  end

  for i, arc in ipairs (unvisited_arcs) do
    local change_in_tree_length = 0 
     -- set tree length to 0 for first insertion arc
    if not values.tree_length then
      values.tree_length = 0
      values.best_arc = arc
      values.min_length = 0
    else -- compute new tree length for the case that k is inserted into this arc
      local b = arc.head --current arc
      local a = unvisited_arcs[i%2+1].head -- the remaining arc
      local k_v = vertices[k] -- the leaf to be inserted
      change_in_tree_length = 1/4 * ( (   self:distance(a,c)
                                        + k_dists[vertex][b])
                                        - (self:distance(a,b)
                                        + k_dists[vertex][c]) )
      values.tree_length = values.tree_length + change_in_tree_length
    end
    -- if the tree length becomes shorter, this is the new best arc
    -- for the insertion of leaf k  
    if values.tree_length < values.min_length then
      values.best_arc = arc
      values.min_length = values.tree_length
    end
      
    -- go deeper
    self:findBestEdge(arc.head, values)
      
    values.tree_length = values.tree_length - change_in_tree_length
  end
  return values.best_arc
end

--- Calculates the total tree length
-- This is done by adding up all the edge lengths
--
-- @return the tree length
function BalancedMinimumEvolution2002:calculateTreeLength()
	local vertices = self.phy_tree.digraph.vertices
	local sum = 0

	for index, v1 in ipairs(vertices) do
		for i = index+1,#vertices do
			local v2 = vertices[i]
			local dist = v1.storage.length[v2]
			if dist then
				sum = sum + dist
			end
		end
	end
	return sum
end

-- generates edges for the final graph
--
-- throughout the process of creating the tree, arcs have been
-- disconnected and connected, without truly creating edges. this is
-- done in this function
function BalancedMinimumEvolution2002:createFinalEdges()
  local g = self.phy_tree.digraph
  for _,arc in ipairs(g.arcs) do
     LayoutPipeline.generateEdge(self.phy_tree, arc.tail, arc.head, {generated_options={}})
  end
end


--- Gets the distance between two nodes as specified in their options
--  or storage fields.
--  Note: this function implies that the distance from a to b is the
--  same as the distance from b to a.
--
--  @param a,b The nodes
--  @return The distance between the two nodes
function BalancedMinimumEvolution2002:distance(a, b)
  -- first look if there is a distance stored in the nodes' storages
  if a.storage.distance and a.storage.distance[b] then
    return a.storage.distance[b]
  elseif b.storage.distance and b.storage.distance[a] then
    return b.storage.distance[a]
  -- if not, look in the nodes' options fields; the distances stored
  -- here are the ones specified by the user
  elseif a.options[distance_key] ~= nil and a.options[distance_key][b] ~= nil then
    return a.options[distance_key][b]
  elseif b.options[distance_key]~= nil and b.options[distance_key][a] ~= nil then
    return b.options[distance_key][a]
  else
    -- treat BME algorithm specially
    if self.phy_tree.digraph.storage.bme then
      if a == b then
        return 0
      else
        return nil
      end
    else
      return 0
    end
  end
end


--------------------------------------
--- BNNI (Balanced Nearest Neighbour Interchange)
--  [DESPER and GASCUEL: Fast and Accurate Phylogeny Reconstruction Algorithms Based on the Minimum-Evolution Principle, 2002]
-- swaps two distant-3 subtrees if the total tree length is reduced by doing so, until no such swaps are left
--
-- step 1: precomputation of all average distances between non-intersecting subtrees (already done by BME)
-- step 2: create heap of possible swaps
-- step 3: ( current tree with subtrees a,b,c,d: a--v-- {b, w -- {c, d}} )
-- 					(a): edge (v,w) is the best swap on the heap. Remove (v,c) and (w,b)
-- 					(b), (c), (d) : update the distance matrix
-- 					(e): remove the edge (v,w) from the heap; check the four edges adjacent to it for new possible swaps
-- 					(d): if the heap is non-empty, return to (a)

function BalancedMinimumEvolution2002:runBNNI()
  local g = self.phy_tree.digraph
	-- create a heap of possible swaps
  local possible_swaps = self:newHeap()
  -- go over all arcs, look for possible swaps and add them to the heap [step 2]
  for _, arc in ipairs (g.arcs) do
    self:getBestSwap(arc, possible_swaps)
  end

  -- achieve best swap and update the distance matrix, until there is
  -- no more swap to perform
  if outprints then
    print("______________\nBeginning to swap:")
  end

	while #possible_swaps > 0 do 
    -- get the best swap and delete it from the heap
    local swap = possible_swaps[1].element --[part of step 3 (a)]
    possible_swaps:delete_top_element() -- [part of step 3 (e)]
    
    -- Check if the indicated swap is still possible. Another swap may
    -- have interfered.
    if g:arc(swap.v, swap.subtree1) and g:arc(swap.w, swap.subtree2) and g:arc(swap.v, swap.w) and g:arc(swap.a, swap.v) and g:arc(swap.d, swap.w) then
    	-- insert new arcs and delete the old ones to perform the swap [part of step 3 (a)]
     
      if outprints then
        print("\nSwapping edges:", g:arc(swap.v, swap.subtree1),"and", g:arc(swap.w, swap.subtree2))
        print("across edge: "..swap.v.name.."-->"..swap.w.name)
      end
      
      -- disconnect old arcs
			g:disconnect(swap.v, swap.subtree1)
      g:disconnect(swap.subtree1, swap.v)
      g:disconnect(swap.w, swap.subtree2)
      g:disconnect(swap.subtree2, swap.w)
      
      -- connect new arcs
      g:connect(swap.v, swap.subtree2)
      g:connect(swap.subtree2, swap.v)
      g:connect(swap.w, swap.subtree1)
      g:connect(swap.subtree1, swap.w)

      --update distance matrix
      self:updateBNNI(swap)

      -- update heap: check neighbouring arcs for new possible swaps
      -- [step 3 (e)]
      self:getBestSwap(g:arc(swap.a,swap.v), possible_swaps)
      self:getBestSwap(g:arc(swap.subtree2, swap.v), possible_swaps)
      self:getBestSwap(g:arc(swap.d,swap.w), possible_swaps)
      self:getBestSwap(g:arc(swap.subtree1, swap.w), possible_swaps)
    end
  end

end


---updates the distance matrix after a swap has been performed [step3(b),(c),(d)]
--
--@param swap A table containing the information on the performed swap
--            subtree1, subtree2: the two subtrees, which
--            were swapped
--            a, d: The other two subtrees bordering the
--            swapping edge
--            v, w : the two nodes connecting the swapping edge

function BalancedMinimumEvolution2002:updateBNNI(swap)
  local g = self.phy_tree.digraph
  local b = swap.subtree1
  local c = swap.subtree2
  local a = swap.a
  local d = swap.d
  local v = swap.v
  local w = swap.w
  
  -- updates the distances in one of the four subtrees adjacent to the
  -- swapping edge
  function update_BNNI_subtree(swap, values)
    local g = self.phy_tree.digraph
    local b = swap.farther
    local c = swap.nearer
    local a = swap.subtree
    local v = swap.v
    local d = swap.same
    local w = swap.w
  
    if not values then
      values = {
        visited = {[v] = v}, 
        possible_ys = {v},
        x = a,
        y = v
      }
      -- if we're looking at subtrees in one of the swapped subtrees,
      -- then need the old root (w) for the calculations
      if swap.swapped_branch then values.possible_ys = {w} end
    end
    local visited = values.visited
    local x = values.x
    local y = values.y
    local ys = values.possible_ys
    local l = 0 -- number of edges between y and v
  
    local dist_x_b = self:distance(x,b)
    local dist_x_c = self:distance(x,c)
    visited[x] = x --mark current x as visited
    
    -- loop over possible y's:
    for _, y in ipairs (ys) do
      -- update distance [step 3(b)]
      local distance = self:distance(x,y) - 2^(-l-2)*dist_x_b + 2^(-l-2)*dist_x_c 
      
      if y == w then y = v end -- the old distance w,x was used for the new distance calculation, but it needs to be
      -- saved under its appropriate new name according to its new root. this case only arises when looking at x's
      -- in one of the swapped subtrees (b or c)

      x.storage.distance[y] = distance
      y.storage.distance[x] = distance
      l = l+1 -- length + 1, as the next y will be further away from v
    end
  
    -- update the distance between x and w (root of subtree c and d)
    -- [step 3(c)]
    local distance = 1/2 * (self:distance(x,b) + self:distance(x,d))
    x.storage.distance[w] = distance
    w.storage.distance[x] = distance
    
    -- go to next possible x's
    table.insert(ys, x) -- when we're at the next possible x, y can also be the current x
		for _,arc in ipairs (g:outgoing(x)) do
      if not visited[arc.head] then
        values.x = arc.head
        --go deeper
        update_BNNI_subtree(swap, values)
      end
    end
  end
	
	-- name the nodes/subtrees in a general way that allows the use of the function update_BNNI_subtree
  local update_a = {subtree = a, farther = b, nearer = c, v = v, same = d, w = w}
  local update_b = {subtree = b, farther = a, nearer = d, v = w, same = c, w = v, swapped_branch = true}
  local update_c = {subtree = c, farther = d, nearer = a, v = v, same = b, w = w, swapped_branch = true}
  local update_d = {subtree = d, farther = c, nearer = b, v = w, same = a, w = v}
 
	-- update the distances within the subtrees a,b,c,d respectively
  update_BNNI_subtree(update_a)
  update_BNNI_subtree(update_b)
  update_BNNI_subtree(update_c)
  update_BNNI_subtree(update_d)

  -- update the distance between subtrees v and w [step 3 (d)]:
  local distance = 1/4*( self:distance(a,b) + self:distance(a,d) + self:distance(c,b) + self:distance(c,d) ) 
  v.storage.distance[w] = distance
  w.storage.distance[v] = distance
end


--- finds the best swap across an arc and inserts it into the heap of
--  possible swaps
--
--  @param arc The arc, which is to be checked for possible swaps
--  @param heap_of_swaps The heap, containing all swaps, which
--  improve the total tree length
--
--  the following data of the swap are saved:
--    v,w = the nodes connecting the arc, across which the swap is
--          performed
--    subtree1,2 = the roots of the subtrees that are to be swapped
--    a,d = the roots of the two remaining subtrees adjacent to the arc

function BalancedMinimumEvolution2002:getBestSwap(arc, heap_of_swaps)
  local g = self.phy_tree.digraph
  local possible_swaps = heap_of_swaps
  local v = arc.tail
  local w = arc.head
    
  -- only look at inner edges:
  if not v.leaf and not w.leaf then
    -- get the roots of the adjacent subtrees
    local a, b, c, d
    for _,outgoing in ipairs (g:outgoing(v)) do 
      local head = outgoing.head
      if head ~= w then
        a = a or head
        b = head
      end
    end
    
    for _,outgoing in ipairs (g:outgoing(w)) do
      local head = outgoing.head
      if head ~= v then
        c = c or head
        d = head
      end
    end
    
		-- get the distances between the four subtrees
		local a_b = self:distance(a,b)
    local a_c = self:distance(a,c)
    local a_d = self:distance(a,d)
    local b_c = self:distance(b,c)
    local b_d = self:distance(b,d)
    local c_d = self:distance(c,d)

    -- difference in total tree length between old tree (T) and new tree (T')
    -- when nodes b and c are swapped
    local swap1 = 1/4*(a_b + c_d - a_c - b_d )

    -- difference in total tree length between old tree and new tree when nodes b and d are swapped
    local swap2 = 1/4*(a_b + c_d - a_d - b_c)
			
		-- choose the best swap that reduces the total tree length most (T-T' > 0)
    if swap1 > swap2 and swap1 > 0 then 
		-- v,w = the nodes connecting the edge across which the swap is performed
		-- subtree1 = one of the nodes to be swapped; connected to v
		-- subtree2 = the other node to be swapped; connected to w
		-- a = other node connected to v
		-- d = other node connected to w
 	  	local swap = { v = v, w = w, subtree1 = b, subtree2 = c, a = a, d = d }
      -- insert the swap into the heap
			possible_swaps:insert(swap, swap1)
    elseif swap2 > 0 then 
      local swap = { v = v, w = w, subtree1 = b, subtree2 = d, d = c, a = a }
      possible_swaps:insert(swap, swap2)
    end
  end
end


-- creates a binary heap
-- implementation as an array as described in the respective wikipedia article
function BalancedMinimumEvolution2002:newHeap()
  local g = self.phy_tree.digraph
  local heap = {}
  
  function heap:insert(element, value)
    local object = {}
    object.element = element
    object.value = value
    table.insert(heap, object)
    
    local i = #heap
    local parent = math.floor(i/2)
    
    -- sort the new object into its correct place
    while heap[parent] and heap[parent].value < heap[i].value do
      heap[i] = heap[parent]
      heap[parent] = object
      i = parent
      parent = math.floor(i/2)
    end
  end
  
  -- deletes the top element from the heap
  function heap:delete_top_element()
    -- replace first element with last and delete the last element
    heap[1] = heap[#heap]
    table.remove(heap, #heap)
    
    local i = 1
    local left_child = 2*i 
    local right_child = 2*i +1
    local not_done = true

    -- sort the new top element into its correct place by swapping it
    -- against its largest child
    while not_done and heap[left_child] do 
      local largest_child
      if heap[right_child] then
        if heap[left_child].value > heap[right_child].value then
          largest_child = left_child
        else
          largest_child = right_child
        end
      else
        largest_child = left_child
      end

      if largest_child and heap[largest_child].value > heap[i].value then
        local temp = heap[largest_child]
        heap[largest_child] = heap[i]
        heap[i] = temp
        i = largest_child
        left_child = 2*i 
        right_child = 2*i +1
      else -- the element is already at its correct place
        not_done = false
      end
    end
  end

  return heap 
end

--------------------------------
--- computes the final branch lengths
--
--	goes over all arcs and computes the final branch lengths,
--	as neither the BME nor the BNNI phy_tree does so.
function BalancedMinimumEvolution2002:computeFinalLengths()
  local g = self.phy_tree.digraph
  for _, arc in ipairs(g.arcs) do
    local head = arc.head
    local tail = arc.tail
    local distance 
    local a,b,c,d
		-- assert, that the length hasn't already been computed for this arc
    if not head.storage.length or not head.storage.length[tail] then
      if not head.leaf then
        -- define subtrees a and b
				for _, arc in ipairs (g:outgoing(head)) do
          local subtree = arc.head
          if subtree ~= tail then
            a = a or subtree
            b = subtree
          end
        end
      end
      if not tail.leaf then
				-- define subtrees c and d
        for _, arc in ipairs (g:outgoing(tail)) do
          local subtree = arc.head
          if subtree ~= head then
            c = c or subtree
            d = subtree
          end
        end
      end
			-- compute the distance using the formula for outer or inner edges, respectively
      if head.leaf then
        distance = 1/2 * (  self:distance(head,c)
                          + self:distance(head,d)
                          - self:distance(c,d)   )
     elseif tail.leaf then
        distance = 1/2 * (  self:distance(tail,a)
                          + self:distance(tail,b)
                          - self:distance(a,b)   )
      else --inner edge
        distance = self:distance(head, tail)
                   -1/2 * (  self:distance(a,b)
                           + self:distance(c,d) )
      end

     	-- save the distance in the vertices' storage 
      head.storage.length = head.storage.length or {}
      tail.storage.length = tail.storage.length or {}
      head.storage.length[tail] = distance
      tail.storage.length[head] = distance
    end
  end

  if outprints then
    print("\nfinal distance matrix:")
    self:printDists(self.phy_tree.digraph.vertices) 
    print("\nfinal edge lengths:")
    self:printLengths(self.phy_tree.digraph.vertices)
  end
end

-----------------------------------
--debugging and outprint functions
--these are only used when outprints are set to true

-- prints out a distance matrix for a set of vertices
function BalancedMinimumEvolution2002:printDists(vertices)
  local function round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
  end

  for i,v in ipairs (vertices) do
    local s=v.name.."   "
    for j,v2 in ipairs (vertices) do
      local dist = self:distance(v,v2)
      if dist== nil then dist="x"
      else
        dist = round(dist,2)
      end
      s=s..dist.."  "
    end
    s=s.."\n"
    print(s)
  end
  print("\n\n")
end

-- prints out the lengths of the arcs between a set of vertices
function BalancedMinimumEvolution2002:printLengths(vertices)
  local function round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
  end

  for i,v in ipairs (vertices) do
    local s=v.name.."   "
    for j,v2 in ipairs (vertices) do
      local dist = v.storage.length[v2]
      if dist== nil then dist="x"
      else
        dist = round(dist,2)
      end
      s=s..dist.."  "
    end
    s=s.."\n"
    print(s)
  end
  print("\n\n")
end

return BalancedMinimumEvolution2002
