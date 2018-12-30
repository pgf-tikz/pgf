#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>

struct module_script : scripting::declarations {
  void declare (scripting::script s)
  {
    using namespace scripting;

    s.declare (key ("RankingModule")
	       .module_type ());
    
    s.declare (key ("AcyclicSubgraphModule")
	       .module_type ());

    s.declare (key ("HierarchyLayoutModule")
	       .module_type ());

    s.declare (key ("TwoLayerCrossMin")
	       .module_type ());

    s.declare (key ("InitialPlacer")
	       .module_type ());

    s.declare (key ("MultilevelBuilder")
	       .module_type ());
  }
};

