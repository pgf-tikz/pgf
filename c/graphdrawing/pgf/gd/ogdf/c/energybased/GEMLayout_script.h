#include <pgf/gd/ogdf/c/InterfaceFromOGDF.h>
#include <ogdf/energybased/GEMLayout.h>

struct GEMLayout_script :
  scripting::declarations,
  scripting::factory<ogdf::GEMLayout>
{
  ogdf::GEMLayout* make (scripting::run_parameters* parameters) {
    using namespace ogdf;
    GEMLayout* r = new GEMLayout;

    parameters->configure_option ("GEMLayout.numberOfRounds",
                                  &GEMLayout::numberOfRounds, *r);
    parameters->configure_option ("GEMLayout.minimalTemperature",
                                  &GEMLayout::minimalTemperature, *r);
    parameters->configure_option ("GEMLayout.initialTemperature",
                                  &GEMLayout::initialTemperature, *r);
    parameters->configure_option ("GEMLayout.gravitationalConstant",
                                  &GEMLayout::gravitationalConstant, *r);
    parameters->configure_option ("GEMLayout.desiredLength",
                                  &GEMLayout::desiredLength, *r);
    parameters->configure_option ("GEMLayout.maximalDisturbance",
                                  &GEMLayout::maximalDisturbance, *r);
    parameters->configure_option ("GEMLayout.rotationAngle",
                                  &GEMLayout::rotationAngle, *r);
    parameters->configure_option ("GEMLayout.oscillationAngle",
                                  &GEMLayout::oscillationAngle, *r);
    parameters->configure_option ("GEMLayout.rotationSensitivity",
                                  &GEMLayout::rotationSensitivity, *r);
    parameters->configure_option ("GEMLayout.oscillationSensitivity",
                                  &GEMLayout::oscillationSensitivity, *r);
    parameters->configure_option ("GEMLayout.attractionFormula",
                                  &GEMLayout::attractionFormula, *r);
          
    return r;
  }
  
  void declare (scripting::script s) {
    using namespace scripting;
    using namespace ogdf;

    s.declare (key ("GEMLayout")
               .set_module ("LayoutModule", this)
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));

    s.declare (key ("GEMLayout.numberOfRounds")
               .type ("number")
               .initial ("20000")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.minimalTemperature")
               .type ("number")
               .initial ("0.005")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.initialTemperature")
               .type ("number")
               .initial ("10")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.gravitationalConstant")
               .type ("number")
               .initial ("0.0625")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.desiredLength")
               .type ("length")
               .alias_function ("function (o) return o['node pre sep'] + o['node post sep'] end")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.maximalDisturbance")
               .type ("number")
               .initial ("0")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.rotationAngle")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.oscillationAngle")
               .type ("number")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.rotationSensitivity")
               .type ("number")
               .initial ("0.01")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.oscillationSensitivity")
               .type ("number")
               .initial ("0.3")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
    s.declare (key ("GEMLayout.attractionFormula")
               .type ("number")
               .initial ("1")
               .documentation_in ("pgf.gd.doc.ogdf.energybased.GEMLayout"));
                    
  }
  
};
