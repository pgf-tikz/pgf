#ifndef PGF_TABLEBRIDGED_H
#define PGF_TABLEBRIDGED_H

extern "C" {
#include <lua.h>
}

#include <string>

namespace pgf {
  
  class TableBridged {

  private:

    class Rep;
    Rep* rep;

  public:

    // Create a TableBridged from a table on the top of the Lua stack
    TableBridged(lua_State *L, int index=-1);
    TableBridged(lua_State *L, TableBridged* defaults, int index=-1);
    ~TableBridged();

    bool          isNumberField  (const std::string& field) const;
    bool          isBooleanField (const std::string& field) const;
    bool          isStringField  (const std::string& field) const;
    bool          isTableField   (const std::string& field) const;

    bool          getBooleanField (const std::string& field) const;
    double        getNumberField  (const std::string& field) const;
    std::string   getStringField  (const std::string& field) const;

  };

}

#endif
