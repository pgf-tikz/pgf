#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/layered/FastSimpleHierarchyLayout.h>

struct FastSimpleHierarchyLayout_script :
  scripting::declarations,
  scripting::factory<ogdf::FastSimpleHierarchyLayout>
{
  
  ogdf::FastSimpleHierarchyLayout* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    
    FastSimpleHierarchyLayout* r = new FastSimpleHierarchyLayout
      (
       parameters->option<int> ("FastSimpleHierarchyLayout.siblingDistance"),
       parameters->option<int> ("FastSimpleHierarchyLayout.layerDistance")
      );
    
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("FastSimpleHierarchyLayout")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.FastSimpleHierarchyLayout")
	       .set_module ("HierarchyLayoutModule", this));

    s.declare (key ("FastSimpleHierarchyLayout.layerDistance")
	       .type ("length")
	       .alias ("level distance")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.FastSimpleHierarchyLayout"));

    s.declare (key ("FastSimpleHierarchyLayout.siblingDistance")
	       .type ("length")
	       .alias ("sibling distance")
	       .documentation_in ("pgf.gd.doc.ogdf.layered.FastSimpleHierarchyLayout"));
  }
};


