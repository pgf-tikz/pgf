#ifndef PGF_GD_INTERFACE_C_INTERFACEFROMC_H
#define PGF_GD_INTERFACE_C_INTERFACEFROMC_H

/** \file pgf/gd/interface/c/InterfaceFromC.h

    The C-header file that should be used by algorithms written
    in C for graph drawing in Lua.
*/


#ifdef __cplusplus
extern "C" {
#endif





// Option handling

/** Abstraction of a Lua option table.
    You cannot access it directly, but only through the function
    pgfgd_isset and so on. Note that pointers to such option tables
    will only be valid during a run of the algorithm; you cannot store
    a point to an option table past the run of an algorithm.
*/
    
typedef struct pgfgd_OptionTable pgfgd_OptionTable;


/** Returns 1 if the key is actually set in the option table to any
    non-nil value; otherwise 0. */
int pgfgd_isset(pgfgd_OptionTable* t, const char* key);

/** Returns 1 if the key is a number (or can be converted to a
    number) in the option table. */
int pgfgd_isnumber(pgfgd_OptionTable* t, const char* key);

/** Returns 1 if the key is a string in the option table. */
int pgfgd_isstring(pgfgd_OptionTable* t, const char* key);

/** Returns 1 if the key is a Boolean value in the option table. */
int pgfgd_isboolean(pgfgd_OptionTable* t, const char* key);

/** Returns 1 if the key is a user value in the option table. */
int pgfgd_isuser(pgfgd_OptionTable* t, const char* key);

/** Provided that pgfgd_isnumber returns 1 for the key, this funciton
    will return the number stored in the key (otherwise, the function
    may crash). Note that integers are also retrieved through this function. */ 
double pgfgd_tonumber(pgfgd_OptionTable* t, const char* key);

/** Provided that pgfgd_isstring returns 1 for this key, this function
    returns a copy of the string stored in the key. You must free the
    returned string yourself. */
char* pgfgd_tostring(pgfgd_OptionTable* t, const char* key);

/** Provided that pgfgd_isboolean returns 1 for this key, the function
    returns this Boolean value. */
int pgfgd_toboolean(pgfgd_OptionTable* t, const char* key);

/** Provided that pgfgd_isuser returns 1 for this key, the function
    returns this user value. */
void* pgfgd_touser(pgfgd_OptionTable* t, const char* key);



// Graph model

/** An abstraction of a pgf.gd.model.Coordinate object. */
typedef struct pgfgd_Coordinate {
  double x;
  double y;
} pgfgd_Coordinate;


/** Used to pass around arrays of Coordinate objects. The main purpose
    of the structure is to provide access to the length of the
    array. Note that numbering starts with 0.
*/ 
typedef struct pgfgd_Coordinate_array {
  int length;
  pgfgd_Coordinate* array;
} pgfgd_Coordinate_array;


typedef struct pgfgd_Edge pgfgd_Edge;

/** An array of Edge objects. */
typedef struct pgfgd_Edge_array {
  
  int length;
  pgfgd_Edge** array;
  
} pgfgd_Edge_array;

  
/** This struct is used to model a Lua Path. In Lua, a path is an
    array where each entry is either a Coordinate object or a
    string. This is modeled on the C layer by having
    two arrays and for each position, either the coordinates array or
    the strings array is set (the strings
    array is set at position i if, and only if, it is not null).  

    Graph drawing functions may wish to modify Edge paths, namely
    whenever they wish to setup a special routing for an edge. In this
    case, you may not directly modify the object, but, rather, you
    must use the functions pgfgd_path_xxx to modify the path
    field. When the graph drawing function is done, the values stored
    in the the path fields of the Edges of the syntactic digraph are
    copied back to Lua.

    Note that numbering starts at 0. Also note that you have to set
    the path field for each syntactic edge individually.

    The |length| field will be |-1| for the ``default path'' of an
    edge. The actual path (a straight line from the tail to the head
    vertex) is generated only when the graph is written back, because
    only then the coordinates of the nodes will be known. 
*/

typedef struct pgfgd_Path {

  /** Both arrays of this struct will have this length, except when
      this field is set to -1, indicating that a default path should
      be generated when this path is written back to the graph. */
  int                length;

  /** An array of coordinates. Not all entries of this array are
      relevant, namely only those for which the strings array is null
      at the some position.
  */
  pgfgd_Coordinate*  coordinates;

  /** An array of strings. Whenever an entry in this array is not
      null, the entry in the coordinates array at the same position is
      ignored. */
  char**             strings;
  
} pgfgd_Path;


  
/** An abstraction of a pgf.gd.model.Vertex. These objects are
    managed by the library (including creation and deletion), you
    should not create them yourself or modify them, except for the pos
    field, which you should modify (indeed, this is the whole purpose
    of your graph drawing algorithm).
*/

typedef struct pgfgd_Vertex {
  
  /** The name field of the Lua Vertex class. */
  char* name;

  /** The path field of the Lua Vertex class. */
  pgfgd_Path* path;

  /** The shape field of the Lua Vertex class. */
  char* shape;

  /** The kind field of the Lua Vertex class. */
  char* kind;
  
  /** The pos field of the Lua Vertex class. Unlike the other fields
      of this struct, you can write pos.x and pos.y. When the graph
      drawing function returns, the values stored in theses fields
      will be written back to the Lua layer.
  */
  pgfgd_Coordinate pos;
  
  /** The options fields of the Lua Vertex class. Note that you do
      not have direct access to theses options. Rather, all access to
      them must go through functions like pgfgd_isset that take a
      pgfgd_OptionsTable* as input. Also note that you cannot store a
      pointer to an options table: At the end of the graph drawing
      function, all option table pointers will loose their
      meaning. If you really wish to store an options table, you need
      to retrieve all information stored in it while the point is
      still active and then store the retrieved information in your
      own table.
  */
  pgfgd_OptionTable* options;

  /** Similar to the incoming field of the Lua Vertex class, but it
      stores abstractions of the syntactic Edges objects of the
      syntactic digraph, rather than the table of Arc objects that are
      really stored in a Vertex. Also note that in a Lua Vertex
      object, the incoming and outgoing arcs depend on the graph,
      while a pgfgd_Vertex always only stores the incoming and
      outgoing edges of the syntactic digraph. The order of the edges
      in the incoming array will be the same as on the Lua layer, but
      numbering starts with 0 (since these are C arrays).
  */
  pgfgd_Edge_array incoming;

  /** Like the incoming fields. */
  pgfgd_Edge_array outgoing;

  /** The index of this vertex in the array entry of the syntactic
      digraph. */
  int array_index;
  
} pgfgd_Vertex;



/** Used to pass around arrays of Vertex objects (more precisely, of
    arrays of pointers to pgfgd_Vertex objects). Note that numbering
    starts with 0.
*/

typedef struct pgfgd_Vertex_array {
  int length;
  pgfgd_Vertex** array;
} pgfgd_Vertex_array;

  

/** This function allows you to query an anchor of a vertex (like a
    call to |Vertex:anchor|). The function returns
    |1| if there is such an anchor, otherwise |0| is returned and
    both |x| and |y| will be set to 0. */
extern int pgfgd_vertex_anchor(pgfgd_Vertex* v, const char* anchor, double* x, double* y);
  
  

/** An abstraction of pgf.gd.model.Edge. */

struct pgfgd_Edge {
  
  /** The tail field of the Lua Edge class. */
  pgfgd_Vertex* tail;

  /** The head field of the Lua Edge class. */
  pgfgd_Vertex* head;

  /** The direction field of the Lua Edge class. */
  char* direction;
  
  /** The path field of the Lua Edge class. You can read this field
      directly, but you can write it only through the function whose
      names start with pgfgd_path.

      For each pgfgd_Edge object, at the end of the graph drawing
      routinge, the value stored in this field will be written back to
      the path field of the original syntactic edge.
  */
  pgfgd_Path* path;

  /** A pointer to the options table of the Edge. This works like the
      options table of pgdgd_Vertex and the same restrictions apply.
   */
  pgfgd_OptionTable* options;
  
  /** The index of this edge in the array entry of the syntactic
      digraph. */
  int array_index;
  
};


typedef struct pgfgd_SyntacticDigraph_internals pgfgd_SyntacticDigraph_internals;


/** The class pgf.gd.model.Digraph is modeled using two different C
    structs: First, we have pgfgd_SyntacticDigraph and, second, we
    have pgfgd_Digraph. The first is used, only, to model the (single)
    syntactic digraph that is passed to the graph drawing function,
    while the second is used to model different, more light weight
    digraphs that are computed be the graph drawing system prior to
    the call of the graph drawing routine. For instance, the spanning
    tree computed by the graph drawing system for algorithms whose
    preconditions included "tree" will be modeled as a pgfgd_Digraph.
    
    There is only one pgfgd_SyntacticDigraph during a call of
    the graph drawing routine and you can access its properties
    directly by accessing the fields of the struct. You cannot,
    however, modify the syntactic digraph, except for setting the pos
    fields of the vertices and for setting the path field arrays of
    the syntactic edges (through the pgfgd_path_xxx functions). When
    the graph drawing function is done, the modifications will be
    written back to the Lua layer.

    Note that the syntactic digraph only stores the syntactic edges,
    not the Arc objects. In particular, when you write
    |graph { a <- b }| on the TikZ layer, you will get one syntactic
    edge from a to b (not the other way round) with its direction
    field set to "<-" in the syntactic digraph object.
 */

typedef struct pgfgd_SyntacticDigraph {
  
  /** The vertices field of a Lua (syntactic) digraph. You may not
      modify this array, except for changing the pos fields of the
      vertices. */
  pgfgd_Vertex_array vertices;

  /** All syntactic edges of the graph. You cannot modify this array,
      but you can use the pgfgd_path_xxx funtion to change the routing
      of the edges stored here. Note that, since you get access to 
      syntactic edges, the direction of these edges may not be what
      you expect and there may be several syntactic edges between the
      same vertices.
   */
  pgfgd_Edge_array syntactic_edges;

  /** The syntactic digraph's options field. Like all options fields,
      it will go out of scope at the end of the graph drawing
      routine. 
   */
  pgfgd_OptionTable* options;

  pgfgd_SyntacticDigraph_internals* internals;
  
} pgfgd_SyntacticDigraph;




// Modifying edge bend paths

/** You can apply this function to an Edge to clear the routing path
    stored in it. 
*/
extern void pgfgd_path_clear          (pgfgd_Edge* e);
  
/** This function adds a moveto at the end of a path. */
extern void pgfgd_path_append_moveto (pgfgd_Edge* e, double x, double y);
  
/** This function adds a moveto to the |tail anchor| of the tail of
    the edge. This call is useful for ``starting'' a path. This
    function is a ``service function,'' you can achieve the same
    effect by directly reading the option table of the tail vertex
    and then using the pgfgd_vertex_anchor method. */
extern void pgfgd_path_append_moveto_tail (pgfgd_Edge* e);
  
/** This function adds a lineto at the end of a path. */
extern void pgfgd_path_append_lineto (pgfgd_Edge* e, double x, double y);
  
/** This function adds a linto to the |head anchor| of the head of
    the edge. This call is useful for ``ending'' a path. */
extern void pgfgd_path_append_lineto_head (pgfgd_Edge* e);
  
/** This function adds a closepath at the end of a path. */
extern void pgfgd_path_append_closepath (pgfgd_Edge* e);
  
/** This function adds a curevto at the end of a path. */
extern void pgfgd_path_append_curveto (pgfgd_Edge* e, double x1, double y1, double x2, double y2, double x, double y);
   



// Querying graphs other than the syntactic digraph

/** A pgfgd_Digraph is a light-weight abstraction of a Lua Digraph
    object. Unlike a pgfgd_SyntacticDigraph, you cannot access the
    fields such an object directly, rather, all information is
    retrieved through functions starting with pgfgd_digraph.

    When the graph drawing function is called, the graph drawing
    system will already have computed a number of special digraphs in
    addition to the syntactic digraph passed to the function. For
    instance, there is always the "ugraph", which is the undirected
    graph underlying the syntactic digraph. To access these special
    graphs, you first call pgfgd_get_digraph and then use the
    pgfgd_digraph_xxx function to retrieve information about them.

    Unlike the pgfgd_SyntacticDigraph object, which is managed by the
    library, you must free pgfgd_Digraph objects yourself through the
    pgfgd_digraph_free function.
*/

typedef struct pgfgd_Digraph pgfgd_Digraph;

/** There is no abstraction of an Arc object on the C layer. Rather,
    an arc is simply the index of the tail vertex plus the index of
    the head vertex, where the indices are relative to the array of
    vertices making up the digraph under consideration.

    You may wonder why we store indices rather than pointers to
    pgfgd_Vertex objects. The reason is that a pgfgd_Digraph may
    actually contain vertices that are not present in the syntactic
    digraph (for instance, dummy vertices in a spanning tree) and for
    which no pgfgd_Vertex obejct exists. For this reason, we only use
    indices and there is a special function
    (pgfgd_digraph_syntactic_vertex) that can be used to retrieve the
    pgfgd_Vertex object, provided it exists.

    Note that the numbers stored in the tails and heads arrays, which
    refer to positions inside a Lua vertices array, start numbering
    with 1. The arrays themselves, however, start numbering with
    0. So, tails[0] == 1 and heads[0] == 2 would mean that there is an
    Arc from the first to the second vertex. You can pass the numbers
    stored in these arrays directly to the pgfgd_digraph_xxx
    functions.

    You must free pgfgd_Arc_array objects yourself via
    pgfgd_digraph_free_arc_array. 
 */
typedef struct pgfgd_Arc_array {

  /** The length of both arrays. */
  int length;

  /** The array of the numbers of the tail vertices of the arcs. The
      array itself starts numbering with 0, but its entries refer to
      positions inside Lua array, so their numbering starts with 1. */
  int* tails;

  /** Like tails. */
  int* heads;
  
} pgfgd_Arc_array;


/** In order to access special digraphs like the |ugraph| or the
    |spanning_tree| computed by the graph drawing system, you first
    need to call this function. In detail, the graph_name must be the
    name of a field of the Lua algorithm object and this field must
    store a |Digraph| object. Examples are "digraph" or "ugraph". The
    function will then return a handle to this digraph which you can
    subsequently access. The handle will become invalid at the end of
    the graph drawing funciton and you must free it explicitly using
    pgfgd_digraph_free. 
 */
extern pgfgd_Digraph*    pgfgd_get_digraph              (pgfgd_SyntacticDigraph* g, const char* graph_name);

/** Returns the number of vertices in the digraph. Note that this
    number needs not be the same as the number of vertices in the
    syntactic digraph and that the ordering need not be the
    same as in the syntactic digraph. */
extern int               pgfgd_digraph_num_vertices     (pgfgd_Digraph* g);

/** Returns a newly allocated array of all arcs present in the
    digraph. You must free this array explicitly using
    pgfgd_digraph_free_arc_array. 
*/
extern pgfgd_Arc_array*  pgfgd_digraph_arcs             (pgfgd_Digraph* g);

/** This function allows you to retrieve the syntatic vertex that
    corresponds to a given index in the digraph. Normally, the first
    vertex of a digraph like the ugraph will also be the first entry
    of the vertices field of the syntactic digraph, but this need not
    always be the case. For instance, for a spanning_tree digraph,
    there will be more vertices in the graph than there are syntactic
    vertices and the order may be quite different. For theses reaons,
    you must use this function to convert a vertex index into the
    digraph g into a pgfgd_Vertex object. It may happen that the index
    does not refer to any syntactic vertex, in this case 0 is
    returned.

    Note that v is an index into a Lua array and, thus, numbering
    starts with 1.
*/
extern pgfgd_Vertex*     pgfgd_digraph_syntactic_vertex (pgfgd_Digraph* g, int v);

/** Tests whether there is an arc between two vertices in the digraph
    g. The tail and head are indices starting with 1. This operation
    takes time $O(1)$.
*/
extern int               pgfgd_digraph_isarc            (pgfgd_Digraph* g, int tail, int head);

/** Returns an array of all syntactic edges present between two
    vertices (whose indices are given as input). You must free the
    returned array explicitly using
    pgfgd_digraph_free_edge_array. Typically, this array will have at
    most one entry, but it may happen that the user has specified
    several syntatic edges between the same vertices, in which case
    you get a larger array here.

    Note that tail and head are indices (starting with 1) into the
    digraph's vertices array, which the return value is an array of
    syntactic edges present in the syntactic digraph between the
    vertices corresponding to these indices. In particular, if the
    vertices do not correspond to syntactic vertices, the returned
    array will always be empty.
*/
extern pgfgd_Edge_array* pgfgd_digraph_syntactic_edges  (pgfgd_Digraph* g, int tail, int head);

/** Returns an array of all incoming arcs of the given vertex. (As
    always, the vertex is coded as an index starting with 1 into the
    vertices array of the digraph.) You must free this array
    yourself using pgfgd_digraph_free_arc_array. In the returned
    array, all entries of the head array will equal v.
 */
extern pgfgd_Arc_array*  pgfgd_digraph_incoming         (pgfgd_Digraph* g, int v);

/** Like pgfgd_digraph_incoming. */
extern pgfgd_Arc_array*  pgfgd_digraph_outgoing         (pgfgd_Digraph* g, int v);

/** Frees a pgfgd_Digraph object previously allocated by the
    pgfgd_get_digraph function. */
extern void              pgfgd_digraph_free             (pgfgd_Digraph* d);

/** Frees a pgfgd_Arc_array object; in particular, the arrays stored
    inside it are freed. You should call this function once at some
    point for all objects of this kind returned by any library function.
*/
extern void              pgfgd_digraph_free_arc_array   (pgfgd_Arc_array* arcs);

/** Like pgfgd_digraph_free_arc_array, but for the Edge arrays
    returned by pgfgd_digraph_syntactic_edges. Do not call this
    function for the syntactic_edges field of a syntactic digraph.
*/ 
extern void              pgfgd_digraph_free_edge_array  (pgfgd_Edge_array* edges);



// Declarations

struct lua_State;
typedef void (*pgfgd_algorithm_fun) (pgfgd_SyntacticDigraph* component, void* user_data);
typedef struct pgfgd_Declaration pgfgd_Declaration;


/** Each declaration of a new option starts with a call to this
    function. The function returns an object whose properties you can
    set subsequently through the pgfgd_key_xxx function. Once all
    properties of the key have been set, you call pgfgd_declare to
    make Lua aware of the option. Then, you need to call
    pgfgd_free_key on it.  
 */

extern pgfgd_Declaration* pgfgd_new_key (const char* key);

/** Sets the summary field of the key. You should always call this
    function. */
extern void pgfgd_key_summary           (pgfgd_Declaration* d, const char* s);

/** Sets the type field of the key. */
extern void pgfgd_key_type              (pgfgd_Declaration* d, const char* s);

/** Sets the initial field of the key to a string. */
extern void pgfgd_key_initial           (pgfgd_Declaration* d, const char* s);

/** Sets the initial field of the key to void* value (a light userdata
    in Lua-speak). */
extern void pgfgd_key_initial_user      (pgfgd_Declaration* d, void* v);

/** Sets the default field of the key. */
extern void pgfgd_key_default           (pgfgd_Declaration* d, const char* s);

/** Sets the alias field of the key. */
extern void pgfgd_key_alias             (pgfgd_Declaration* d, const char* s);

/** Sets the alias_function_string field of the key. */
extern void pgfgd_key_alias_function    (pgfgd_Declaration* d, const char* s);

/** Sets the documentation field of the key. */
extern void pgfgd_key_documentation     (pgfgd_Declaration* d, const char* s);

/** Sets the documentation_in field of the key. */
extern void pgfgd_key_documentation_in  (pgfgd_Declaration* d, const char* s);

/** Sets the phase field of the key. */
extern void pgfgd_key_phase             (pgfgd_Declaration* d, const char* s);

/** Sets the algorithm field of the key. The function f must conform
    to the function prototype pgfgd_algorithm_fun, which prescribes
    that the function takes a syntactic digraph as input
    (pgfgd_SyntacticDigraph*) and some user data and does not return
    anything. The user data that is passed to the function is the
    datum passed here.

    Whenever the key is now used on the Lua layer, the graph drawing
    system will run the normal layout pipeline on the graph. Then, at
    some point, it would call the actual Lua graph drawing
    algorithm. At that point, the function f is called instead. The
    parameter of this function will be a representation of the
    to-be-drawn syntatic digraph as a C pgfgd_SyntacticDigraph. 
*/
extern void pgfgd_key_algorithm         (pgfgd_Declaration* d,
					 pgfgd_algorithm_fun f,
					 void* user_data);

/** Adds a use to the key. This means that whenever the key is used,
    the given key--value pairs will also be set. This is used, in
    particular, to create aliases for keys (but is not to be confused
    with the |alias| field, whose semantics are slightly different). 
 */
extern void pgfgd_key_add_use           (pgfgd_Declaration* d, const char* key, const char* value);

/** Adds a use to the key, but with the value being a user value in
    Lua-speak. 
 */
extern void pgfgd_key_add_use_user      (pgfgd_Declaration* d, const char* key, void* value);

/** Adds an example to the examples field of the key. */
extern void pgfgd_key_add_example       (pgfgd_Declaration* d, const char* s);

/** Adds a precondition (the field s of the precondition table is set
    to true) to the key. */
extern void pgfgd_key_add_precondition  (pgfgd_Declaration* d, const char* s);

/** Adds a postcondition to the key. */
extern void pgfgd_key_add_postcondition (pgfgd_Declaration* d, const char* s);

/** After all properties of an option key have been set, call this
    function once to actually declare the key inside the state that
    your graph drawing library's main function gets 
    passed by the Lua dynamic linkage code. */
extern void pgfgd_declare               (struct lua_State* s, pgfgd_Declaration* d);

/** Frees the memory used by the key object. */
extern void pgfgd_free_key              (pgfgd_Declaration* d);
  
#ifdef __cplusplus
}
#endif

  
#endif
