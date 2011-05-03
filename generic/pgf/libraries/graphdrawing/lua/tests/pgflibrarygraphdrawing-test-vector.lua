pgf.module("pgf.graphdrawing.test")
pgf.import("pgf.graphdrawing")

Sys:setVerbose(true)

a = Vector:new(2, function (n) return 0 end)
assert(a:x() == 0 and a:y() == 0)

b = Vector:new(2, function (n) return n end)
assert(b:x() == 1 and b:y() == 2)

c = a:minus(b)
assert(c:x() == -1 and c:y() == -2)

d = Vector:new(2, function (n) return n * n end)
assert(d:x() == 1 and d:y() == 4)

origin1 = Vector:new(2)
origin1:set{x = 10}
origin1:set{y = 20}
assert(origin1:x() == 10 and origin1:y() == 20)

origin2 = Vector:new(2)
origin2:set{x = 5}
origin2:set{y = 10}
assert(origin2:x() == 5 and origin2:y() == 10)

a = Vector:new(2, function (n) return 2 end)
assert(a:get(1) == 2 and a:get(2) == 2)
a:setOrigin(origin1)

assert(a:x() == 2 and a:get(1) == 12)
assert(a:y() == 2 and a:get(2) == 22)

b = Vector:new(2, function (n) return 2 end)
assert(b:get(1) == 2 and b:get(2) == 2)
b:setOrigin(origin2)

assert(b:x() == 2 and b:get(1) ==  7)
assert(b:y() == 2 and b:get(2) == 12)

c = a:plus(b)

assert(c.origin == origin1)
Sys:log('a = ' .. tostring(a))
Sys:log('a.origin = ' .. tostring(a.origin))
Sys:log('b = ' .. tostring(b))
Sys:log('b.origin = ' .. tostring(b.origin))
Sys:log('c = ' .. tostring(c))
Sys:log('c.origin = ' .. tostring(c.origin))
assert(c:x() ==  9 and c:get(1) == 19)
assert(c:y() == 14 and c:get(2) == 34)

a:setOrigin(nil)
assert(a:get(1) == 2 and a:get(2) == 2)
Sys:log('a = ' .. tostring(a))
Sys:log('origin1 = ' .. tostring(origin1))
a:setOrigin(origin1, true)
Sys:log('a = ' .. tostring(a))
assert(a:get(1) == 2 and a:get(2) == 2)
assert(a.origin == origin1)
a:setOrigin(origin2, true)
assert(a:get(1) == 2 and a:get(2) == 2)
assert(a.origin == origin2)

Sys:setVerbose(false)
