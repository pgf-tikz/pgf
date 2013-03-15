#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/CoffmanGrahamRanking.h>

struct CoffmanGrahamRanking_script :
  scripting::declarations,
  scripting::factory<ogdf::CoffmanGrahamRanking>
{
  
  ogdf::CoffmanGrahamRanking* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    CoffmanGrahamRanking* r = new CoffmanGrahamRanking;
    
    parameters->configure_option ("CoffmanGrahamRanking.width",
				  &CoffmanGrahamRanking::width, *r);
    parameters->configure_module ("AcyclicSubgraphModule",
				  &CoffmanGrahamRanking::setSubgraph, *r);
    
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    s.declare (key ("CoffmanGrahamRanking")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.CoffmanGrahamRanking")
	       .set_module ("RankingModule", this));

    s.declare (key ("CoffmanGrahamRanking.width")
	       .type ("number")
	       .initial ("3")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.CoffmanGrahamRanking"));
  }
};

