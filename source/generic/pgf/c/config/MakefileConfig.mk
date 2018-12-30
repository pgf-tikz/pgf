
# Where Lua is installed
LUAPATH=/usr/local/lua52

LUAINCLUDES = $(LUAPATH)/include
LUALIBPATH = $(LUAPATH)/lib


# Where ogdf is installed
OGDFPATH=/usr/local/ogdf

OGDFINCLUDES = $(OGDFPATH)
OGDFLIBPATH = $(OGDFPATH)/_release


# Where the pgf C includes are found
PGFINCLUDES=../../../..


# Where the shared libraries should be installed (base dir)
INSTALLDIR=/usr/texbin/lib/luatex/lua


# If you need special flags:
MYCFLAGS=
MYLDFLAGS=

# Link flags for building a shared library 
SHAREDFLAGS=

# Link flags for linking against the shared Lua lib
LINKSHAREDLUA=

# Architecture flags:
ARCHFLAGS=

# The to-be-used compiler
CC=gcc


# Now read local definition, which may overwrite the above
-include $(CONFIGDIR)/LocalMakefileConfig.mk



