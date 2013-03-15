#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <pgf/gd/interface/c/InterfaceFromC.h>

#include <ogdf/basic/geometry.h>


using namespace ogdf;

namespace scripting {

  
  void ogdf_runner::bridge ()
  {
    graph            = Graph();
    graph_attributes = GraphAttributes (graph,
					GraphAttributes::nodeGraphics |
					GraphAttributes::edgeGraphics |
					GraphAttributes::nodeLevel |
					GraphAttributes::edgeIntWeight |
					GraphAttributes::edgeDoubleWeight |
					GraphAttributes::nodeWeight);
    
    pgfgd_SyntacticDigraph* g = parameters->syntactic_digraph;
    
    int n = g->vertices.length;
    int m = g->syntactic_edges.length;
    
    node* nodes = new node [n];
    
    for (int i=0; i < n; i++) {
      nodes[i] = graph.newNode();

      // Computer width and height
      int x1,x2,y1,y2;

      pgfgd_Coordinate_array* hull = &g->vertices.array[i]->hull;

      if (hull->length == 0) {
	graph_attributes.width(nodes[i]) = 0;
	graph_attributes.height(nodes[i]) = 0;
      } else {
	x1 = x2 = hull->array[0].x;
	y1 = y2 = hull->array[0].y;

	for (int j = 1; j < hull->length; j++) {
	  int x = hull->array[j].x;
	  int y = hull->array[j].y;

	  x1 = x < x1 ? x : x1;
	  x2 = x > x2 ? x : x2;
	  y1 = y < y1 ? y : y1;
	  y2 = y > y2 ? y : y2;
	}

	graph_attributes.width(nodes[i]) = x2-x1;
	graph_attributes.height(nodes[i]) = y2-y1;	
      }
    }
    
    for (int i=0; i < m; i++) {
      int tail = g->syntactic_edges.array[i]->tail->array_index;
      int head = g->syntactic_edges.array[i]->head->array_index;

      graph.newEdge(nodes[tail], nodes[head]);
    }
  }
  
  void ogdf_runner::unbridge ()
  {
    pgfgd_SyntacticDigraph* g = parameters->syntactic_digraph;
    
    node v;
    int i;
    for (i = 0, v = graph.firstNode(); v; v=v->succ(), i++) {
      g->vertices.array[i]->pos.x = graph_attributes.x(v);
      g->vertices.array[i]->pos.y = graph_attributes.y(v);
    }
    
    edge e;
    for (i = 0, e = graph.firstEdge(); e; e=e->succ(), i++) {
      pgfgd_Edge* ed = g->syntactic_edges.array[i];
      
      pgfgd_path_clear (ed);
      
      DPolyline bend = graph_attributes.bends(e);
      bend.unify();
      bend.normalize();

      int tail_x = graph_attributes.x(e->source());
      int tail_y = graph_attributes.y(e->source());

      for (List<DPoint>::iterator it = bend.begin(); it.valid(); it++) 
	pgfgd_path_add_coordinate(ed, (*it).m_x - tail_x, (*it).m_y - tail_y);
    }    
  }
  
}
