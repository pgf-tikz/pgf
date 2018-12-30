#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/BarycenterPlacer.h>

struct BarycenterPlacer_script :
  scripting::declarations,
  scripting::factory<ogdf::BarycenterPlacer>
{
  ogdf::BarycenterPlacer* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    BarycenterPlacer* r = new BarycenterPlacer;

    parameters->configure_option ("BarycenterPlacer.weightedPositionPriority",
                                  &BarycenterPlacer::weightedPositionPriority, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("BarycenterPlacer")
               .set_module ("InitialPlacer", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.BarycenterPlacer"));

    s.declare (key ("BarycenterPlacer.weightedPositionPriority")
               .type ("boolean")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.BarycenterPlacer"));
                    
  }
  
};
