
// Own header:
#include <pgf/gd/interface/c/InterfaceFromC++.h>

// Own C header:
#include <pgf/gd/interface/c/InterfaceFromC.h>

// Lua stuff:
#include <lauxlib.h>


using namespace pgf::gd;

Option::Option(const char* key)
{
  d = pgfgd_new_key(key);
}

Option::~Option()
{
  pgfgd_free_key(d);
}


initial::initial (const char* s) : str(s) {}
type::type       (const char* s) : str(s) {}

Option& operator << (Option& o, const initial& x)
{
  pgfgd_key_initial(o.d, x.str);
  return o;
}

Option& operator << (Option& o, const type& x)
{
  pgfgd_key_type(o.d, x.str);
  return o;
}
    
    
