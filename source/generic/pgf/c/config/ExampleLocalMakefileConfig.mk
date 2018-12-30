MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.7.sdk
MYLDFLAGS=

ARCHFLAGS=-arch x86_64

SHAREDFLAGS=-undefined dynamic_lookup -bundle -llua -L$(LUALIBPATH)

