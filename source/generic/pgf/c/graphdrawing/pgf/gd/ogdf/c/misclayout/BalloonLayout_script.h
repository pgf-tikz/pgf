#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/misclayout/BalloonLayout.h>

struct BalloonLayout_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  void run () {
    using namespace ogdf;
    BalloonLayout layout;
    
    parameters->configure_option ("BalloonLayout.evenAngles",
				  &BalloonLayout::setEvenAngles, layout);
    
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    
    s.declare (key ("BalloonLayout")
	       .precondition ("connected")
	       .algorithm (this)
	       .documentation_in ("pgf.gd.doc.ogdf.misclayout.BalloonLayout"));

    s.declare (key ("BalloonLayout.evenAngles")
	       .type ("boolean")
	       .documentation_in ("pgf.gd.doc.ogdf.misclayout.BalloonLayout"));
  }
};

