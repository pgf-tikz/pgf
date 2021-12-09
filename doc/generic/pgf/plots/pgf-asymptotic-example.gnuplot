set table "plots/pgf-asymptotic-example.table"; set format "%.5f"
set samples 200.0; set parametric; plot [t=0.4:1.5] [] [] (t*t*t)*sin(1/(t*t*t)),(t*t*t)*cos(1/(t*t*t))
