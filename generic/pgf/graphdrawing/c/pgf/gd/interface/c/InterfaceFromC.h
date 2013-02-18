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


typedef struct pgfgd_path_array {
  // The type of the path field. The two arrays both have length
  // path_len. For each position, exactly one of the two arrays will
  // not non-null. 
  int                length;
  pgfgd_Coordinate*  coordinates;
  char**             strings;
} pgfgd_path_array;


struct pgfgd_Edge {
  
  // The tail field
  pgfgd_Vertex* tail;

  // The head field
  pgfgd_Vertex* head;

  // The direction field
  char* direction;
  
  pgfgd_path_array path;
  
  // The options field
  pgfgd_OptionTable* options;
  
};



typedef struct  pgfgd_Digraph {

  // The vertices field. Currently, you cannot add to this array.
  pgfgd_Vertex_array vertices;
  
  // The syntactic_edges. You do not have access to the |arcs| field,
  // but, instead, to an array of all syntactic edges.
  pgfgd_Edge_array syntactic_edges;
  
  // The options field.
  pgfgd_OptionTable* options;
  
} pgfgd_Digraph;



// Modifying edge bend paths

extern void pgfgd_path_clear(pgfgd_Edge* e);
extern void pgfgd_path_add_coordinate(pgfgd_Edge* e, double x, double y);
extern void pgfgd_path_add_string(pgfgd_Edge* e, const char* s);


// Declarations

struct lua_State;
typedef void (*pgfgd_algorithm_fun) (pgfgd_Digraph* g);
typedef struct pgfgd_Declaration pgfgd_Declaration;

extern pgfgd_Declaration* pgfgd_new_key (struct lua_State* state, const char* key);
extern void pgfgd_key_summary(pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_type(pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_initial(pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_default(pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_alias(pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_documentation(pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_phase(pgfgd_Declaration* d, const char* s);
extern void pgfgd_key_algorithm(pgfgd_Declaration* d, pgfgd_algorithm_fun f);
extern void pgfgd_key_add_use(pgfgd_Declaration* d, const char* key, const char* value);
extern void pgfgd_key_add_example(pgfgd_Declaration* d, const char* s);
extern void pgfgd_declare(pgfgd_Declaration* d);

#endif
