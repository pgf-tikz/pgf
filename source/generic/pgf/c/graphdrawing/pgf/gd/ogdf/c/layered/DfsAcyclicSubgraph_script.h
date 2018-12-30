#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
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
	       .documentation_in ("pgf.gd.doc.ogdf.layered.DfsAcyclicSubgraph")
	       .set_module ("AcyclicSubgraphModule", this));
  }
};

