#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/planarity/PlanarizationLayout.h>

struct PlanarizationLayout_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  
  void run () {
    using namespace ogdf;
    PlanarizationLayout layout;
    
    parameters->configure_option ("PlanarizationLayout.preprocessCliques",
				  &PlanarizationLayout::preprocessCliques, layout);
    parameters->configure_option ("PlanarizationLayout.minCliqueSize",
				  &PlanarizationLayout::minCliqueSize, layout);

    // .. TODO: configure modules
    
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    s.declare (key ("PlanarizationLayout")
	       .precondition ("connected")
	       .postcondition ("fixed")
	       .algorithm (this)
	       .documentation_in ("pgf.gd.doc.ogdf.planarity.PlanarizationLayout"));

    s.declare (key ("PlanarizationLayout.preprocessCliques")
	       .type ("boolean")
	       .initial ("false")
	       .documentation_in ("pgf.gd.doc.ogdf.planarity.PlanarizationLayout"));
    
    s.declare (key ("PlanarizationLayout.minCliqueSize")
	       .type ("number") 
	       .initial ("10")
	       .documentation_in ("pgf.gd.doc.ogdf.planarity.PlanarizationLayout"));
  }
  
};
