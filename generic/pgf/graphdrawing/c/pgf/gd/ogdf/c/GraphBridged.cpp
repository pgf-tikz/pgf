
extern "C" {
#include <lauxlib.h>
}


#include <pgf/gd/ogdf/c/GraphBridged.h>
#include <ogdf/basic/geometry.h>

#include <map>
#include <set>
#include <vector>


using namespace std;
using namespace ogdf;

namespace pgf {
  

  // Let us start with the internals:
  
  class GraphBridged::Rep {

  public:
    
    Graph                         graph;
    GraphAttributes               graph_attributes;
    
    NodeArray<TableBridged*>      node_options;
    EdgeArray<TableBridged*>      edge_options;

    vector<node>                  indices_to_nodes;
    EdgeArray<pair<int,int> >     edge_indices;
    
    TableBridged*                 graph_options;
    TableBridged*                 default_options;
    
    vector<TableBridged*>         options_table;
    
    Rep (lua_State* L, int index);
    ~Rep ();
    
    void unbridgeGraph        (lua_State *L, int index);
    
  private:
    
    void bridgeOptionTables   (lua_State *L, int index);
    void bridgeVertices       (lua_State *L, int index);
    void bridgeEdges          (lua_State *L, int index);

  };
  

  // Now comes the implementation of the internals:
  // When this function is called, the Lua tos (top of stack) must be
  // the object returned by Adaptorhelper.prepareGraphForC
  
  GraphBridged::Rep::Rep(lua_State* L, int index) {
    if (index < 0)
      index = lua_gettop(L) + index + 1;
    
    // Create graph:
    graph = Graph();
    
    // Create graph attributes:
    graph_attributes = GraphAttributes(graph,
				       GraphAttributes::nodeGraphics |
				       GraphAttributes::edgeGraphics |
				       GraphAttributes::nodeLevel |
				       GraphAttributes::edgeIntWeight |
				       GraphAttributes::edgeDoubleWeight |
				       GraphAttributes::nodeWeight);

    // Create options table:
    lua_getfield(L, index, "options");
    if (!lua_getmetatable(L, -1))
      luaL_error(L, "option table does not have a metatable");
    default_options = new TableBridged(L);
    lua_pop(L, 1);
    
    graph_options = new TableBridged(L, default_options);
    lua_pop(L, 1);
    
    // Create arrays:
    node_options = NodeArray<TableBridged*> (graph);
    edge_options = EdgeArray<TableBridged*> (graph);
    edge_indices = EdgeArray<pair<int, int> > (graph);
    
    // Ok, everything created. Now start filling:
    bridgeOptionTables (L, index);
    bridgeVertices (L, index);
    bridgeEdges (L, index);
  }
  
  GraphBridged::Rep::~Rep() {
    delete default_options;
    delete graph_options;
    for (vector<TableBridged*>::iterator i = options_table.begin(); i != options_table.end(); i++) 
      delete *i;
  }

  void GraphBridged::Rep::bridgeOptionTables(lua_State *L, int index) {
    lua_getfield(L, index, "options_for_c");
    int len = lua_objlen(L, -1);
    for (int i=1; i<=len; i++) {
      lua_rawgeti(L, -1, i);
      options_table.push_back(new TableBridged(L, default_options));
      lua_pop(L, 1);
    }
    lua_pop(L, 1);
  }
  
  void GraphBridged::Rep::bridgeVertices(lua_State *L, int index) {
    
    // Get vertex array:
    lua_getfield(L, index, "vertices_for_c");
    
    // The tos is the vertex array.
    int array_length = lua_objlen(L, -1);
    
    for (int i=1; i<= array_length; i++) {
      node n = graph.newNode();

      indices_to_nodes.push_back(n);
      
      lua_rawgeti(L, -1, i);
      // The tos is now the entry
      
      // Read option index:
      lua_getfield(L, -1, "options_index");
      node_options[n] = options_table[lua_tointeger(L,-1)-1];
      lua_pop(L,1);
      
      // Read width index:
      lua_getfield(L, -1, "width");
      graph_attributes.width(n) = lua_tonumber(L,-1);
      lua_pop(L,1);
      
      // Read height index:
      lua_getfield(L, -1, "height");
      graph_attributes.height(n) = lua_tonumber(L,-1);
      lua_pop(L,1);
      
      // Read other indices...
      
      // Missing...
      
      // Pop vertex
      lua_pop(L,1);
    }  
    
    lua_pop(L, 1);
  }
  
  void GraphBridged::Rep::bridgeEdges(lua_State *L, int index) {
    
    // Get vertex array:
    lua_getfield(L, index, "syntactic_edges_for_c");
          
    // The tos is the vertex array.
    int array_length = lua_objlen(L, -1);
    
    for (int i=1; i<= array_length; i++) {
      lua_rawgeti(L, -1, i);
      // The tos is now the entry

      // Find head and tail nodes:
      lua_getfield(L, -1, "tail_index");
      int tail_index = lua_tointeger(L,-1);
      lua_getfield(L, -2, "head_index");
      int head_index = lua_tointeger(L,-1);
      lua_pop(L,2);
      
      node tail = indices_to_nodes[tail_index-1];
      node head = indices_to_nodes[head_index-1];

      edge e = graph.newEdge(tail, head);
      
      // Read option index:
      lua_getfield(L, -1, "options_index");
      edge_options[e] = options_table[lua_tointeger(L,-1)-1];
      lua_pop(L,1);
      
      // Read indices...
      lua_getfield(L, -1, "syntactic_edge_index");
      int se_index = lua_tointeger(L,-1);
      lua_getfield(L, -2, "arc_index");
      int arc_index = lua_tointeger(L,-1);
      lua_pop(L,2);
      
      edge_indices[e] = pair<int, int>(arc_index, se_index);

      // Read other indices...

      // Missing...
      
      // Pop edge
      lua_pop(L,1);
    }  
    
    lua_pop(L, 1);
  }

  
  // Called after the C code has run. See
  // Bridge.unbridgeGraph for details. 
  void GraphBridged::Rep::unbridgeGraph(lua_State *L, int index) {
    
    // Vertex tables
    lua_getfield(L, index, "vertex_indices");
    int vertex_indices = lua_gettop(L);

    lua_getfield(L, index, "x");
    int x = lua_gettop(L);

    lua_getfield(L, index, "y");
    int y = lua_gettop(L);
    
    // Edge tables
    lua_getfield(L, index, "arc_indices");
    int arc_indices = lua_gettop(L);

    lua_getfield(L, index, "syntactic_edge_indices");
    int se_indices = lua_gettop(L);

    lua_getfield(L, index, "bends");
    int bends = lua_gettop(L);
    
    // Start writing back the computed coordinates of the vertices:
    int i = 1;
    for (node v = graph.firstNode(); v; i++, v = v->succ()) {
      // Set vertex_indices[i] = i
      lua_pushinteger(L, i);
      lua_rawseti(L, vertex_indices, i);
      
      // Set x[i] = x-position
      lua_pushnumber(L, graph_attributes.x(v));
      lua_rawseti(L, x, i);

      // Set y[i] = y-position
      lua_pushnumber(L, graph_attributes.y(v));
      lua_rawseti(L, y, i);
    }
    
    // Now, start writing back the computed edge infos:
    int j = 1;
    for (edge e = graph.firstEdge(); e; j++, e = e->succ()) {

      pair<int, int> p = edge_indices[e];

      // Set arc_indices[j] = p.first
      lua_pushinteger(L, p.first);
      lua_rawseti(L, arc_indices, j);

      // Set syntactic_edge_index[j] = p.second
      lua_pushinteger(L, p.second);
      lua_rawseti(L, se_indices, j);

      // Now, build bend table
      lua_createtable(L, 0, 1); // The 1 is temporary until the link problem is fixed

      DPolyline bend = graph_attributes.bends(e);
      bend.unify();
      bend.normalize();

      int k = 1;
      for (List<DPoint>::iterator it = bend.begin(); it.valid(); it++, k++) {
	// Make a new entry:
	lua_createtable(L, 0, 2);
	lua_pushnumber(L, (*it).m_x);
	lua_setfield(L, -2, "x");
	lua_pushnumber(L, (*it).m_y);
	lua_setfield(L, -2, "y");
	lua_rawseti(L, -2, k);
      }
      
      lua_rawseti(L, bends, j);
    }

    // Ok, cleanup
    lua_pop(L, 6);
  }  
  


  GraphBridged::GraphBridged(lua_State *L, int index)
  {
    rep = new Rep (L, index);
  }
  
  GraphBridged::~GraphBridged()
  {
    if (rep)
      delete rep;
  }

  Graph& GraphBridged::getGraph ()
  {
    return rep->graph;
  }

  GraphAttributes& GraphBridged::getGraphAttributes()
  {
    return rep->graph_attributes;
  }

  NodeArray<TableBridged*>& GraphBridged::getNodeOptions ()
  {
    return rep->node_options;
  }
  
  EdgeArray<TableBridged*>& GraphBridged::getEdgeOptions ()
  {
    return rep->edge_options;
  }
 
  TableBridged& GraphBridged::getGraphOptions ()
  {
    return *rep->graph_options;
  }

  void GraphBridged::unbridgeGraph(lua_State *L, int index)
  {
    rep->unbridgeGraph(L, index);
  }
  
}
