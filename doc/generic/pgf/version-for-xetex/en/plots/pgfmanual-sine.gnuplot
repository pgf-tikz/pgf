set terminal table
set output "pgfmanual-sine.table"
set format "%.5f"
set samples 20
plot [x=0:10] sin(x)
