#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/SiftingHeuristic.h>

struct SiftingHeuristic_script :
  scripting::declarations,
  scripting::factory<ogdf::SiftingHeuristic>
{
  
  ogdf::SiftingHeuristic* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    
    SiftingHeuristic* h = new SiftingHeuristic;

    char* strategy = 0;
    
    if (parameters->option("SiftingHeuristic.strategy", strategy)) {
      if (strcmp(strategy, "left_to_right") == 0)
	h->strategy(SiftingHeuristic::left_to_right);
      else if (strcmp(strategy, "desc_degree") == 0)
	h->strategy(SiftingHeuristic::desc_degree);
      else if (strcmp(strategy, "random") == 0)
	h->strategy(SiftingHeuristic::random);

      free(strategy);
    }
    return h;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    s.declare (key ("SiftingHeuristic")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.SiftingHeuristic")
	       .set_module ("TwoLayerCrossMin", this));

    s.declare (key ("SiftingHeuristic.strategy")
	       .type ("string")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.SiftingHeuristic"));
  }
};

