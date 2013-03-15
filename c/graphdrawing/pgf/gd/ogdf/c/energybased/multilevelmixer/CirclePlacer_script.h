#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/CirclePlacer.h>

struct CirclePlacer_script :
  scripting::declarations,
  scripting::factory<ogdf::CirclePlacer>
{
  ogdf::CirclePlacer* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    CirclePlacer* r = new CirclePlacer;

    parameters->configure_option ("CirclePlacer.circleSize",
                                  &CirclePlacer::setCircleSize, *r);
    parameters->configure_option ("CirclePlacer.radiusFixed",
                                  &CirclePlacer::setRadiusFixed, *r);


    char* s = 0;
    
    if (parameters->option("CirclePlacer.nodeSelection", s)) {
      if (strcmp(s, "new") == 0)
	r->setNodeSelection(CirclePlacer::nsNew);
      else if (strcmp(s, "old") == 0)
	r->setNodeSelection(CirclePlacer::nsOld);
      else if (strcmp(s, "all") == 0)
	r->setNodeSelection(CirclePlacer::nsAll);

      free(s);
    }
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("CirclePlacer")
               .set_module ("InitialPlacer", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.CirclePlacer"));

    s.declare (key ("CirclePlacer.circleSize")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.CirclePlacer"));
                    
    s.declare (key ("CirclePlacer.radiusFixed")
               .type ("boolean")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.CirclePlacer"));
                    
    s.declare (key ("CirclePlacer.nodeSelection")
               .type ("string")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.CirclePlacer"));
                    
  }
  
};
