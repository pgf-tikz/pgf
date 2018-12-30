#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/SpringEmbedderFRExact.h>

struct SpringEmbedderFRExact_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  void run () {
    using namespace ogdf;
    SpringEmbedderFRExact layout;

    parameters->configure_option ("SpringEmbedderFRExact.iterations",
                                  &SpringEmbedderFRExact::iterations, layout);
    parameters->configure_option ("SpringEmbedderFRExact.noise",
                                  &SpringEmbedderFRExact::noise, layout);
    parameters->configure_option ("SpringEmbedderFRExact.idealEdgeLength",
                                  &SpringEmbedderFRExact::idealEdgeLength, layout);
    parameters->configure_option ("SpringEmbedderFRExact.convTolerance",
                                  &SpringEmbedderFRExact::convTolerance, layout);

    char* s = 0;
    
    if (parameters->option("SpringEmbedderFRExact.coolingFunction", s)) {
      if (strcmp(s, "factor") == 0)
	layout.coolingFunction(SpringEmbedderFRExact::cfFactor);
      else if (strcmp(s, "logarithmic") == 0)
	layout.coolingFunction(SpringEmbedderFRExact::cfLogarithmic);

      free(s);
    }
    
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("SpringEmbedderFRExact")
               .precondition ("connected")
               .algorithm (this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFRExact"));

    s.declare (key ("SpringEmbedderFRExact.iterations")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFRExact"));
                    
    s.declare (key ("SpringEmbedderFRExact.noise")
               .type ("boolean")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFRExact"));
                    
    s.declare (key ("SpringEmbedderFRExact.coolingFunction")
               .type ("string")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFRExact"));
                    
    s.declare (key ("SpringEmbedderFRExact.idealEdgeLength")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFRExact"));
                    
    s.declare (key ("SpringEmbedderFRExact.convTolerance")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.SpringEmbedderFRExact"));
                    
  }
  
};
