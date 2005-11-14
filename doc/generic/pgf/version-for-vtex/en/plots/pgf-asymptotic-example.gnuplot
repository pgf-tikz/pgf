set terminal table; set output "plots/pgf-asymptotic-example.table"; set format "%.5f"
set samples 200; set parametric; plot [t=0.4:1.5] (t*t*t)*sin(1/(t*t*t)),(t*t*t)*cos(1/(t*t*t))
