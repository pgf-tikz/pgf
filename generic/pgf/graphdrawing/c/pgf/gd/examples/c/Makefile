MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk
MYLDFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk

CC=gcc
FLAGS=$(MYCFLAGS) -arch x86_64 -g -O2 -Wall -I../../../../lua_c_api/include -I../../../../

all: FastSimpleDemo.o 
	$(CC) $(FLAGS) -undefined dynamic_lookup -bundle $(MYLDFLAGS) -L../../../../lua_c_api/lib -llua -o FastSimpleDemo.so \
	FastSimpleDemo.o ../../interface/c/InterfaceFromC.o

FastSimpleDemo.o: FastSimpleDemo.c
	$(CC) $(FLAGS) -c -o FastSimpleDemo.o FastSimpleDemo.c
