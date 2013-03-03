MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk
MYLDFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk

BASE=../../../../..

CC=gcc
FLAGS=$(MYCFLAGS) -arch x86_64 -O2 -Wall  -I$(BASE)/c -I$(BASE)/c/ogdf -I$(BASE)/c/lua_c_api/include

ScriptingOGDF.so: ScriptingOGDF.o \
		../../interface/c/InterfaceFromOGDF.o \
		../../interface/c/InterfaceFromC++.o \
		../../interface/c/InterfaceFromC.o Makefile
	$(CC) $(FLAGS) -undefined dynamic_lookup -bundle $(MYLDFLAGS) \
	-L$(BASE)/c/ogdf/_release -lOGDF \
	-L$(BASE)/c/lua_c_api/lib -llua \
	-o ScriptingOGDF.so \
	ScriptingOGDF.o \
	../../interface/c/InterfaceFromC.o \
	../../interface/c/InterfaceFromC++.o \
	../../interface/c/InterfaceFromOGDF.o

ScriptingOGDF.o: ScriptingOGDF.c++ \
		../../interface/c/InterfaceFromOGDF.h \
		../../interface/c/InterfaceFromC++.h \
		../../interface/c/InterfaceFromC.h Makefile
	$(CC) $(FLAGS) -c -o ScriptingOGDF.o ScriptingOGDF.c++

clean:
	rm *.o *.so
