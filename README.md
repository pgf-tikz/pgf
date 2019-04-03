# pgf – A Portable Graphic Format for TeX

[![Travis Build Status][travis-svg]][travis-link]

See the directory `doc/generic/pgf` for more information. See the file
`doc/generic/pgf/pgfmanual.pdf` for a manual. This
documentation also explains the installation.  See the file
`doc/generic/pgf/license/LICENSE` for license details.

Please go to https://github.com/pgf-tikz/pgf
to submit bug reports, request new features, etc.

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
$ cd pgf/doc/generic/pgf/version-for-luatex/en/
$ make
```
We recommend building at least the version for LuaTeX, as shown in the
example above because this has the broadest coverage of PGF features.
To test the animations feature you have to build the version for
dvisvgm.

[travis-svg]: https://travis-ci.com/pgf-tikz/pgf.svg?branch=master
[travis-link]: https://travis-ci.com/pgf-tikz/pgf