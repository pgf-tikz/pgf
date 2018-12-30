#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/FMMMLayout.h>

struct FMMMLayout_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  void run () {
    using namespace ogdf;
    FMMMLayout layout;
    
    layout.newInitialPlacement(false);
    layout.qualityVersusSpeed(FMMMLayout::qvsGorgeousAndEfficient);
    
    parameters->configure_option ("FMMMLayout.unitEdgeLength",
				  &FMMMLayout::unitEdgeLength, layout);
    parameters->configure_option ("FMMMLayout.randSeed",
				  &FMMMLayout::randSeed, layout);
	  
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    s.declare (key ("FMMMLayout")
	       .precondition ("connected")
	       .algorithm (this)
	       .documentation_in ("pgf.gd.doc.ogdf.energybased.FMMMLayout"));

    s.declare (key ("FMMMLayout.randSeed")
	       .type ("number")
	       .initial ("42")
	       .alias ("random seed")
	       .documentation_in ("pgf.gd.doc.ogdf.energybased.FMMMLayout"));
    
    s.declare (key ("FMMMLayout.unitEdgeLength")
	       .type ("length") 
	       .initial ("1cm")
	       .alias_function ("function (o) return o['node pre sep'] + o['node post sep'] end")
	       .documentation_in ("pgf.gd.doc.ogdf.energybased.FMMMLayout"));
  }
  
};
