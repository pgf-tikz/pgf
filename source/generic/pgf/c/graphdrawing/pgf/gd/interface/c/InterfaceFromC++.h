#ifndef PGF_GD_INTERFACE_C_INTERFACEFROMCPP_H
#define PGF_GD_INTERFACE_C_INTERFACEFROMCPP_H

/** \file pgf/gd/interface/c/InterfaceFromC++.h

    The C++-header file that should be used by algorithms written
    in C++ for graph drawing in Lua.
*/


struct lua_State;
struct pgfgd_Declaration;
struct pgfgd_SyntacticDigraph;

namespace scripting {
  
  // Forward;
  class script;
  class run_parameters;
  
  
  class runner {
  public:

    void prepare (run_parameters* p) { parameters = p; }
    
    virtual void bridge   () {}
    virtual void run      () = 0;
    virtual void unbridge () {}
    
    virtual ~runner  () {}

  protected:

    run_parameters* parameters;
    
  };
  
  class factory_base {
  public:
    virtual void* make_void (run_parameters*) = 0;
    virtual ~factory_base () {}
  };
    
  template <class T> class factory : public factory_base {
    virtual void* make_void (run_parameters*r) { return static_cast<void*>(make(r)); }
    virtual T*    make (run_parameters*) { return new T(); }
  };
    
  class key {
  public:
    
    key (const char*);
    key (struct pgfgd_Declaration*);
    ~key ();
    
    const key& summary          (const char*) const;
    const key& initial          (const char*) const;
    const key& initial          (factory_base*) const;
    const key& type             (const char*) const;
    const key& module_type      () const;
    const key& default_value    (const char*) const;
    const key& alias            (const char*) const;
    const key& alias_function   (const char*) const;
    const key& documentation    (const char*) const;
    const key& documentation_in (const char*) const;
    const key& phase            (const char*) const;
    const key& set_key          (const char*, const char*) const;
    const key& set_module       (const char*, factory_base*) const;
    const key& example          (const char*) const;
    const key& precondition     (const char*) const;
    const key& postcondition    (const char*) const;
    const key& algorithm        (runner*) const;

  private:
      
    struct pgfgd_Declaration* d;  
    friend class script;

    key (const key& k); // Not implemented.
    key& operator = (const key& k); // Not implemented.

  };

  
  // Declarations are useful for scripting:
  
  class declarations {
    
  public:
    
    virtual void declare (script) = 0;
    virtual ~declarations () {}
    
  };
  

  // The script class
    
  class script {
    
  public:
    
    script (struct lua_State*);
    
    // Declares a key
    void declare (const key&);
    void declare (declarations&);
    void declare (declarations*);
    
  private:
    
    struct lua_State* state;
    
  };
  
  
  
  // Declaring algorithms defined in a function
    
  class function_runner : public runner {
  public:
    function_runner (void (*f) (run_parameters&)) : fun(f) {}
    virtual void run () { fun(*parameters); }

  private:
    void (*fun) (run_parameters&);
  };
  

  // Configuring a class

  class run_parameters {
  public:
    
    struct pgfgd_SyntacticDigraph* syntactic_digraph;
    
    template <class Layout, class T>
    void configure_option (const char*, void (Layout::*) (T), Layout&);
    
    template <class Layout, class T>
    void configure_module (const char*, void (Layout::*) (T*), Layout&);

    template <class T> bool option        (const char*, T&);
    template <class T> T    option        (const char*);
    template <class T> bool option_is_set (const char*);
    
    template <class T> T*   make          (const char*);

  protected:
    void* invoke_void_factory_for (const char*);
  };
  
  template <class T>
  T run_parameters::option (const char* k)
  {
    T t;
    option (k, t);
    return t;
  }
  
  template <class T>
  bool run_parameters::option_is_set (const char* k)
  {
    T t;
    return option(k, t);
  }

  template <class Layout, class T>
  void run_parameters::configure_option (const char* k, void (Layout::*f) (T), Layout& l)
  {
    T t;
    if (option<T> (k, t))
      (l.*f) (t);
  }

  template <class Layout, class T>
  void run_parameters::configure_module (const char* k, void (Layout::*f) (T*), Layout& l)
  {
    if (void* obj = invoke_void_factory_for(k))
      (l.*f) (static_cast<T*> (obj));
  }
  
  template <class T>
  T* run_parameters::make (const char* k) { return static_cast<T*>(invoke_void_factory_for(k)); }

}


#endif
