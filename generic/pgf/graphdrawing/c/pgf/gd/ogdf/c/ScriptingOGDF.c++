#include <pgf/gd/interface/c/InterfaceFromOGDF.h>

#include <ogdf/layered/SugiyamaLayout.h>
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
	       .summary ("The longest-path ranking algorithm.")
	       .documentation ("\
                   |LongestPathRanking| implements the well-known longest-path \
                   ranking algorithm, which can be used as first phase in \
                   |SugiyamaLayout|. The implementation contains a special \
                   optimization for reducing edge lengths, as well as special \
                   treatment of mixed-upward graphs (for instance, \textsc{uml} \
                   class diagrams).")
	       .set_module ("RankingModule", this));

    s.declare (key ("LongestPathRanking.separateDeg0Layer")
	       .type ("boolean")
	       .initial ("true")
	       .summary ("If set to true, isolated nodes are placed on a separate layer."));

    s.declare (key ("LongestPathRanking.separateMultiEdges")
	       .type ("boolean")
	       .initial ("true")
	       .summary ("If set to true, multi-edges will span at least two layers."));

    s.declare (key ("LongestPathRanking.optimizeEdgeLength")
	       .type ("boolean")
	       .initial ("true")
	       .summary ("If set to true the ranking algorithm tries to reduce\
                   edge length even if this might increase the height of the\
                   layout. Choose false, if the longest-path ranking known from the\
                   literature should be used."));
  }
};



struct RankingModule_script : scripting::declarations {
  void declare (scripting::script s)
  {
    using namespace scripting;
    s.declare (key ("RankingModule")
	       .module_type ()
	       .initial (new LongestPathRanking_script));	       
  }
};


struct SugiyamaLayout_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  void run () {
    using namespace ogdf;
    SugiyamaLayout layout;
    
    parameters->configure_option ("SugiyamaLayout.runs",
				  &SugiyamaLayout::runs, layout);
    parameters->configure_option ("SugiyamaLayout.transpose",
				  &SugiyamaLayout::transpose, layout);
    
    parameters->configure_module ("RankingModule",
				  &SugiyamaLayout::setRanking, layout);
    
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    s.declare (key ("SugiyamaLayout")
	       .summary ("The OGDF implementation of the Sugiyama method")
	       .precondition ("connected")
	       .postcondition ("upward_oriented_swapped")
	       .algorithm (this));

    s.declare (key ("SugiyamaLayout.runs")
	       .summary ("Determines, how many times the crossing minimization is repeated.")
	       .type ("number")
	       .initial ("15")
	       .documentation ("Each repetition (except for the first) starts with \
                    randomly permuted nodes on each layer. Deterministic behaviour can \
                    be achieved by setting |SugiyamaLayout.runs| to 1."));
    
    s.declare (key ("SugiyamaLayout.transpose")
	       .type ("boolean") 
	       .initial ("true") 
	       .summary ("Determines whether the transpose step is performed \
                    after each 2-layer crossing minimization; this step tries to \
                    reduce the number of crossings by switching neighbored nodes on \
                    a layer."));
  }
};


extern "C" int luaopen_pgf_gd_ogdf_c_ScriptingOGDF (struct lua_State *state) {
  
  scripting::script s (state);

  s.declare (new SugiyamaLayout_script);
  s.declare (new RankingModule_script);
  s.declare (new LongestPathRanking_script);
  
  return 0;
}

