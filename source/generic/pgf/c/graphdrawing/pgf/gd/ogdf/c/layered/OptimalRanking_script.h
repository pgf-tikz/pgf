#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/OptimalRanking.h>

struct OptimalRanking_script :
  scripting::declarations,
  scripting::factory<ogdf::OptimalRanking>
{
  
  ogdf::OptimalRanking* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    OptimalRanking* r = new OptimalRanking;
    
    parameters->configure_option ("OptimalRanking.separateMultiEdges",
				  &OptimalRanking::separateMultiEdges, *r);
    parameters->configure_module ("AcyclicSubgraphModule",
				  &OptimalRanking::setSubgraph, *r);
    
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    s.declare (key ("OptimalRanking")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.OptimalRanking")
	       .set_module ("RankingModule", this));

    s.declare (key ("OptimalRanking.separateMultiEdges")
	       .type ("boolean")
	       .initial ("true")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.OptimalRanking"));
  }
};

