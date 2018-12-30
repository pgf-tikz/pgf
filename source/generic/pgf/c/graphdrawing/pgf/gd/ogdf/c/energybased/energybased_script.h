#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>

#include "FMMMLayout_script.h"
#include "GEMLayout_script.h"
#include "FastMultipoleEmbedder_script.h"

#include "SpringEmbedderFR_script.h"
#include "SpringEmbedderFRExact_script.h"
#include "SpringEmbedderKK_script.h"

#include "MultilevelLayout_script.h"

#include "multilevelmixer/multilevelmixer_script.h"

struct energybased_script :
  scripting::declarations
{
  void declare (scripting::script s) {
    s.declare (new FMMMLayout_script);
    s.declare (new GEMLayout_script);
    s.declare (new FastMultipoleEmbedder_script);
    
    s.declare (new SpringEmbedderFR_script);
    s.declare (new SpringEmbedderFRExact_script);
    s.declare (new SpringEmbedderKK_script);

    s.declare (new MultilevelLayout_script);

    s.declare (new multilevelmixer_script);
  }
};
