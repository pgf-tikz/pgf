#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/SugiyamaLayout.h>

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
    parameters->configure_option ("SugiyamaLayout.fails",
				  &SugiyamaLayout::fails, layout);
    
    parameters->configure_module ("RankingModule",
				  &SugiyamaLayout::setRanking, layout);
    parameters->configure_module ("TwoLayerCrossMin",
				  &SugiyamaLayout::setCrossMin, layout);
    parameters->configure_module ("HierarchyLayoutModule",
				  &SugiyamaLayout::setLayout, layout);
	  
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    s.declare (key ("SugiyamaLayout")
	       .precondition ("connected")
	       .postcondition ("upward_oriented_swapped")
	       .algorithm (this)
	       .documentation_in ("pgf.gd.doc.ogdf.layered.SugiyamaLayout"));

    s.declare (key ("SugiyamaLayout.runs")
	       .type ("number")
	       .initial ("15")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.SugiyamaLayout"));
    
    s.declare (key ("SugiyamaLayout.transpose")
	       .type ("boolean") 
	       .initial ("true") 
	       .documentation_in ("pgf.gd.doc.ogdf.layered.SugiyamaLayout"));
    
    s.declare (key ("SugiyamaLayout.fails")
	       .type ("number") 
	       .initial ("4") 
	       .documentation_in ("pgf.gd.doc.ogdf.layered.SugiyamaLayout"));
  }
  
};
