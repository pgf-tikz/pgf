
# Which version of Lua to use. This depends on the version of luatex
LUAVERSION=52

# Where the lua header files for this particular version can be found
LUAINCLUDES=/usr/local/lua$(LUAVERSION)/include

# Where the pgf includes are found
PGFINCLUDES=../../../..

# If you need special flags:
MYCFLAGS=
MYLDFLAGS=

# Architecture flags:
ARCHFLAGS=-arch x86_64

# The to-be-used compiler
CC=gcc



