extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
  
int luaopen_pgf_gd_ogdf_c_Control (lua_State *L);
}

#include <pgf/gd/ogdf/c/Declare.h>

#include <pgf/gd/ogdf/c/GraphBridged.h>

#include <ogdf/basic/Graph.h>
#include <ogdf/basic/GraphAttributes.h>

#include <ogdf/layered/SugiyamaLayout.h>
#include <ogdf/layered/OptimalRanking.h>
#include <ogdf/layered/MedianHeuristic.h>

#include <ogdf/energybased/FMMMLayout.h>

#include <cstdlib>

using namespace ogdf;
using namespace pgf;


// Stack:
// 1 is unbridgeGraph function,
// 2 is the graph
// 3 is graph prepared for use by GraphBridge

static int run (lua_State *L) {
  
  GraphBridged gb (L);
  lua_pop(L, 1);
  
  // To be moved to separate function:
  SugiyamaLayout SL;
  SL.setRanking(new OptimalRanking);
  SL.setCrossMin(new MedianHeuristic);
  SL.call(gb.getGraphAttributes());

  // Ok, now, move back:
  gb.unbridgeGraph(L);
  lua_call(L, 2, 0);
  
  return 0;
}


static int run_fmmm (lua_State *L) {

  GraphBridged gb (L);
  lua_pop(L, 1);

  srand(gb.getGraphOptions().getNumberField("random seed"));
  
  FMMMLayout fmmm;
  
  //  fmmm.useHighLevelOptions(true);
  fmmm.unitEdgeLength(gb.getGraphOptions().getNumberField("node distance")); 
  fmmm.randSeed(gb.getGraphOptions().getNumberField("random seed"));
  fmmm.newInitialPlacement(false);
  fmmm.qualityVersusSpeed(FMMMLayout::qvsGorgeousAndEfficient);
  
  fmmm.call(gb.getGraphAttributes());

  // Ok, now, move back:
  gb.unbridgeGraph(L);
  lua_call(L, 2, 0);
  
  return 0;
}

static int do_declarations(lua_State* L) {
  
  Parameter p;
  p.key = "layered crossing fail stop";
  p.type = "number";
  p.initial = "4";
  p.summary =
"The number of times that the number of crossings may not\n\
decrease after a complete top-down bottom-up traversal,\n\
before a run is terminated.";
  p.declare(L);

  return 0;
  
}


static const struct luaL_reg registry [] = {
  {"do_declarations", do_declarations},
  {"run", run},
  {"run_fmmm", run_fmmm},
  {NULL, NULL}  /* sentinel */
};

int luaopen_pgf_gd_ogdf_c_Control (lua_State *L) {
  luaL_register(L, "pgf.gd.ogdf.c.Control", registry);
  return 1;
}
