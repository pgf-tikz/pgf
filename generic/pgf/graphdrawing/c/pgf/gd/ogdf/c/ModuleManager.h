#ifndef PGF_MODULEMANAGER_H
#define PGF_MODULEMANAGER_H


#include <string>
#include <typeinfo>


namespace pgf {
  
  class AlgorithmBase;
  
  class ModuleManager {
    
  public:
    
    typedef void* (*void_factory) (AlgorithmBase&);

    template<class Module>
    struct FactoryType {
      typedef Module* (*module_factory) (AlgorithmBase&);
    };

    template<class Module>
    static void registerFactory (const std::string& key,
				 const std::string& value,
				 typename FactoryType<Module>::module_factory);
    
    template<class Module>
    static typename FactoryType<Module>::module_factory getFactory (const std::string& key,
								    const std::string& value);

    template<class Module>
    static std::string keyOf (void);
    
  private:
    
    static void registerVoidFactory (const std::string& type_name,
				     const std::string& key,
				     const std::string& value,
				     void_factory f);
    static void_factory getVoidFactory (const std::string& type_name,
					const std::string& key,
					const std::string& value);

    static std::string keyOf (const std::string& type_name);
    
  };
  

  // Template implementations:
    
  template<class Module>
  void ModuleManager::registerFactory (const std::string& key,
				       const std::string& value,
				       typename FactoryType<Module>::module_factory factory)
  {
    registerVoidFactory(typeid(Module).name(), key, value, reinterpret_cast<void_factory> (factory));
  }

  template<class Module>
  typename ModuleManager::FactoryType<Module>::module_factory
  ModuleManager::getFactory (const std::string& key,
			     const std::string& value)
  {
    return reinterpret_cast<typename FactoryType<Module>::module_factory> (getVoidFactory(typeid(Module).name(), key, value));
  }

  
  template<class Module>
  std::string ModuleManager::keyOf (void)
  {
    return keyOf(typeid(Module).name());
  }
  
} // namespace

#endif
