#ifndef PGF_GD_INTERFACE_C_INTERFACEFROMC_H
#define PGF_GD_INTERFACE_C_INTERFACEFROMC_H


// Option handling

typedef struct pgfgd_OptionTable pgfgd_OptionTable;

int pgfgd_isset(pgfgd_OptionTable* t, const char* key);

int pgfgd_isnumber(pgfgd_OptionTable* t, const char* key);
int pgfgd_isstring(pgfgd_OptionTable* t, const char* key);
int pgfgd_isboolean(pgfgd_OptionTable* t, const char* key);

double      pgfgd_tonumber(pgfgd_OptionTable* t, const char* key);
char*       pgfgd_tostring(pgfgd_OptionTable* t, const char* key);
int         pgfgd_toboolean(pgfgd_OptionTable* t, const char* key);



// Graph model

typedef struct pgfgd_Coordinate {
  double x;
  double y;
} pgfgd_Coordinate;

typedef struct pgfgd_Coordinate_array {
  int length;
  pgfgd_Coordinate* array;
} pgfgd_Coordinate_array;


typedef struct pgfgd_Edge pgfgd_Edge;
typedef struct pgfgd_Edge_array {
  
  int length;
  pgfgd_Edge** array;
  
} pgfgd_Edge_array;


typedef struct pgfgd_Vertex {
  
  // The name field
  char* name;
  
  // The hull field
  pgfgd_Coordinate_array hull;

  // The hull_center field
  pgfgd_Coordinate hull_center;

  // The shape field
  char* shape;

  // The kind field
  char* kind;
  
  // The pos field
  pgfgd_Coordinate pos;
  
  // The options field
  pgfgd_OptionTable* options;

  // The incoming and outgoing syntactic edges
  pgfgd_Edge_array incoming;
  pgfgd_Edge_array outgoing;
  
} pgfgd_Vertex;

typedef struct pgfgd_Vertex_array {
  int length;
  pgfgd_Vertex** array;
} pgfgd_Vertex_array;


typedef struct pgfgd_Path_array {
  // The type of the path field. The two arrays both have length
  // path_len. For each position, exactly one of the two arrays will
  // not non-null. 
  int                length;
  pgfgd_Coordinate*  coordinates;
  char**             strings;
} pgfgd_Path_array;


struct pgfgd_Edge {
  
  // The tail field
  pgfgd_Vertex* tail;

  // The head field
  pgfgd_Vertex* head;

  // The direction field
  char* direction;
  
  pgfgd_Path_array path;
  
  // The options field
  pgfgd_OptionTable* options;
  
};


typedef struct pgfgd_SyntacticDigraph_internals pgfgd_SyntacticDigraph_internals;

typedef struct pgfgd_SyntacticDigraph {

  // The vertices field. Currently, you cannot add to this array.
  pgfgd_Vertex_array vertices;
  
  // The syntactic_edges. You do not have access to the |arcs| field,
  // but, instead, to an array of all syntactic edges.
  pgfgd_Edge_array syntactic_edges;
  
  // The options field.
  pgfgd_OptionTable* options;

  pgfgd_SyntacticDigraph_internals* internals;
  
} pgfgd_SyntacticDigraph;



// Modifying edge bend paths

extern void pgfgd_path_clear          (pgfgd_Edge* e);
extern void pgfgd_path_add_coordinate (pgfgd_Edge* e, double x, double y);
extern void pgfgd_path_add_string     (pgfgd_Edge* e, const char* s);


// Querying graphs other than the syntactic digraph

typedef struct pgfgd_Digraph pgfgd_Digraph;

typedef struct pgfgd_Arc_array {
  int length;
  int* tails;
  int* heads;
} pgfgd_Arc_array;

extern pgfgd_Digraph* pgfgd_get_digraph              (pgfgd_SyntacticDigraph* g, const char* graph_name);
extern int            pgfgd_digraph_num_vertices     (pgfgd_Digraph* g);
extern void           pgfgd_digraph_arcs             (pgfgd_Digraph* g, pgfgd_Arc_array* arcs);
extern pgfgd_Vertex*  pgfgd_digraph_syntactic_vertex (pgfgd_Digraph* g, int v);
extern int            pgfgd_digraph_isarc            (pgfgd_Digraph* g, int tail, int head);
extern void           pgfgd_digraph_syntactic_edges  (pgfgd_Digraph* g, int tail, int head, pgfgd_Edge_array* edges);
extern void           pgfgd_digraph_incoming         (pgfgd_Digraph* g, int v, pgfgd_Arc_array* incoming_arcs);
extern void           pgfgd_digraph_outgoing         (pgfgd_Digraph* g, int v, pgfgd_Arc_array* outgoing_arcs);


// Declarations

struct lua_State;
typedef void (*pgfgd_algorithm_fun) (pgfgd_SyntacticDigraph* component);
typedef struct pgfgd_Declaration pgfgd_Declaration;

extern pgfgd_Declaration* pgfgd_new_key (struct lua_State* state, const char* key);
extern void pgfgd_key_summary           (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_type              (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_initial           (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_default           (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_alias             (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_documentation     (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_phase             (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_algorithm         (pgfgd_Declaration* d, pgfgd_algorithm_fun f);
extern void pgfgd_key_add_use           (pgfgd_Declaration* d, const char* key, const char* value);
extern void pgfgd_key_add_example       (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_add_precondition  (pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_add_postcondition (pgfgd_Declaration* d, const char* s);
extern void pgfgd_declare               (pgfgd_Declaration* d);

#endif
