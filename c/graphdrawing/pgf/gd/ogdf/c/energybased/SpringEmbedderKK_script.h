#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/SpringEmbedderKK.h>

struct SpringEmbedderKK_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  void run () {
    using namespace ogdf;
    SpringEmbedderKK layout;

    parameters->configure_option ("SpringEmbedderKK.stopTolerance",
                                  &SpringEmbedderKK::setStopTolerance, layout);
    parameters->configure_option ("SpringEmbedderKK.desLength",
                                  &SpringEmbedderKK::setDesLength, layout);
          
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("SpringEmbedderKK")
               .precondition ("connected")
               .algorithm (this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderKK"));

    s.declare (key ("SpringEmbedderKK.stopTolerance")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderKK"));
                    
    s.declare (key ("SpringEmbedderKK.desLength")
               .type ("length")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderKK"));
                    
  }
  
};
