#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/ZeroPlacer.h>

struct ZeroPlacer_script :
  scripting::declarations,
  scripting::factory<ogdf::ZeroPlacer>
{
  ogdf::ZeroPlacer* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    ZeroPlacer* r = new ZeroPlacer;

    parameters->configure_option ("ZeroPlacer.randomRange",
                                  &ZeroPlacer::setRandomRange, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("ZeroPlacer")
               .set_module ("InitialPlacer", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.ZeroPlacer"));

    s.declare (key ("ZeroPlacer.randomRange")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.ZeroPlacer"));
                    
  }
  
};
