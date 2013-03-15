#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/FastMultipoleEmbedder.h>

struct FastMultipoleEmbedder_script :
  scripting::declarations,
  scripting::factory<ogdf::FastMultipoleEmbedder>
{
  ogdf::FastMultipoleEmbedder* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    FastMultipoleEmbedder* r = new FastMultipoleEmbedder;

    parameters->configure_option ("FastMultipoleEmbedder.numIterations",
                                  &FastMultipoleEmbedder::setNumIterations, *r);
    parameters->configure_option ("FastMultipoleEmbedder.multipolePrec",
                                  &FastMultipoleEmbedder::setMultipolePrec, *r);
    parameters->configure_option ("FastMultipoleEmbedder.defaultEdgeLength",
                                  &FastMultipoleEmbedder::setDefaultEdgeLength, *r);
    parameters->configure_option ("FastMultipoleEmbedder.defaultNodeSize",
                                  &FastMultipoleEmbedder::setDefaultNodeSize, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("FastMultipoleEmbedder")
               .set_module ("LayoutModule", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.FastMultipoleEmbedder"));

    s.declare (key ("FastMultipoleEmbedder.numIterations")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.FastMultipoleEmbedder"));
                    
    s.declare (key ("FastMultipoleEmbedder.multipolePrec")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.FastMultipoleEmbedder"));
                    
    s.declare (key ("FastMultipoleEmbedder.defaultEdgeLength")
               .type ("length")
               .alias_function ("function (o) return o['node pre sep'] + o['node post sep'] end")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.FastMultipoleEmbedder"));
                    
    s.declare (key ("FastMultipoleEmbedder.defaultNodeSize")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.FastMultipoleEmbedder"));
                    
  }
  
};
