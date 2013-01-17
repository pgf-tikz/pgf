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
}

struct pgfgd_Node {
  const char* name;
  pgfgd_Coordinate pos;

  pgfgd_OptionTable* options;
};

struct pgfgd_Edge {
  pgfgd_Node* tail;
  pgfgd_Node* head;

  const char* direction;

  int bends_len;
  pgfgd_Coordinate* bends;

  pgfgd_OptionTable* options;
};

struct pgfgd_Digraph {
  int vertices_len;
  pgfgd_Node* vertices;
  
  int syntactic_edges_len;
  pgfgd_Edge* syntactic_edges;

  pgfgd_OptionTable* options;  
};



// Init code

typedef struct lua_State lua_State;

extern void pgfgd_declarations_start(lua_State* state, const char* library_name);
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
