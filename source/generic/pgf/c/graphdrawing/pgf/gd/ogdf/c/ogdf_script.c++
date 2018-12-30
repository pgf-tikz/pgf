#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>

#include "module/module_script.h"

#include "layered/layered_script.h"
#include "energybased/energybased_script.h"
#include "misclayout/misclayout_script.h"
#include "planarity/planarity_script.h"


extern "C" int luaopen_pgf_gd_ogdf_c_ogdf_script (struct lua_State *state) {
  
  scripting::script s (state);

  s.declare (new module_script);
  s.declare (new layered_script);
  s.declare (new energybased_script);
  s.declare (new misclayout_script);
  s.declare (new planarity_script);
  
  return 0;
}

