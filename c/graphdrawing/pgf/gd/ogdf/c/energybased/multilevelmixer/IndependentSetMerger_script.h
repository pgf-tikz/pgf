#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/IndependentSetMerger.h>

struct IndependentSetMerger_script :
  scripting::declarations,
  scripting::factory<ogdf::IndependentSetMerger>
{
  ogdf::IndependentSetMerger* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    IndependentSetMerger* r = new IndependentSetMerger;

    parameters->configure_option ("IndependentSetMerger.searchDepthBase",
                                  &IndependentSetMerger::setSearchDepthBase, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("IndependentSetMerger")
               .set_module ("MultilevelBuilder", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.IndependentSetMerger"));

    s.declare (key ("IndependentSetMerger.searchDepthBase")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.IndependentSetMerger"));
                    
  }
  
};
