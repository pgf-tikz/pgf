#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/RandomPlacer.h>

struct RandomPlacer_script :
  scripting::declarations,
  scripting::factory<ogdf::RandomPlacer>
{
  ogdf::RandomPlacer* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    RandomPlacer* r = new RandomPlacer;

    parameters->configure_option ("RandomPlacer.circleSize",
                                  &RandomPlacer::setCircleSize, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("RandomPlacer")
               .set_module ("InitialPlacer", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.RandomPlacer"));

    s.declare (key ("RandomPlacer.circleSize")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.RandomPlacer"));
                    
  }
  
};
