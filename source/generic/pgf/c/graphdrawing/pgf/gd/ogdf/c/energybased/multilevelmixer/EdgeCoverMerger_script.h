#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/EdgeCoverMerger.h>

struct EdgeCoverMerger_script :
  scripting::declarations,
  scripting::factory<ogdf::EdgeCoverMerger>
{
  ogdf::EdgeCoverMerger* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    EdgeCoverMerger* r = new EdgeCoverMerger;

    parameters->configure_option ("EdgeCoverMerger.factor",
                                  &EdgeCoverMerger::setFactor, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("EdgeCoverMerger")
               .set_module ("MultilevelBuilder", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.EdgeCoverMerger"));

    s.declare (key ("EdgeCoverMerger.factor")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.EdgeCoverMerger"));
                    
  }
  
};
