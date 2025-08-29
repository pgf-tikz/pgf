-- Tests which require shell escape enabled

testfiledir  = "testfiles-shell"
checkopts    = "-interaction=nonstopmode -shell-escape"

-- files removed between different engine tests
dynamicfiles = {"*.gnuplot", "*.table"}
