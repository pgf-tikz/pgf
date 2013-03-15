#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/RandomMerger.h>

struct RandomMerger_script :
  scripting::declarations,
  scripting::factory<ogdf::RandomMerger>
{
  ogdf::RandomMerger* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    RandomMerger* r = new RandomMerger;

    parameters->configure_option ("RandomMerger.factor",
                                  &RandomMerger::setFactor, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("RandomMerger")
               .set_module ("MultilevelBuilder", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.RandomMerger"));

    s.declare (key ("RandomMerger.factor")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.RandomMerger"));
                    
  }
  
};
