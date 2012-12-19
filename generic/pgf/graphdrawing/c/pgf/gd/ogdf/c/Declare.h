#ifndef PGF_DECLARE_H
#define PGF_DECLARE_H

extern "C" {
#include <lua.h>
}

#include <vector>

namespace pgf {
  
  struct Parameter {
    
    Parameter ();
    
    const char* key;
    const char* type;
    const char* initial;
    const char* default_value;
    const char* summary;
    const char* documentation;
    std::vector<const char*> examples;
    
    void declare(lua_State* L);
    
  };
  
}

#endif
