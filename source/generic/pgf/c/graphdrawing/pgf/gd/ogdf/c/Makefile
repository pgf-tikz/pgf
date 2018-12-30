CONFIGDIR=../../../../../config
include $(CONFIGDIR)/MakefileConfig.mk

FLAGS=$(MYCFLAGS) $(ARCHFLAGS) -O2 -Wall -I$(LUAINCLUDES) -I$(PGFINCLUDES) -I$(OGDFINCLUDES)

all: ogdf_script.so SimpleDemoOGDF.so

clean:
	rm *.o *.so

install: ogdf_script.so SimpleDemoOGDF.so
	mkdir -p $(INSTALLDIR)/pgf/gd/ogdf/c
	cp SimpleDemoOGDF.so $(INSTALLDIR)/pgf/gd/ogdf/c/pgf_gd_ogdf_c_SimpleDemoOGDF.so
	cp ogdf_script.so $(INSTALLDIR)/pgf/gd/ogdf/c/pgf_gd_ogdf_c_ogdf_script.so


ogdf_script.so: ogdf_script.o InterfaceFromOGDF.o ../../interface/c/InterfaceFromC++.o ../../interface/c/InterfaceFromC.o 
	$(CC) $(FLAGS) $(SHAREDFLAGS) $(MYLDFLAGS) \
	-L$(OGDFLIBPATH) -lOGDF \
	$(LINKSHAREDLUA) \
	-o ogdf_script.so \
	ogdf_script.o \
	InterfaceFromOGDF.o \
	../../interface/c/InterfaceFromC.o \
	../../interface/c/InterfaceFromC++.o 

ogdf_script.o: ogdf_script.c++ \
		InterfaceFromOGDF.h \
		../../interface/c/InterfaceFromC++.h \
		../../interface/c/InterfaceFromC.h Makefile
	$(CC) $(FLAGS) -c -o ogdf_script.o ogdf_script.c++


SimpleDemoOGDF.so: SimpleDemoOGDF.o \
			InterfaceFromOGDF.o \
			../../interface/c/InterfaceFromC++.o \
			../../interface/c/InterfaceFromC.o Makefile
	$(CC) $(FLAGS) $(SHAREDFLAGS) $(MYLDFLAGS) \
	$(LINKSHAREDLUA) \
	-L$(OGDFLIBPATH) -lOGDF \
	-o SimpleDemoOGDF.so \
	SimpleDemoOGDF.o ../../interface/c/InterfaceFromC++.o ../../interface/c/InterfaceFromC.o \
	InterfaceFromOGDF.o

SimpleDemoOGDF.o: SimpleDemoOGDF.c++ \
			InterfaceFromOGDF.h \
			../../interface/c/InterfaceFromC++.h \
			../../interface/c/InterfaceFromC.h
	$(CC) $(FLAGS) -I$(OGDFINCLUDES) -c -o SimpleDemoOGDF.o SimpleDemoOGDF.c++



InterfaceFromOGDF.o: ../../interface/c/InterfaceFromC++.h ../../interface/c/InterfaceFromC.h \
			InterfaceFromOGDF.c++ InterfaceFromOGDF.h
	$(CC) $(FLAGS) -c -o InterfaceFromOGDF.o InterfaceFromOGDF.c++

