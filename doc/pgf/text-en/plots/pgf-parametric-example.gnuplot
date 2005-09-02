set terminal table; set output "plots/pgf-parametric-example.table"; set format "%.5f"
set samples 25; set parametric; plot [t=-3.141:3.141] t*sin(t),t*cos(t)
