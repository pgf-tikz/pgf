#include <pgf/gd/ogdf/c/ModuleManager.h>

using namespace std;

#include <map>
#include <stdexcept>

namespace pgf {
  
  static map<string, ModuleManager::void_factory> factories;
  static map<string, string> keys;

  void ModuleManager::registerVoidFactory (const std::string& type_name,
					   const std::string& key,
					   const std::string& value,
					   ModuleManager::void_factory f)
  {
    // Register the type_name:
    if (keys.count(type_name) == 0) {
      keys[type_name] = key;
    } else if(keys[type_name] != key) {
      throw logic_error ("different keys used for same type name");
    }
    factories[type_name + '/' + key + '/' + value] = f;
  }
  
  ModuleManager::void_factory ModuleManager::getVoidFactory (const std::string& type_name,
							     const std::string& key,
							     const std::string& value)
  {
    return factories[type_name + '/' + key + '/' + value];
  }
  
  string ModuleManager::keyOf (const string& type_name)
  {
    return keys[type_name];
  }
  
}
