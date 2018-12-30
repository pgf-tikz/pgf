#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/SolarPlacer.h>

struct SolarPlacer_script :
  scripting::declarations,
  scripting::factory<ogdf::SolarPlacer>
{
  ogdf::SolarPlacer* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    SolarPlacer* r = new SolarPlacer;

          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("SolarPlacer")
               .set_module ("InitialPlacer", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.SolarPlacer"));

  }
  
};
