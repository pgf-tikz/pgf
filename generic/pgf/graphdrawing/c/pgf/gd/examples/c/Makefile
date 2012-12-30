MYCFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk
MYLDFLAGS=-isysroot/Developer/SDKs/MacOSX10.5.sdk

CC=gcc
FLAGS=$(MYCFLAGS) -g -O2 -Wall -I../../../../lua_c_api/include

all: FastSimpleDemo.o
	$(CC) $(FLAGS) -bundle $(MYLDFLAGS) -L../../../../lua_c_api/lib -llua -o FastSimpleDemo.so \
	FastSimpleDemo.o

FastSimpleDemo.o: FastSimpleDemo.c
	$(CC) $(FLAGS) -c -o FastSimpleDemo.o FastSimpleDemo.c
