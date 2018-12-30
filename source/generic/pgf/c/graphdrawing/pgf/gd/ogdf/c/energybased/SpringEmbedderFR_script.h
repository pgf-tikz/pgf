#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/SpringEmbedderFR.h>

struct SpringEmbedderFR_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  void run () {
    using namespace ogdf;
    SpringEmbedderFR layout;

    parameters->configure_option ("SpringEmbedderFR.iterations",
                                  &SpringEmbedderFR::iterations, layout);
    parameters->configure_option ("SpringEmbedderFR.noise",
                                  &SpringEmbedderFR::noise, layout);
    parameters->configure_option ("SpringEmbedderFR.scaleFunctionFactor",
                                  &SpringEmbedderFR::scaleFunctionFactor, layout);
          
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("SpringEmbedderFR")
               .precondition ("connected")
               .algorithm (this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFR"));

    s.declare (key ("SpringEmbedderFR.iterations")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFR"));
                    
    s.declare (key ("SpringEmbedderFR.noise")
               .type ("boolean")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFR"));
                    
    s.declare (key ("SpringEmbedderFR.scaleFunctionFactor")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFR"));
                    
  }
  
};
