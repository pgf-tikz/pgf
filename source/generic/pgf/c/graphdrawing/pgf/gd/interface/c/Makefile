CONFIGDIR=../../../../../config
include $(CONFIGDIR)/MakefileConfig.mk

FLAGS=$(MYCFLAGS) $(ARCHFLAGS) -O2 -Wall -I$(LUAINCLUDES) -I$(PGFINCLUDES)

all: InterfaceFromC.o InterfaceFromC++.o

clean:
	rm *.o

install:

InterfaceFromC.o: InterfaceFromC.c InterfaceFromC.h
	$(CC) $(FLAGS) -c -o InterfaceFromC.o InterfaceFromC.c

InterfaceFromC++.o: InterfaceFromC++.h InterfaceFromC.h InterfaceFromC++.c++ 
	$(CC) $(FLAGS) -c -o InterfaceFromC++.o InterfaceFromC++.c++
