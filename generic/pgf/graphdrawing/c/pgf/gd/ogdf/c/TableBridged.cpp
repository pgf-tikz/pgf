#include <pgf/gd/ogdf/c/TableBridged.h>

#include <map>
#include <set>

#include <iostream>

using namespace std;

namespace pgf {
  

  // Let us start with the internals:
  
  class TableBridged::Rep {

  public:
    
    set<string>         table_fields;
    map<string, bool>   bool_fields;
    map<string, double> double_fields;
    map<string, string> string_fields;

    TableBridged*       defaults;

    Rep(lua_State* L, int index, TableBridged* defaults);
    
  private:
    
    void fill_fields(lua_State *L, int index, const string& prefix);
    
  };


  // Now comes the implementation of the internals:
  
  TableBridged::Rep::Rep(lua_State* L, int index, TableBridged* defaults) {
    fill_fields(L, index, "");
    this->defaults = defaults;
  }

  void TableBridged::Rep::fill_fields(lua_State *L, int index, const string& prefix) {
    
    if (index < 0)
      index = lua_gettop(L) + index + 1;
    
    lua_pushnil(L);  /* first key */
    
    while (lua_next(L, index) != 0) {
      
      // Now, is the key a string?
      if (lua_type(L, -2) == LUA_TSTRING) {
	string base  = lua_tostring(L, -2);
	string field = prefix + base;
	
	switch (lua_type(L,-1)) {
	  
	case LUA_TSTRING: 
	  string_fields.insert( pair<string,string>(field, lua_tostring(L,-1)));
	  break;
	  
	case LUA_TBOOLEAN:
	  bool_fields.insert( pair<string,bool>(field, lua_toboolean(L,-1)));
	  break;
	  
	case LUA_TNUMBER: 
	  double_fields.insert( pair<string,double>(field, lua_tonumber(L,-1)));
	  break;
	  
	case LUA_TTABLE:
	  if (base.length() >= 1 && base[0] != '_') {
	    table_fields.insert(field);
	    fill_fields(L, -1, field + '.');
	  }
	  break;
	}
      }
      
      // Remove value, keep key for next iteration
      lua_pop(L, 1);
    }
  }
  

  // Now comes the main part:

  TableBridged::TableBridged(lua_State* L, int index) {
    rep = new Rep (L, index, 0);
  }

  TableBridged::TableBridged(lua_State* L, TableBridged* defaults, int index) {
    rep = new Rep (L, index, defaults);
  }

  TableBridged::~TableBridged() {
    if (rep) delete rep;
  }
  
  bool TableBridged::isBooleanField(const string& field) const {
    return rep->bool_fields.count(field) > 0 || (rep->defaults && rep->defaults->isBooleanField(field));
  }
  
  bool TableBridged::isNumberField(const string& field) const {
    return rep->double_fields.count(field) > 0 || (rep->defaults && rep->defaults->isNumberField(field));
  }
  
  bool TableBridged::isStringField(const string& field) const {
    return rep->string_fields.count(field) > 0 || (rep->defaults && rep->defaults->isStringField(field));
  }
  
  bool TableBridged::isTableField(const string& field) const {
    return rep->table_fields.count(field) > 0 || (rep->defaults && rep->defaults->isTableField(field));
  }

  bool TableBridged::getBooleanField (const string& field) const {
    if (rep->bool_fields.count(field)>0)
      return rep->bool_fields.find(field)->second;
    else
      return rep->defaults->getBooleanField(field);
  }
  
  double TableBridged::getNumberField (const string& field) const {
    if (rep->double_fields.count(field)>0)
      return rep->double_fields.find(field)->second;
    else
      return rep->defaults->getNumberField(field);
  }
  
  string TableBridged::getStringField (const string& field) const {
    if (rep->string_fields.count(field)>0)
      return rep->string_fields.find(field)->second;
    else
      return rep->defaults->getStringField(field);
  }
}
