#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/GreedyCycleRemoval.h>

struct GreedyCycleRemoval_script :
  scripting::declarations,
  scripting::factory<ogdf::GreedyCycleRemoval>
{
  
  ogdf::GreedyCycleRemoval* make (scripting::run_parameters* parameters) {
    return new ogdf::GreedyCycleRemoval;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    s.declare (key ("GreedyCycleRemoval")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.GreedyCycleRemoval")
	       .set_module ("AcyclicSubgraphModule", this));
  }
};

