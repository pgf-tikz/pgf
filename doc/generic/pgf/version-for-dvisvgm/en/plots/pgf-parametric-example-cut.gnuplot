set table "plots/pgf-parametric-example-cut.table"; set format "%.5f"
set samples 25; set parametric; plot [t=-3.141:3.141] [0:1] [] t*sin(t),t*cos(t)
