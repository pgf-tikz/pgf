#ifndef PGF_INTERFACEFROMC_H
#define PGF_INTERFACEFROMC_H


// Option handling

typedef struct pgfgd_OptionTable pgfgd_OptionTable;

int pgfgd_isset(pgfgd_OptionTable* t, const char* key);

int pgfgd_isnumber(pgfgd_OptionTable* t, const char* key);
int pgfgd_isstring(pgfgd_OptionTable* t, const char* key);
int pgfgd_isboolean(pgfgd_OptionTable* t, const char* key);

double      pgfgd_tonumber(pgfgd_OptionTable* t, const char* key);
const char* pgfgd_tostring(pgfgd_OptionTable* t, const char* key);
int         pgfgd_toboolean(pgfgd_OptionTable* t, const char* key);



// Graph model

struct pgfgd_Coordinate {
  double x;
  doubel y;
};

struct pgfgd_Vertex {
  
  // The name field
  const char* name;
  
  // The hull field
  int hull_len;
  pgfgd_Coordinate* hull;

  // The hull_center field
  pgfgd_Coordinate* hull_center;

  // The shape field
  const char* shape;

  // The kind field
  const char* kind;
  
  // The pos field
  pgfgd_Coordinate pos;
  
  // The options field
  pgfgd_OptionTable* options;
};


struct pgfgd_Edge {
  
  // The tail field
  pgfgd_Vertex* tail;

  // The head field
  pgfgd_Vertex* head;

  // The direction field
  const char* direction;

  // The path field. The two arrays both have length path_len. For
  // each position, exactly one of the two arrays will not non-null.  
  int path_len;
  pgfgd_Coordinate* path_coordinates;
  const char**      path_strings
  
  // The options field
  pgfgd_OptionTable* options;
  
};


struct pgfgd_Digraph {

  // The vertices field. Currently, you cannot add to this array.
  int vertices_len;
  pgfgd_Vertex* vertices;
  
  // The syntactic_edges. You do not have access to the |arcs| field,
  // but, instead, to an array of all syntactic edges.
  int syntactic_edges_len;
  pgfgd_Edge* syntactic_edges;
  
  // The options field.
  pgfgd_OptionTable* options;  
};



// Init code

typedef struct lua_State lua_State;

extern void pgfgd_declarations_start(lua_State* state);
extern int  pgfgd_declarations_done(void);



// Declarations

typedef struct pgfgd_Declaration pgfgd_Declaration;
typedef void (*pgfgd_algorithm_fun) (pgfgd_Digraph* g);

extern void pgfgd_declare(pgfgd_Declaration* d);


// Declaring different things

extern pgfgd_Declaration* pgfgd_new_option(const char* key, const char* type,  const char* initial_value, const char* summary);
extern pgfgd_Declaration* pgfgd_new_algorithm(const char* key, pgfgd_algorithm_fun f, const char* summary);


// General settings for all declarations:

extern pgfgd_Declaration* pgfgd_default(pgfgd_Declaration* d, const char* default_value);
extern pgfgd_Declaration* pgfgd_alias(pgfgd_Declaration* d, const char* alias);
extern pgfgd_Declaration* pgfgd_add_documentation(pgfgd_Declaration* d, const char* line);
extern pgfgd_Declaration* pgfgd_add_example(pgfgd_Declaration* d, const char* line);
extern pgfgd_Declaration* pgfgd_add_key_value_pair(pgfgd_Declaration* d, const char* key, const char* value);

#endif
