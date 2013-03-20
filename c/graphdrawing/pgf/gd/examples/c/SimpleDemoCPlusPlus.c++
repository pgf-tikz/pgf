#include <pgf/gd/interface/c/InterfaceFromC++.h>
#include <pgf/gd/interface/c/InterfaceFromC.h>

#include <math.h>


struct FastLayout : scripting::declarations, scripting::runner {
  
  void run () {
    pgfgd_SyntacticDigraph* graph = parameters->syntactic_digraph;
    
    double angle  = 6.28318530718 / graph->vertices.length;
    double radius = parameters->option<double>("fast simple demo radius c++");

    for (int i = 0; i < graph->vertices.length; i++) {
      pgfgd_Vertex* v = graph->vertices.array[i];
      v->pos.x = cos(angle*i) * radius;
      v->pos.y = sin(angle*i) * radius;
    }
  }
  
  void declare(scripting::script s) {
    using namespace scripting;

    s.declare(key ("fast simple demo layout c++")
	      .summary ("The C++ version of the hello world of graph drawing")
	      .precondition ("connected")
	      .precondition ("tree")
	      .algorithm (this));
    
    s.declare(key ("fast simple demo radius c++")
	      .summary ("A radius value for the hello world of graph drawing")
	      .type ("length")
	      .initial ("1cm"));
  }
  
};

extern "C" int luaopen_pgf_gd_examples_c_SimpleDemoCPlusPlus (struct lua_State *state) {

  scripting::script s (state);

  s.declare (new FastLayout);
   
  return 0;
}

