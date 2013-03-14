include ../../MakefileConfig.mk

FLAGS=$(MYCFLAGS) $(ARCHFLAGS) -O2 -Wall -I$(LUAINCLUDES) -I$(PGFINCLUDES)

all: FastSimpleDemo.so FastSimpleDemoC++.so FastSimpleDemoOGDF.so

FastSimpleDemo.so: FastSimpleDemo.o 
	$(CC) $(FLAGS) -undefined dynamic_lookup -bundle $(MYLDFLAGS) -o FastSimpleDemo.so \
	FastSimpleDemo.o ../../interface/c/InterfaceFromC.o

FastSimpleDemo.o: FastSimpleDemo.c
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