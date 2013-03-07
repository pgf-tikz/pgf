#include <pgf/gd/interface/c/InterfaceFromOGDF.h>


#include "module/module_script.h"

#include "layered/SugiyamaLayout_script.h"

#include "layered/LongestPathRanking_script.h"
#include "layered/OptimalRanking_script.h"
#include "layered/CoffmanGrahamRanking_script.h"

#include "layered/DfsAcyclicSubgraph_script.h"
#include "layered/GreedyCycleRemoval_script.h"

#include "layered/BarycenterHeuristic_script.h"
#include "layered/GreedyInsertHeuristic_script.h"
#include "layered/SiftingHeuristic_script.h"
#include "layered/MedianHeuristic_script.h"
#include "layered/SplitHeuristic_script.h"

#include "layered/FastHierarchyLayout_script.h"
#include "layered/FastSimpleHierarchyLayout_script.h"


extern "C" int luaopen_pgf_gd_ogdf_c_ogdf_script (struct lua_State *state) {
  
  scripting::script s (state);

  s.declare (new module_script);
  
  s.declare (new SugiyamaLayout_script);
  
  s.declare (new LongestPathRanking_script);
  s.declare (new OptimalRanking_script);
  s.declare (new CoffmanGrahamRanking_script);

  s.declare (new DfsAcyclicSubgraph_script);
  s.declare (new GreedyCycleRemoval_script);
  
  s.declare (new BarycenterHeuristic_script);
  s.declare (new GreedyInsertHeuristic_script);
  s.declare (new SiftingHeuristic_script);
  s.declare (new MedianHeuristic_script);
  s.declare (new SplitHeuristic_script);
  
  s.declare (new FastHierarchyLayout_script);
  s.declare (new FastSimpleHierarchyLayout_script);
  
  return 0;
}

