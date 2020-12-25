# BREAKING CHANGES

If a topath is bent by any of the in=, out=, bend=, etc. options, a Bezier
curve is constructed in the background.  To infer the positions of the control
points the start and end coordinate are converted to absolute coordinates.
However, this has the effect that subsequent points on the path think that the
endpoint of the topath was absolute which can lead to counter-intuitive path
construction, e.g.
```latex
\draw (2,0) to[out=0,in=180] +(1,0) -- ++(0,-1) -- +(1,0);
```
If old code relies on this behavior, this drawing will silently break!  Please
open an issue if you rely on this.

# Bug fixes

This release introduces a fix for path handling which concerns expansion of
tokens on the path in particular with respect to conditional.  Previously when
the expansion of a conditonal resulted in a frozen \relax the parser would just
give up.  Now the parser will skip over the frozen \relax and continue to
expand tokens.  Whether this will result in a meaningful expansion is up to the
user.

This release also includes other bug fixes. On GitHub you can click the commit
hashes and the issue numbers to get to the fix and the ticket, respectively.

a4c275704 #952
8a997bbc1 #954
8f37bca84 #962
3cbe5a192 #844
49e5f0a08 #654
17a95e4c5 #966
ad06895a6 #966
79e613ae1 #966
