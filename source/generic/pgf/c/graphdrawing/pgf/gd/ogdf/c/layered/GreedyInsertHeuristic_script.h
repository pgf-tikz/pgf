#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/GreedyInsertHeuristic.h>

struct GreedyInsertHeuristic_script :
  scripting::declarations,
  scripting::factory<ogdf::GreedyInsertHeuristic>
{
  
  ogdf::GreedyInsertHeuristic* make (scripting::run_parameters* parameters) {
    return new ogdf::GreedyInsertHeuristic;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    s.declare (key ("GreedyInsertHeuristic")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.GreedyInsertHeuristic")
	       .set_module ("TwoLayerCrossMin", this));
  }
};

