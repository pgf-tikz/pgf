#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>

#include <math.h>

using namespace ogdf;
using namespace scripting;

struct FastLayoutOGDF : declarations, ogdf_runner {
  
  void run () {
    double angle  = 6.28318530718 / graph.numberOfNodes();
    double radius = parameters->option<double>("my radius ogdf");
    
    int i = 0;
    for (node v = graph.firstNode(); v; v=v->succ(), i++) {
      graph_attributes.x(v) = cos(angle*i) * radius;
      graph_attributes.y(v) = sin(angle*i) * radius;
    }
  }
  
  void declare(script s) {
    using namespace scripting;

    s.declare(key ("fast simple demo layout ogdf")
	      .summary ("The OGDF version of the hello world of graph drawing")
	      .precondition ("connected")
	      .algorithm (this));
    
    s.declare(key ("my radius ogdf")
	      .summary ("A radius value for the hello world of graph drawing")
	      .type ("length")
	      .initial ("1cm"));
  }
  
};

extern "C" int luaopen_pgf_gd_ogdf_c_SimpleDemoOGDF (struct lua_State *state) {

  script (state).declare (new FastLayoutOGDF);
   
  return 0;
}

