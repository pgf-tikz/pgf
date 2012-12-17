extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
  
int luaopen_pgf_gd_ogdf_c_Control (lua_State *L);
}


#include <pgf/gd/ogdf/c/GraphBridged.h>

#include <ogdf/basic/Graph.h>
#include <ogdf/basic/GraphAttributes.h>

#include <ogdf/layered/SugiyamaLayout.h>
#include <ogdf/layered/OptimalRanking.h>
#include <ogdf/layered/MedianHeuristic.h>

#include <ogdf/energybased/FMMMLayout.h>

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
  
  FMMMLayout fmmm;
  
  fmmm.useHighLevelOptions(true);
  fmmm.unitEdgeLength(15.0); 
  fmmm.newInitialPlacement(true);
  fmmm.qualityVersusSpeed(FMMMLayout::qvsGorgeousAndEfficient);
  
  fmmm.call(gb.getGraphAttributes());

  // Ok, now, move back:
  gb.unbridgeGraph(L);
  lua_call(L, 2, 0);
  
  return 0;
}

static const struct luaL_reg registry [] = {
  {"run", run},
  {"run_fmmm", run_fmmm},
  {NULL, NULL}  /* sentinel */
};

int luaopen_pgf_gd_ogdf_c_Control (lua_State *L) {
  luaL_register(L, "pgf.gd.ogdf.c.Control", registry);
  return 1;
}
