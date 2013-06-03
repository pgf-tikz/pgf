set table "plots/pgf-exp.table"; set format "%.5f"
set samples 25; plot [x=0:4] 0.05*exp(x)
