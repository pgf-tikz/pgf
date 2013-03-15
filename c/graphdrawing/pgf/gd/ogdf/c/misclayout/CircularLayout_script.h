#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/misclayout/CircularLayout.h>

struct CircularLayout_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  void run () {
    using namespace ogdf;
    CircularLayout layout;
    
    parameters->configure_option ("CircularLayout.minDistCircle",
				  &CircularLayout::minDistCircle, layout);
    parameters->configure_option ("CircularLayout.minDistLevel",
				  &CircularLayout::minDistLevel, layout);
    parameters->configure_option ("CircularLayout.minDistSibling",
				  &CircularLayout::minDistSibling, layout);
    
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    
    s.declare (key ("CircularLayout")
	       .precondition ("connected")
	       .algorithm (this)
	       .documentation_in ("pgf.gd.doc.ogdf.misclayout.CircularLayout"));
    
    s.declare (key ("CircularLayout.minDistCircle")
	       .type ("length")
	       .alias_function ("function (o) return o['part pre sep'] + o['part post sep'] end")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.CircularLayout"));

    s.declare (key ("CircularLayout.minDistLevel")
	       .type ("length")
	       .alias_function ("function (o) return o['level pre sep'] + o['level post sep'] end")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.CircularLayout"));

    s.declare (key ("CircularLayout.minDistSibling")
	       .type ("length")
	       .alias_function ("function (o) return o['sibling pre sep'] + o['sibling post sep'] end")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.CircularLayout"));
  }
};

