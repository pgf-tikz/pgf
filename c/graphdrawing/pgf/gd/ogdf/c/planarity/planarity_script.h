#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>

#include "PlanarizationLayout_script.h"

struct planarity_script :
  scripting::declarations
{
  void declare (scripting::script s) {
    s.declare (new PlanarizationLayout_script);
  }
};
