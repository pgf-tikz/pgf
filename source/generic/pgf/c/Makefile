.PHONY : all clean examples ogdf

all:
	$(MAKE) -C graphdrawing/pgf/gd/interface/c
	$(MAKE) -C graphdrawing/pgf/gd/examples/c
	$(MAKE) -C graphdrawing/pgf/gd/ogdf/c

install_all:
	$(MAKE) -C graphdrawing/pgf/gd/interface/c install
	$(MAKE) -C graphdrawing/pgf/gd/examples/c install
	$(MAKE) -C graphdrawing/pgf/gd/ogdf/c install

examples: 
	$(MAKE) -C graphdrawing/pgf/gd/interface/c
	$(MAKE) -C graphdrawing/pgf/gd/examples/c

install_examples: 
	$(MAKE) -C graphdrawing/pgf/gd/interface/c install
	$(MAKE) -C graphdrawing/pgf/gd/examples/c install

ogdf:
	$(MAKE) -C graphdrawing/pgf/gd/interface/c
	$(MAKE) -C graphdrawing/pgf/gd/ogdf/c

install_ogdf:
	$(MAKE) -C graphdrawing/pgf/gd/interface/c install
	$(MAKE) -C graphdrawing/pgf/gd/ogdf/c install



clean:
	$(MAKE) -C graphdrawing/pgf/gd/interface/c clean
	$(MAKE) -C graphdrawing/pgf/gd/examples/c clean
	$(MAKE) -C graphdrawing/pgf/gd/ogdf/c clean

