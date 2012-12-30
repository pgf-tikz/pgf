#include <lauxlib.h>
#include <math.h>
#include <stdio.h>

static int fast_hello_world (lua_State *L) {

  // First, get number of vertices:
  lua_getfield(L, 1, "vertices_for_c");
  int n = lua_objlen(L, -1);
  double angle = 6.28318530718 / n;
  
  // Get the to-be-filled arrays
  lua_getfield(L, 2, "vertex_indices");
  lua_getfield(L, 2, "x");
  lua_getfield(L, 2, "y");
  
  int i;
  for (i = 1; i <= n; i++) {// set the positions
    // vertex_indices[i] = i
    lua_pushinteger(L, i);
    lua_rawseti(L, -4, i);
    
    // x[i] = cos(angle*i)
    lua_pushnumber(L, cos(angle*i) * 30);
    lua_rawseti(L, -3, i);

    // y[i] = sin(angle*i)
    lua_pushnumber(L, sin(angle*i) * 30);
    lua_rawseti(L, -2, i);
  }
  return 0;
}

static const struct luaL_reg registry [] = {
  {"fast_hello_world", fast_hello_world},
  {NULL, NULL}  // sentinel
};

int luaopen_pgf_gd_examples_c_FastSimpleDemo (lua_State *L) {
  luaL_register(L, "pgf.gd.examples.c.FastSimpleDemo", registry);
  return 1;
}
