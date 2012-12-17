MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk
MYLDFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk

CC=g++
FLAGS=-DLUA_USE_MACOS $(MYCFLAGS) -g -O2 -Wall -I../../../.. -I../../../../ogdf -I../../../../lua_c_api/include

all: Control.o GraphBridged.o TableBridged.o
	$(CC) $(FLAGS) -bundle $(MYLDFLAGS) -L../../../../lua_c_api/lib -llua -L../../../../ogdf/_release -lOGDF -o Control.so \
	Control.o GraphBridged.o TableBridged.o

Control.o: Control.cpp
	$(CC) $(FLAGS) -c -o Control.o Control.cpp

GraphBridged.o: GraphBridged.cpp
	$(CC) $(FLAGS) -c -o GraphBridged.o GraphBridged.cpp

TableBridged.o: TableBridged.cpp
	$(CC) $(FLAGS) -c -o TableBridged.o TableBridged.cpp



