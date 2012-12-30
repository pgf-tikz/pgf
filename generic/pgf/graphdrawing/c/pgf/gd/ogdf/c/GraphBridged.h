#ifndef PGF_GRAPHBRIDGED_H
#define PGF_GRAPHBRIDGED_H


extern "C" {
#include <lua.h>
}

#include <ogdf/basic/EdgeArray.h>
#include <ogdf/basic/NodeArray.h>
#include <ogdf/basic/Graph.h>
#include <ogdf/basic/GraphAttributes.h>

#include <pgf/gd/ogdf/c/TableBridged.h>


namespace pgf {
    
class GraphBridged {
  
 public:
  
  // Create a TableBridged from a table on the top of the Lua stack
  GraphBridged(lua_State *L, int index=1);
  ~GraphBridged();
  
  ogdf::Graph&                     getGraph ();
  ogdf::GraphAttributes&           getGraphAttributes();
  
  ogdf::NodeArray<TableBridged*>&  getNodeOptions ();
  ogdf::EdgeArray<TableBridged*>&  getEdgeOptions ();
  
  TableBridged&                    getGraphOptions (); 
  
  void                             unbridgeGraph(lua_State *L, int index=2);
  
 private:
  
  class Rep;
  Rep* rep;
  
};
 
 
} // namespace

#endif
