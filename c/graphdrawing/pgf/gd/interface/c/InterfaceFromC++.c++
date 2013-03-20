
// Own header:
#include <pgf/gd/interface/c/InterfaceFromC++.h>

extern "C" {
  
// Own C header:
#include <pgf/gd/interface/c/InterfaceFromC.h>
  
// Lua stuff:
#include <lauxlib.h>
  
}


namespace {

  void cpp_caller(pgfgd_SyntacticDigraph* g, void* f)
  {
    using namespace scripting;
    
    run_parameters p;
    p.syntactic_digraph = g;
    
    runner* algo = static_cast<runner*> (f);
    
    algo->prepare(&p);
    algo->bridge();
    algo->run();
    algo->unbridge();
  }

}


namespace scripting {

  // The key class
  
  key::key(const char* key) : d (pgfgd_new_key(key)) {}
  key::key(struct pgfgd_Declaration* dec) : d (dec) {}
  key::~key() {pgfgd_free_key(d); }
  
  const key& key::summary (const char* x) const {
    pgfgd_key_summary(d, x);
    return *this;
  }

  const key& key::initial (const char* x) const {
    pgfgd_key_initial(d, x);
    return *this;
  }

  const key& key::initial (factory_base* fac) const {
    pgfgd_key_initial_user(d, static_cast<void*>(fac));
    return *this;
  }

  const key& key::type (const char* x) const {
    pgfgd_key_type(d, x);
    return *this;
  }

  const key& key::module_type () const {
    pgfgd_key_type(d, "user value");
    return *this;
  }

  const key& key::default_value (const char* x) const {
    pgfgd_key_default(d, x);
    return *this;
  }

  const key& key::alias (const char* x) const {
    pgfgd_key_alias(d, x);
    return *this;
  }

  const key& key::alias_function (const char* x) const {
    pgfgd_key_alias_function(d, x);
    return *this;
  }

  const key& key::documentation (const char* x) const {
    pgfgd_key_documentation(d, x);
    return *this;
  }

  const key& key::documentation_in (const char* x) const {
    pgfgd_key_documentation_in(d, x);
    return *this;
  }

  const key& key::phase (const char* x) const {
    pgfgd_key_phase(d, x);
    return *this;
  }

  const key& key::set_key (const char* k, const char* v) const {
    pgfgd_key_add_use(d, k, v);
    return *this;
  }

  const key& key::set_module (const char* k, factory_base* fac) const {
    pgfgd_key_add_use_user(d, k, static_cast<void*>(fac));
    return *this;
  }

  const key& key::example (const char* x) const {
    pgfgd_key_add_example(d, x);
    return *this;
  }

  const key& key::precondition (const char* x) const {
    pgfgd_key_add_precondition(d, x);
    return *this;
  }

  const key& key::postcondition (const char* x) const {
    pgfgd_key_add_postcondition(d, x);
    return *this;
  }

  const key& key::algorithm (runner* a) const {
    pgfgd_key_algorithm(d, cpp_caller, static_cast<void*>(a));
    return *this;
  }

  
  // The script class
  
  script::script (struct lua_State* s) : state(s) {}
  
  void script::declare (const key& k) {
    pgfgd_declare(state, k.d);
  }
  
  void script::declare (declarations* d) {
    d->declare(*this);
  }
  
  void script::declare (declarations& d) {
    d.declare(*this);
  }
  

  // The run_parameters class

  namespace {
    
    // Helpers:
    template <class T>
    bool fromnumber (pgfgd_SyntacticDigraph* g, const char* k, T& t)
    {
      if (pgfgd_isnumber(g->options, k)) {
	t = static_cast<T>(pgfgd_tonumber(g->options, k));
	return true;
      }
      return false;
    }
    
  };
  
  template <> bool run_parameters::option<bool> (const char* k, bool& t)
  {
    if (pgfgd_isboolean(syntactic_digraph->options, k)) {
      t = static_cast<bool>(pgfgd_toboolean(syntactic_digraph->options, k));
      return true;
    }
    return false;
  }
  
  template <> bool run_parameters::option<char*> (const char* k, char*& t)
  {
    if (pgfgd_isstring(syntactic_digraph->options, k)) {
      t = pgfgd_tostring(syntactic_digraph->options, k);
      return true;
    }
    return false;
  }
  
  template <> bool run_parameters::option<short> (const char* k, short& t)
  { return fromnumber<short> (syntactic_digraph, k, t); }
  
  template <> bool run_parameters::option<unsigned short> (const char* k, unsigned short& t)
  { return fromnumber<unsigned short> (syntactic_digraph, k, t); }
  
  template <> bool run_parameters::option<int> (const char* k, int& t)
  { return fromnumber<int> (syntactic_digraph, k, t); }
  
  template <> bool run_parameters::option<unsigned int> (const char* k, unsigned int& t)
  { return fromnumber<unsigned int> (syntactic_digraph, k, t); }
  
  template <> bool run_parameters::option<long> (const char* k, long& t)
  { return fromnumber<long> (syntactic_digraph, k, t); }
  
  template <> bool run_parameters::option<unsigned long> (const char* k, unsigned long& t)
  { return fromnumber<unsigned long> (syntactic_digraph, k, t); }
  
  template <> bool run_parameters::option<float> (const char* k, float& t)
  { return fromnumber<float> (syntactic_digraph, k, t); }
  
  template <> bool run_parameters::option<double> (const char* k, double& t)
  { return fromnumber<double> (syntactic_digraph, k, t); }
  
  void* run_parameters::invoke_void_factory_for (const char* k)
  {
    if (pgfgd_isuser (syntactic_digraph->options, k)) {
      factory_base* user = static_cast<factory_base *>(pgfgd_touser (syntactic_digraph->options, k));
      return user->make_void(this);
    }
    return 0;
  }
  
}
