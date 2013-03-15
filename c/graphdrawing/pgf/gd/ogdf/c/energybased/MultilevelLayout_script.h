#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/MultilevelLayout.h>

struct MultilevelLayout_script :
  scripting::declarations,
  scripting::ogdf_runner
{
  void run () {
    using namespace ogdf;
    MultilevelLayout layout;

    parameters->configure_module ("LayoutModule",
                                  &MultilevelLayout::setLayout, layout);
    parameters->configure_module ("MultilevelBuilder",
                                  &MultilevelLayout::setMultilevelBuilder, layout);
    parameters->configure_module ("InitialPlacer",
                                  &MultilevelLayout::setPlacer, layout);
          
    layout.call (graph_attributes);
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("MultilevelLayout")
               .precondition ("connected")
               .algorithm (this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.MultilevelLayout"));

  }
  
};
