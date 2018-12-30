#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/MedianPlacer.h>

struct MedianPlacer_script :
  scripting::declarations,
  scripting::factory<ogdf::MedianPlacer>
{
  ogdf::MedianPlacer* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    MedianPlacer* r = new MedianPlacer;

          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("MedianPlacer")
               .set_module ("InitialPlacer", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.MedianPlacer"));

  }
  
};
