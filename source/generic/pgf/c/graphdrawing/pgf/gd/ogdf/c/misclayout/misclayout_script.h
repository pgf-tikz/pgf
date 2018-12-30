#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>

#include "BalloonLayout_script.h"
#include "CircularLayout_script.h"

struct misclayout_script :
  scripting::declarations
{
  void declare (scripting::script s) {
    s.declare (new BalloonLayout_script);
    s.declare (new CircularLayout_script);
  }
};
