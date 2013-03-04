#include <pgf/gd/interface/c/InterfaceFromOGDF.h>
#include <ogdf/layered/DfsAcyclicSubgraph.h>

struct DfsAcyclicSubgraph_script :
  scripting::declarations,
  scripting::factory<ogdf::DfsAcyclicSubgraph>
{
  
  ogdf::DfsAcyclicSubgraph* make (scripting::run_parameters* parameters) {
    return new ogdf::DfsAcyclicSubgraph;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    s.declare (key ("DfsAcyclicSubgraph")
	       .documentation_in ("pgf.gd.ogdf.layered.documentation")
	       .set_module ("AcyclicSubgraphModule", this));
  }
};

