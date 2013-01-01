MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk
MYLDFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk

BASE=../../../../..

LIBRARIES=pgf.gd.ogdf.library

CC=g++
FLAGS=-DLUA_USE_MACOS $(MYCFLAGS) -g -O2 -Wall -I$(BASE)/c -I$(BASE)/c/ogdf -I$(BASE)/c/lua_c_api/include

all: CLibrary.o GraphBridged.o TableBridged.o AlgorithmBase.o ModuleManager.o
	$(CC) $(FLAGS) -bundle $(MYLDFLAGS) -L$(BASE)/c/lua_c_api/lib -llua -L$(BASE)/c/ogdf/_release -lOGDF -o CLibrary.so \
	CLibrary.o GraphBridged.o TableBridged.o AlgorithmBase.o ModuleManager.o

CLibrary.cpp: CLibrary.cpp.in
	lualatex --luaonly $(BASE)/lua/pgf/gd/tools/make_gd_wrap.lua $(LIBRARIES) \
	CLibrary.cpp.in pgf.gd.ogdf.c.CLibrary CLibrary.cpp

CLibrary.o: CLibrary.cpp AlgorithmBase.h GraphBridged.h TableBridged.h ModuleManager.h
	$(CC) $(FLAGS) -c -o CLibrary.o CLibrary.cpp

GraphBridged.o: GraphBridged.cpp TableBridged.h
	$(CC) $(FLAGS) -c -o GraphBridged.o GraphBridged.cpp

TableBridged.o: TableBridged.cpp
	$(CC) $(FLAGS) -c -o TableBridged.o TableBridged.cpp

AlgorithmBase.o: AlgorithmBase.cpp
	$(CC) $(FLAGS) -c -o AlgorithmBase.o AlgorithmBase.cpp

ModuleManager.o: ModuleManager.cpp
	$(CC) $(FLAGS) -c -o ModuleManager.o ModuleManager.cpp


clean:
	rm *.o
	rm CLibrary.cpp

clean_lua:
	rm CLibrary.cpp

