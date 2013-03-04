#include <pgf/gd/interface/c/InterfaceFromOGDF.h>


#include "layered/SugiyamaLayout_script.h"

#include "layered/LongestPathRanking_script.h"
#include "layered/OptimalRanking_script.h"
#include "layered/CoffmanGrahamRanking_script.h"
#include "layered/DfsAcyclicSubgraph_script.h"
#include "layered/GreedyCycleRemoval_script.h"


#include "module/module_script.h"


extern "C" int luaopen_pgf_gd_ogdf_c_ogdf_script (struct lua_State *state) {
  
  scripting::script s (state);
  
  s.declare (new SugiyamaLayout_script);
  
  s.declare (new LongestPathRanking_script);
  s.declare (new OptimalRanking_script);
  s.declare (new CoffmanGrahamRanking_script);
  s.declare (new DfsAcyclicSubgraph_script);
  s.declare (new GreedyCycleRemoval_script);
  
  s.declare (new module_script);
  
  return 0;
}

