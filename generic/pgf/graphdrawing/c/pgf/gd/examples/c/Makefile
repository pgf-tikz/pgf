MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk
MYLDFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk

BASE=../../../../..

CC=gcc
FLAGS=$(MYCFLAGS) -arch x86_64 -O2 -Wall -g -I$(BASE)/c -I$(BASE)/c/ogdf -I$(BASE)/c/lua_c_api/include

all: FastSimpleDemo.so FastSimpleDemoC++.so FastSimpleDemoOGDF.so


FastSimpleDemo.so: FastSimpleDemo.o  ../../interface/c/InterfaceFromC.o Makefile
	$(CC) $(FLAGS) -undefined dynamic_lookup -bundle $(MYLDFLAGS) -L$(BASE)/c/lua_c_api/lib -llua  -o FastSimpleDemo.so \
	FastSimpleDemo.o ../../interface/c/InterfaceFromC.o

FastSimpleDemo.o: FastSimpleDemo.c ../../interface/c/InterfaceFromC.h
	$(CC) $(FLAGS) -c -o FastSimpleDemo.o FastSimpleDemo.c


FastSimpleDemoC++.so: FastSimpleDemoC++.o ../../interface/c/InterfaceFromC++.o  ../../interface/c/InterfaceFromC.o Makefile
	g++ $(FLAGS) -undefined dynamic_lookup -bundle $(MYLDFLAGS) -L$(BASE)/c/lua_c_api/lib -llua -o FastSimpleDemoC++.so \
	FastSimpleDemoC++.o ../../interface/c/InterfaceFromC++.o ../../interface/c/InterfaceFromC.o
	cp FastSimpleDemoC++.so FastSimpleDemoCpp.so

FastSimpleDemoC++.o: FastSimpleDemoC++.c++ ../../interface/c/InterfaceFromC++.h  ../../interface/c/InterfaceFromC.h
	g++ $(FLAGS) -c -o FastSimpleDemoC++.o FastSimpleDemoC++.c++


FastSimpleDemoOGDF.so: FastSimpleDemoOGDF.o ../../interface/c/InterfaceFromOGDF.o ../../interface/c/InterfaceFromC++.o  ../../interface/c/InterfaceFromC.o Makefile
	g++ $(FLAGS) -undefined dynamic_lookup -bundle $(MYLDFLAGS) -L$(BASE)/c/ogdf/_release -lOGDF \
	-L$(BASE)/c/lua_c_api/lib -llua -o FastSimpleDemoOGDF.so \
	FastSimpleDemoOGDF.o ../../interface/c/InterfaceFromC++.o ../../interface/c/InterfaceFromC.o \
	../../interface/c/InterfaceFromOGDF.o

FastSimpleDemoOGDF.o: FastSimpleDemoOGDF.c++ ../../interface/c/InterfaceFromOGDF.h ../../interface/c/InterfaceFromC++.h  ../../interface/c/InterfaceFromC.h
	g++ $(FLAGS) -c -o FastSimpleDemoOGDF.o FastSimpleDemoOGDF.c++

clean:
	rm *.o *.so