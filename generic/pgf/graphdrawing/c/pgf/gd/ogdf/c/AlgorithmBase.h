#ifndef PGF_ALGORITHMBASE_H
#define PGF_ALGORITHMBASE_H

#include <pgf/gd/ogdf/c/ModuleManager.h>
#include <pgf/gd/ogdf/c/GraphBridged.h>


namespace pgf {
 
  struct AlgorithmBase {

    AlgorithmBase (GraphBridged& gb);
    
    GraphBridged&           graph_bridged;
    
    // Easy access:
    ogdf::Graph&            graph;
    ogdf::GraphAttributes&  graph_attributes;
  
    ogdf::NodeArray<TableBridged*>& node_options;
    ogdf::EdgeArray<TableBridged*>& edge_options;
  
    TableBridged&           graph_options;

    std::string string_option (const std::string& c);
    bool        bool_option   (const std::string& c);
    double      number_option (const std::string& c);
    
    bool        is_option     (const std::string& c);

    template <class Module>
    Module*     new_module    ();

    template <class Module>
    bool        is_module_set ();
    
  };


  // Template implementations

  template <class Module> Module* AlgorithmBase::new_module ()
  {
    std::string key = ModuleManager::keyOf<Module>();
    
    if (is_option(key)) 
      return ModuleManager::getFactory<Module> (key, string_option(key)) (*this);
    else
      return 0;
  }

  template <class Module> bool AlgorithmBase::is_module_set ()
  {
    return is_option(ModuleManager::keyOf<Module>());
  }
 
} // namespace

#endif
