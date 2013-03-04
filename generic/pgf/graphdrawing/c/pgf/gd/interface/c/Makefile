MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk
MYLDFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk

BASE=../../../../..

CC=gcc
FLAGS=$(MYCFLAGS) -arch x86_64 -O2 -g -Wall -I$(BASE)/c/ogdf -I$(BASE)/c/lua_c_api/include -I$(BASE)/c 

all: InterfaceFromC.o InterfaceFromC++.o InterfaceFromOGDF.o

clean:
	rm *.o

InterfaceFromOGDF.o: InterfaceFromC++.h InterfaceFromC++.c++ InterfaceFromC.c InterfaceFromC.h \
			InterfaceFromOGDF.c++ InterfaceFromOGDF.h
	$(CC) $(FLAGS) -c -o InterfaceFromOGDF.o InterfaceFromOGDF.c++

InterfaceFromC.o: InterfaceFromC.c InterfaceFromC.h
	$(CC) $(FLAGS) -c -o InterfaceFromC.o InterfaceFromC.c

InterfaceFromC++.o: InterfaceFromC++.h InterfaceFromC++.c++
	$(CC) $(FLAGS) -c -o InterfaceFromC++.o InterfaceFromC++.c++
