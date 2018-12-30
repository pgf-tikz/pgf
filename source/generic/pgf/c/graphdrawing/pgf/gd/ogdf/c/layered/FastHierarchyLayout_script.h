#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/FastHierarchyLayout.h>

struct FastHierarchyLayout_script :
  scripting::declarations,
  scripting::factory<ogdf::FastHierarchyLayout>
{
  
  ogdf::FastHierarchyLayout* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    FastHierarchyLayout* r = new FastHierarchyLayout;
    
    parameters->configure_option ("FastHierarchyLayout.fixedLayerDistance",
				  &FastHierarchyLayout::fixedLayerDistance, *r);
    parameters->configure_option ("FastHierarchyLayout.layerDistance",
				  &FastHierarchyLayout::layerDistance, *r);
    parameters->configure_option ("FastHierarchyLayout.nodeDistance",
				  &FastHierarchyLayout::nodeDistance, *r);
    
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;
    
    s.declare (key ("FastHierarchyLayout")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.FastHierarchyLayout")
	       .set_module ("HierarchyLayoutModule", this));

    s.declare (key ("FastHierarchyLayout.fixedLayerDistance")
	       .type ("boolean")
	       .initial ("false")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.FastHierarchyLayout"));

    s.declare (key ("FastHierarchyLayout.layerDistance")
	       .type ("length")
	       .alias_function ("function (o) return o['level pre sep'] + o['level post sep'] end")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.FastHierarchyLayout"));

    s.declare (key ("FastHierarchyLayout.nodeDistance")
	       .type ("length")
	       .alias_function ("function (o) return o['sibling pre sep'] + o['sibling post sep'] end")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.FastHierarchyLayout"));
  }
};


