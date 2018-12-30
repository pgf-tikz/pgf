#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/LocalBiconnectedMerger.h>

struct LocalBiconnectedMerger_script :
  scripting::declarations,
  scripting::factory<ogdf::LocalBiconnectedMerger>
{
  ogdf::LocalBiconnectedMerger* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    LocalBiconnectedMerger* r = new LocalBiconnectedMerger;

    parameters->configure_option ("LocalBiconnectedMerger.factor",
                                  &LocalBiconnectedMerger::setFactor, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("LocalBiconnectedMerger")
               .set_module ("MultilevelBuilder", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.LocalBiconnectedMerger"));

    s.declare (key ("LocalBiconnectedMerger.factor")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.LocalBiconnectedMerger"));
                    
  }
  
};
