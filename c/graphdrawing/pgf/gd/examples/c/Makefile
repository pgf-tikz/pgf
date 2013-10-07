CONFIGDIR=../../../../../config
include $(CONFIGDIR)/MakefileConfig.mk

FLAGS=$(MYCFLAGS) $(ARCHFLAGS) -O2 -Wall -I$(LUAINCLUDES) -I$(PGFINCLUDES) 


all: SimpleDemoC.so SimpleDemoCPlusPlus.so

clean:
	rm *.o *.so

install: SimpleDemoC.so SimpleDemoCPlusPlus.so
	mkdir -p $(INSTALLDIR)/pgf/gd/examples/c
	cp SimpleDemoC.so $(INSTALLDIR)/pgf/gd/examples/c/pgf_gd_examples_c_SimpleDemoC.so
	cp SimpleDemoCPlusPlus.so  $(INSTALLDIR)/pgf/gd/examples/c/pgf_gd_examples_c_SimpleDemoCPlusPlus.so

SimpleDemoC.so: SimpleDemoC.o
	$(CC) $(FLAGS) $(SHAREDFLAGS) $(MYLDFLAGS) \
	$(LINKSHAREDLUA) \
	-o SimpleDemoC.so \
	SimpleDemoC.o ../../interface/c/InterfaceFromC.o

SimpleDemoC.o: SimpleDemoC.c
	$(CC) $(FLAGS) -c -o SimpleDemoC.o SimpleDemoC.c


SimpleDemoCPlusPlus.so: SimpleDemoCPlusPlus.o ../../interface/c/InterfaceFromC++.o  ../../interface/c/InterfaceFromC.o 
	$(CC) $(FLAGS) $(SHAREDFLAGS) $(MYLDFLAGS) \
	$(LINKSHAREDLUA) \
	-o SimpleDemoCPlusPlus.so \
	SimpleDemoCPlusPlus.o ../../interface/c/InterfaceFromC++.o ../../interface/c/InterfaceFromC.o

SimpleDemoCPlusPlus.o: SimpleDemoCPlusPlus.c++ ../../interface/c/InterfaceFromC++.h  ../../interface/c/InterfaceFromC.h
	g++ $(FLAGS) -c -o SimpleDemoCPlusPlus.o SimpleDemoCPlusPlus.c++

