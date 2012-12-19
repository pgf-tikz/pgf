#include <pgf/gd/ogdf/c/Declare.h>

#include <vector>

using namespace std;

static void setter (lua_State*L, int t, const char* s, const char* field)
{
  if (s) {
    lua_pushstring(L, s);
    lua_setfield(L, t, field);
  }
}

namespace pgf {

  Parameter::Parameter() :
    key (0),
    type (0),
    initial (0),
    default_value (0),
    summary (0),
    documentation (0),
    examples ()
  {}
  
  void Parameter::declare(lua_State* L)
  {
    // Ok, first, we need access to the declare function:
    lua_getfield(L, LUA_GLOBALSINDEX, "pgf");
    lua_getfield(L, -1, "gd");
    lua_getfield(L, -1, "interface");
    lua_getfield(L, -1, "InterfaceToAlgorithms");
    lua_getfield(L, -1, "declare");
    
    lua_replace(L, -5);
    lua_pop(L, 3);

    // Now, construct the table of entries for the call:
    lua_createtable(L, 0, 7);
    int t = lua_gettop(L);
    
    setter (L, t, this->key, "key");
    setter (L, t, this->type, "type");
    setter (L, t, this->default_value, "default");
    setter (L, t, this->initial, "initial");
    setter (L, t, this->summary, "summary");
    setter (L, t, this->documentation, "documentation");
    
    if (this->examples.size() > 0) {
      lua_createtable(L, this->examples.size(), 0);
      int t_examples = lua_gettop(L);

      int i = 1;
      for (vector<const char*>::iterator it = this->examples.begin();
	   it != this->examples.end();
	   ++it, ++i) {
	lua_pushstring(L, *it);
	lua_rawseti(L, t_examples, i);
      }

      lua_setfield(L, t, "examples");
    }

    lua_call(L, 1, 0);
  }

}
