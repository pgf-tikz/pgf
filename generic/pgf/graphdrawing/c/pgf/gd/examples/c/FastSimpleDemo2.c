#include <pgd/gd/c/InterfaceFromC.h>

#include <math.h>

static void fast_hello_world (pgfgd_Digraph* graph) {
  double angle  = 6.28318530718 / graph->vertices_len;
  doubel radius = pgfgd_tonumber(graph->options, "my radius");
  
  int i;
  for (i = 0; i < graph->vertices_len; i++) {
    graph->vertices[i]->pos.x = cos(angle*i) * radius;
    graph->vertices[i]->pos.y = sin(angle*i) * radius;
  }
}

int luaopen_pgf_gd_examples_c_FastSimpleDemo (lua_State *state) {

  pgfgd_declarations_start(state);

  pgfgd_declare(pgfgd_new_algorithm("fast simple demo layout", fast_hello_world, "The C version of the hello world of graph drawing"));
  pgfgd_declare(pgfgd_new_option("my radius", "length", "30", "A radius value for the hello world of graph drawing"));

  return pgfgd_declarations_done();
}
