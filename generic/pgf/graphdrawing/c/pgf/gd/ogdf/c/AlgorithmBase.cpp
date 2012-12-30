#include <pgf/gd/ogdf/c/AlgorithmBase.h>

using namespace std;
using namespace ogdf;

namespace pgf {
  
  AlgorithmBase::AlgorithmBase(GraphBridged& gb)
    : graph_bridged(gb),
      graph(gb.getGraph()),
      graph_attributes(gb.getGraphAttributes()),
      node_options(gb.getNodeOptions()),
      edge_options(gb.getEdgeOptions()),
      graph_options(gb.getGraphOptions())
  {}

  string AlgorithmBase::string_option(const string& c)
  {
    return graph_options.getStringField(c);
  }

  bool AlgorithmBase::bool_option(const string& c)
  {
    return graph_options.getBooleanField(c);
  }

  double AlgorithmBase::number_option(const string& c)
  {
    return graph_options.getNumberField(c);
  }

  bool AlgorithmBase::is_option(const string& c)
  {
    return
      graph_options.isNumberField(c) || graph_options.isStringField(c) ||
      graph_options.isBooleanField(c) || graph_options.isTableField(c);
  }
  
}
