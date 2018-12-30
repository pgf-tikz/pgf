#ifndef PGF_GD_INTERFACE_C_INTERFACEFROMOGDF_H
#define PGF_GD_INTERFACE_C_INTERFACEFROMOGDF_H

/** \file pgf/gd/interface/c/InterfaceFromOGDF.h

    The C++-header file that should be used by algorithms written
    for the OGFD library when the algorithm should be included in Lua. 
*/

#include <pgf/gd/interface/c/InterfaceFromC++.h>
#include <ogdf/basic/Graph.h>
#include <ogdf/basic/GraphAttributes.h>

namespace scripting {
  
  class ogdf_runner : public runner {
  public:

    void bridge ();
    void unbridge ();
    
  protected:

    ogdf::Graph           graph;
    ogdf::GraphAttributes graph_attributes;
    
  };
  
  
  class ogdf_function_runner : public ogdf_runner {
  public:
    typedef void (*function) (run_parameters&,
			      ogdf::Graph&,
			      ogdf::GraphAttributes&);
    
    ogdf_function_runner (function f) : fun(f) {}
    virtual void run () { fun(*parameters, graph, graph_attributes); }

  private:
    function fun;
  };
}


#endif
