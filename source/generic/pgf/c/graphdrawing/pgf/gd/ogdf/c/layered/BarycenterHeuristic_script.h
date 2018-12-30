#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/BarycenterHeuristic.h>

struct BarycenterHeuristic_script :
  scripting::declarations,
  scripting::factory<ogdf::BarycenterHeuristic>
{
  
  ogdf::BarycenterHeuristic* make (scripting::run_parameters* parameters) {
    return new ogdf::BarycenterHeuristic;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    s.declare (key ("BarycenterHeuristic")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.BarycenterHeuristic")
	       .set_module ("TwoLayerCrossMin", this));
  }
};

