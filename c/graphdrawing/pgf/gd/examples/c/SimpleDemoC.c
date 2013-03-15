#include <pgf/gd/interface/c/InterfaceFromC.h>
#include <math.h>

static void fast_hello_world (pgfgd_SyntacticDigraph* graph, void* v) {
  double angle  = 6.28318530718 / graph->vertices.length;
  double radius = pgfgd_tonumber(graph->options, "fast simple demo radius");
  
  int i;
  for (i = 0; i < graph->vertices.length; i++) {
    pgfgd_Vertex* v = graph->vertices.array[i];
    v->pos.x = cos(angle*i) * radius;
    v->pos.y = sin(angle*i) * radius;
  }
}

int luaopen_pgf_gd_examples_c_SimpleDemoC (struct lua_State *state) {
  pgfgd_Declaration* d;

  // The main layout key
  d = pgfgd_new_key ("fast simple demo layout");
  pgfgd_key_summary          (d, "The C version of the hello world of graph drawing.");
  pgfgd_key_algorithm        (d, fast_hello_world, 0);
  pgfgd_key_documentation    (d, 
    "Just like the |SimpleDemo| algorithm, this algorithm arranges \
     the nodes of a graph in a circle (without paying heed to the sizes of the \
     nodes or to the edges). Its main purpose is to show how C code	\
     can access the Lua representation of graphs. See \
     Section~\ref{section-algorithms-in-c} of the manual for detais.");
  pgfgd_key_add_precondition (d, "connected");
  pgfgd_declare              (state, d);
  pgfgd_free_key             (d);

  // The radius key
  d = pgfgd_new_key ("fast simple demo radius");
  pgfgd_key_summary (d, "A radius value for the hello world of graph drawing");
  pgfgd_key_type    (d, "length");
  pgfgd_key_initial (d, "1cm");
  pgfgd_declare     (state, d);
  pgfgd_free_key    (d);
  
  return 0;
}
