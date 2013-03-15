#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/LongestPathRanking.h>

struct LongestPathRanking_script :
  scripting::declarations,
  scripting::factory<ogdf::LongestPathRanking>
{
  
  ogdf::LongestPathRanking* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    LongestPathRanking* r = new LongestPathRanking;

    parameters->configure_option ("LongestPathRanking.separateDeg0Layer",
				  &LongestPathRanking::separateDeg0Layer, *r);
    parameters->configure_option ("LongestPathRanking.separateMultiEdges",
				  &LongestPathRanking::separateMultiEdges, *r);
    parameters->configure_option ("LongestPathRanking.optimizeEdgeLength",
				  &LongestPathRanking::optimizeEdgeLength, *r);

    parameters->configure_module ("AcyclicSubgraphModule",
				  &LongestPathRanking::setSubgraph, *r);
    
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    s.declare (key ("LongestPathRanking")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.LongestPathRanking")
	       .set_module ("RankingModule", this));

    s.declare (key ("LongestPathRanking.separateDeg0Layer")
	       .type ("boolean")
	       .initial ("true")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.LongestPathRanking"));

    s.declare (key ("LongestPathRanking.separateMultiEdges")
	       .type ("boolean")
	       .initial ("true")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.LongestPathRanking"));

    s.declare (key ("LongestPathRanking.optimizeEdgeLength")
	       .type ("boolean")
	       .initial ("true")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.LongestPathRanking"));
  }
};


