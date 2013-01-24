local UPGMA1958 = {}
UPGMA1958.__index = UPGMA1958

require("pgf.gd.trees").UPGMA1958 = UPGMA1958
local LayoutPipeline = require "pgf.gd.control.LayoutPipeline"
local distance_key = '/graph drawing/distances'

function UPGMA1958:run(phylogenetic_tree)
  -- store the phylogentic tree object, containing all user-specified
  -- graph information
	self.phy_tree = phylogenetic_tree
  self:runUPGMA()
  self:createFinalEdges()
end


--- UPGMA (Unweighted Pair Group Method using arithmetic Averages) algorithm
-- (Sokal and Michener, 1958)
--
--  this function generates a graph on the basis of such a distance
--  matrix by generating nodes and computing the edge lengths; the x-
--  and y-positions of the nodes must be set separately
--
--  requirement: a distance matrix, ideally an ultrametric
function UPGMA1958:runUPGMA()
  local g = self.phy_tree.digraph
  g.clusters = {}
  local clusters = g.clusters
  
  for i=1, #g.vertices do
    -- create the clusters
    local vertex = g.vertices[i]
    local cluster = self:newCluster(vertex)     
    table.insert( clusters, cluster )
    -- remove any preexisting edges
    g:disconnect(vertex)
    self.phy_tree.scope.syntactic_digraph:disconnect(vertex)
  end

  -- search for clusters with smallest distance and merge them
  while #clusters > 1 do
    local minimum_distance
    local min_cluster1
    local min_cluster2
    for i, cluster in ipairs (clusters) do
      for j = i+1,#clusters do
        local cluster2 = clusters[j]
        local cluster_distance = self:getClusterDistance(cluster, cluster2)
        if not minimum_distance or cluster_distance < minimum_distance then
          minimum_distance = cluster_distance
          min_cluster1 = i
          min_cluster2 = j
        end
      end
    end
    -- the following outprint can be used to follow the algorithm's steps:
   -- print("\nminimum distance:"..minimum_distance, "merging clusters:", clusters[min_cluster1].name.." and "..clusters[min_cluster2].name )
    self:mergeClusters(min_cluster1, min_cluster2, minimum_distance)
  end
	-- the node created last is the root
  g.storage.root = g.vertices[#g.vertices]
end


--- a new cluster is created
--
--  @param vertex The vertex the cluster is initialized with
--
--  @return The new cluster
function UPGMA1958:newCluster(vertex)
  local cluster = {
    vertices = {}, -- all vertices of the new cluster
    distances = {}, -- the cluster's distances to all other clusters
    name = "c"..vertex.name,
    cluster_height = 0 -- this value is equivalent to half the distance of the last two clusters
    -- that have been merged to form the current cluster;
    -- necessary for determining the distances of newly generated nodes to their children.  
  }
  table.insert(cluster.vertices, vertex)
  return cluster
end


--- gets the distance between two clusters
--
--	@param cluster1, cluster2 The two clusters
--
--	@return the distance between the clusters
function UPGMA1958:getClusterDistance(cluster1, cluster2)
  -- if the clusters' distance fields are specified, use them
  local cluster_distance = cluster1.distances[cluster2] or cluster2.distances[cluster1]
  -- else check for distances specified by the user (in the pgf distance key)
  if not cluster_distance then
    local vertex1 = cluster1.vertices[1]
    local vertex2 = cluster2.vertices[1]
    if vertex1.options[distance_key] then
      cluster_distance = vertex1.options[distance_key][vertex2]
    end
    if not cluster_distance and vertex2.options[distance_key] then
      cluster_distance = vertex2.options[distance_key][vertex1]
    end
  end
  return cluster_distance or 0 -- else return 0
end


--- merges two clusters by doing the following:
--  - deletes cluster2 from the clusters table
--  - adds all vertices from cluster2 to the vertices table of cluster1
--  - updates the distances of the new cluster to all remaining clusters
--  - generates a new node, as the new root of the cluster
--  - computes the distance of the new node to the former roots (for
--    later computation of the y-positions)
--  - generates edges, connecting the new node to the former roots
--  - updates the cluster height
--
--  @param index_of_first_cluster The index of the first cluster
--  @param index_of_second_cluster The index of the second cluster
--  @param distance The distance between the two clusters
function UPGMA1958:mergeClusters(index_of_first_cluster, index_of_second_cluster, distance)
  local g = self.phy_tree.digraph
  local cluster1 = self.phy_tree.digraph.clusters[index_of_first_cluster]
  local cluster2 = self.phy_tree.digraph.clusters[index_of_second_cluster]
  local size_of_c1 = #cluster1.vertices -- size of cluster1
  local size_of_c2 = #cluster2.vertices -- size of cluster2
  local root_of_c1 = cluster1.vertices[size_of_c1] -- first cluster's root = its last added vertex
  local root_of_c2 = cluster2.vertices[size_of_c2] -- second cluster's root

  -- update name (for debugging)
  cluster1.name = cluster1.name.." + ".. cluster2.name
  --update cluster distances
  for i,cluster in ipairs (self.phy_tree.digraph.clusters) do
    if cluster ~= cluster1 and cluster ~= cluster2 then
     local dist1 = self:getClusterDistance (cluster1, cluster)
     local dist2 = self:getClusterDistance (cluster2, cluster )
     cluster1.distances[cluster] = (dist1*size_of_c1 + dist2*size_of_c2)/ (size_of_c1+size_of_c2)
     cluster.distances[cluster1] = cluster1.distances[cluster]
    end
  end
  -- add vertices of cluster2 to cluster1
  for i, vertex in ipairs (cluster2.vertices) do
    table.insert(cluster1.vertices, vertex)
  end
  -- delete cluster2
  table.remove(self.phy_tree.digraph.clusters, index_of_second_cluster)

  --add node and connect last vertex of each cluster with new node
  local new_node = LayoutPipeline.generateNode(self.phy_tree, {
    name = "UPGMA-node ".. #self.phy_tree.digraph.vertices+1,
    generated_options = {"phylogenetic inner node"},
  } )
  new_node.storage.distance={}
  -- the distance of the new node ( = the new root of the cluster) to its children (= the former roots) is
  -- equivalent to half the distance between the two former clusters
  -- minus the respective cluster height
  local distance1 = distance/2-cluster1.cluster_height
  new_node.storage.distance[root_of_c1] = distance1
  local distance2 = distance/2-cluster2.cluster_height
  new_node.storage.distance[root_of_c2] = distance2 
 
  -- these distances are also the final edge lengths, thus:
  new_node.storage.length = {}
  if not root_of_c1.storage.length then root_of_c1.storage.length = {} end
  if not root_of_c2.storage.length then root_of_c2.storage.length = {} end
  new_node.storage.length[root_of_c1] = distance1
  root_of_c1.storage.length[new_node] = distance1

  new_node.storage.length[root_of_c2] = distance2
  root_of_c2.storage.length[new_node] = distance2
  
  --LayoutPipeline.generateEdge(self, root_of_c1, new_node, {generated_options={"newEdge"}}) 
  --LayoutPipeline.generateEdge(self, root_of_c2, new_node, {generated_options={"newEdge"}})
  g:connect(root_of_c1, new_node)
  g:connect(new_node, root_of_c1)
  g:connect(root_of_c2, new_node)
  g:connect(new_node, root_of_c2)
  
  table.insert(cluster1.vertices, new_node)
  cluster1.cluster_height = distance/2 -- set new height of the cluster
end



-- generates edges for the final graph
--
-- throughout the process of creating the tree, arcs have been
-- disconnected and connected, without truly creating edges. this is
-- done in this function
function UPGMA1958:createFinalEdges()
  local g = self.phy_tree.digraph
  for _,arc in ipairs(g.arcs) do
     LayoutPipeline.generateEdge(self.phy_tree, arc.tail, arc.head, {generated_options={}})
  end
end


return UPGMA1958
