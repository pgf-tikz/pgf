pgf.module("pgf.graphdrawing.test")
pgf.import("pgf.graphdrawing")

a = Vector:new(2, function (n) return 0 end)
assert(a:x() == 0 and a:y() == 0)

b = Vector:new(2, function (n) return n end)
assert(b:x() == 1 and b:y() == 2)

c = a:minus(b)
assert(c:x() == -1 and c:y() == -2)

d = Vector:new(2, function (n) return n * n end)
assert(d:x() == 1 and d:y() == 4)
