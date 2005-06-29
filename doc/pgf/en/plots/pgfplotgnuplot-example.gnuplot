set terminal table; set output "plots/pgfplotgnuplot-example.table"; set format "%.5f"
plot [x=0:3.5] x*sin(x)
