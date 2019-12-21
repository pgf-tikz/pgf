# pgf – A Portable Graphic Format for TeX

[![Travis Build Status][travis-svg]][travis-link]

PGF is a TeX macro package for generating graphics. It is platform-
and format-independent and works together with the most important TeX
backend drivers, including `pdftex` and `dvips`. It comes with a
user-friendly syntax layer called Ti*k*Z.

See the directory `doc/generic/pgf` for more information. See the file
`doc/generic/pgf/pgfmanual.pdf` (also available from 
https://pgf-tikz.github.io/pgf/pgfmanual.pdf) for a manual. This
documentation also explains the installation.  See the file
`doc/generic/pgf/license/LICENSE` for license details.

Please go to the official repository at https://github.com/pgf-tikz/pgf or the
official mailing list at https://tug.org/mailman/listinfo/pgf-tikz to submit
bug reports, request new features, etc.

## Installation

In general you should just use the version of PGF that is shipped by
your TeX distribution.  See their documentation on how to install
packages.

If you are feeling adventurous you can install the latest development
version in TeX Live from our tlcontrib repository.
```console
$ tlmgr repository add http://pgf-tikz.github.io/pgf/tlnet pgf-development
$ tlmgr pinning add pgf-development "*"
$ tlmgr update --self --all
$ tlmgr install pgf --reinstall
```

## Development

Currently PGF does not have a comprehensive test suite to check for
regressions, so for now we check for bugs by building the manual for
each commit.  To build the manual locally you can either copy the PGF
repository into your texmf tree (not recommended) or use the usertree
option of TeX Live.  For the usertree option on GNU/Linux, follow
these steps:
```console
$ git clone https://github.com/pgf-tikz/pgf
$ tlmgr init-usertree --usertree pgf
$ export TEXMFHOME=`realpath pgf`
$ texlua build.lua manual luatex
```
We recommend building at least the version for LuaTeX, as shown in the
example above because this has the broadest coverage of PGF features.
To test the animations feature you have to build the version for
dvisvgm.

[travis-svg]: https://travis-ci.com/pgf-tikz/pgf.svg?branch=master
[travis-link]: https://travis-ci.com/pgf-tikz/pgf
