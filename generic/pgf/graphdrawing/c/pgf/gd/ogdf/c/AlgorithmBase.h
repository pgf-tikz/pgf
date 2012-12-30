#ifndef PGF_ALGORITHMBASE_H
#define PGF_ALGORITHMBASE_H


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
    
    bool        is_option (const std::string& c);
    
  };
 
} // namespace

#endif
