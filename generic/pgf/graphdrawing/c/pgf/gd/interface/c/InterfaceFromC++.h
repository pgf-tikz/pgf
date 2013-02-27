#ifndef PGF_GD_INTERFACE_C_INTERFACEFROMCPP_H
#define PGF_GD_INTERFACE_C_INTERFACEFROMCPP_H

/** \file pgf/gd/interface/c/InterfaceFromC++.h

    The C++-header file that should be used by algorithms written
    in C++ for graph drawing in Lua.
*/


struct lua_State;
struct pgfgd_Declaration;


namespace pgf
{
  namespace gd {
    
    struct Option {
      Option (const char* key);
      ~Option ();
      pgfgd_Declaration* d;
    };

    struct initial {
      initial (const char*);
      const char* str;
    };

    struct type {
      type (const char*);
      const char* str;
    };
    
    Option& operator << (Option&, const initial&);
    Option& operator << (Option&, const type&);

    
    class Script {
      
    public:

      Script (struct lua_State*);

      void declare (const Option& k);

    private:

      struct lua_State* state;
      
    };
    
  }
}


#endif
