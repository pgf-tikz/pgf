#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/multilevelmixer/SolarMerger.h>

struct SolarMerger_script :
  scripting::declarations,
  scripting::factory<ogdf::SolarMerger>
{
  ogdf::SolarMerger* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    SolarMerger* r = new SolarMerger (parameters->option<bool>("SolarMerger.simple"), 
				      parameters->option<bool>("SolarMerger.massAsNodeRadius"));
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("SolarMerger")
               .set_module ("MultilevelBuilder", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.SolarMerger"));

    s.declare (key ("SolarMerger.simple")
               .type ("boolean")
	       .initial ("false")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.SolarMerger"));
                    
    s.declare (key ("SolarMerger.massAsNodeRadius")
               .type ("boolean")
	       .initial ("false")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.multilevelmixer.SolarMerger"));
                    
  }
  
};
