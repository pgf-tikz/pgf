#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/SplitHeuristic.h>

struct SplitHeuristic_script :
  scripting::declarations,
  scripting::factory<ogdf::SplitHeuristic>
{
  
  ogdf::SplitHeuristic* make (scripting::run_parameters* parameters) {
    return new ogdf::SplitHeuristic;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    s.declare (key ("SplitHeuristic")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.SplitHeuristic")
	       .set_module ("TwoLayerCrossMin", this));
  }
};

