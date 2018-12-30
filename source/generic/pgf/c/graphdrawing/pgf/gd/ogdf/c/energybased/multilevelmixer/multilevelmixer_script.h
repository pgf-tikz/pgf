#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>

#include "BarycenterPlacer_script.h"
#include "IndependentSetMerger_script.h"
#include "MedianPlacer_script.h"
#include "SolarMerger_script.h"
#include "CirclePlacer_script.h"
#include "LocalBiconnectedMerger_script.h"
#include "RandomMerger_script.h"
#include "SolarPlacer_script.h"
#include "EdgeCoverMerger_script.h"
#include "MatchingMerger_script.h"
#include "RandomPlacer_script.h"
#include "ZeroPlacer_script.h"

struct multilevelmixer_script :
  scripting::declarations
{
  void declare (scripting::script s) {
    s.declare (new BarycenterPlacer_script);
    s.declare (new IndependentSetMerger_script);
    s.declare (new MedianPlacer_script);
    s.declare (new SolarMerger_script);
    s.declare (new CirclePlacer_script);
    s.declare (new LocalBiconnectedMerger_script);
    s.declare (new RandomMerger_script);
    s.declare (new SolarPlacer_script);
    s.declare (new EdgeCoverMerger_script);
    s.declare (new MatchingMerger_script);
    s.declare (new RandomPlacer_script);
    s.declare (new ZeroPlacer_script);
  }
};
