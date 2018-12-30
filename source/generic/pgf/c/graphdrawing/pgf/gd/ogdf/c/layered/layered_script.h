#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>

#include "SugiyamaLayout_script.h"

#include "LongestPathRanking_script.h"
#include "OptimalRanking_script.h"
#include "CoffmanGrahamRanking_script.h"

#include "DfsAcyclicSubgraph_script.h"
#include "GreedyCycleRemoval_script.h"

#include "BarycenterHeuristic_script.h"
#include "GreedyInsertHeuristic_script.h"
#include "SiftingHeuristic_script.h"
#include "MedianHeuristic_script.h"
#include "SplitHeuristic_script.h"

#include "FastHierarchyLayout_script.h"
#include "FastSimpleHierarchyLayout_script.h"

struct layered_script :
  scripting::declarations
{
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

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
  }
};
