#include <pgf/gd/interface/c/InterfaceFromOGDF.h>

#include "FMMMLayout_script.h"

struct energybased_script :
  scripting::declarations
{
  void declare (scripting::script s) {
    s.declare (new FMMMLayout_script);
  }
};
