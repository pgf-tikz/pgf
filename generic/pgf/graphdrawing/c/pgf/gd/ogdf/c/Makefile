MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk
MYLDFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk

BASE=../../../../..

CC=gcc
FLAGS=$(MYCFLAGS) -arch x86_64 -O2 -Wall  -I$(BASE)/c -I$(BASE)/c/ogdf -I$(BASE)/c/lua_c_api/include

ogdf_script.so: ogdf_script.o \
		../../interface/c/InterfaceFromOGDF.o \
		../../interface/c/InterfaceFromC++.o \
		../../interface/c/InterfaceFromC.o Makefile
	$(CC) $(FLAGS) -undefined dynamic_lookup -bundle $(MYLDFLAGS) \
	-L$(BASE)/c/ogdf/_release -lOGDF \
	-L$(BASE)/c/lua_c_api/lib -llua \
	-o ogdf_script.so \
	ogdf_script.o \
	../../interface/c/InterfaceFromC.o \
	../../interface/c/InterfaceFromC++.o \
	../../interface/c/InterfaceFromOGDF.o

ogdf_script.o: ogdf_script.c++ \
		../../interface/c/InterfaceFromOGDF.h \
		../../interface/c/InterfaceFromC++.h \
		../../interface/c/InterfaceFromC.h Makefile
	$(CC) $(FLAGS) -c -o ogdf_script.o ogdf_script.c++

clean:
	rm *.o *.so
