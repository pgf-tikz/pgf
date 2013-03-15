#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/MatchingMerger.h>

struct MatchingMerger_script :
  scripting::declarations,
  scripting::factory<ogdf::MatchingMerger>
{
  ogdf::MatchingMerger* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    MatchingMerger* r = new MatchingMerger;

    parameters->configure_option ("MatchingMerger.selectByNodeMass",
                                  &MatchingMerger::selectByNodeMass, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("MatchingMerger")
               .set_module ("MultilevelBuilder", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.MatchingMerger"));

    s.declare (key ("MatchingMerger.selectByNodeMass")
               .type ("boolean")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.MatchingMerger"));
                    
  }
  
};
