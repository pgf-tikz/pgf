#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/MedianHeuristic.h>

struct MedianHeuristic_script :
  scripting::declarations,
  scripting::factory<ogdf::MedianHeuristic>
{
  
  ogdf::MedianHeuristic* make (scripting::run_parameters* parameters) {
    return new ogdf::MedianHeuristic;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    s.declare (key ("MedianHeuristic")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.MedianHeuristic")
	       .set_module ("TwoLayerCrossMin", this));
  }
};

