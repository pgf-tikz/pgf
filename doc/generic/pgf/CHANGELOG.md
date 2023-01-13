# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [3.1.10] - 2023-01-13 Henri Menke

Even though this release is not too heavy on user-facing additions it has seen a
lot of contributed changes. Thanks to everyone who volunteered their time!

### BREAKING CHANGES

- `\pgfversiondatetime` and `\pgfrevisiondatetime` have been removed.
  `\pgfversiondate` and `\pgfrevisiondate` now use the format `YYYY-MM-DD`.
  `\pgfrevision{,date}` and `\pgfversion{,date}` are synonyms for now, but the
  revision should eventually gain back its original meaning.  However, as of now
  this is not supported by l3build.
- Many operations in `pgfkeys` used to use `\csname` directly which lets the
  given csname become `\relax` in case it wasn't defined. This resulted in some
  leakage of accidentally `\relax`ed keys into the global scope. This has been
  cleaned up a little. To preserve compatibility macros that used to expand to a
  `\relax`ed csname now expand to a primitive `\relax`. This affects the
  user-level commands `\pgfkeysgetvalue` and `\pgfkeysgetvalueof`. For the
  former the change should not be visible except for the number of expansions
  required. For `\pgfkeysgetvalueof`, however, the behavior is manifestly
  different in that it will now expand to an alias for the primitive `\relax` in
  case the value is undefined instead of a `\relax`ed csname. It has always been
  semantically wrong to assign to the result of `\pgfkeysgetvalueof`, but now it
  will have undesired side-effects. Therefore this change is breaking.
- The `textures` and `vtex` drivers have been deprecated. Both engines are no
  longer in active development and lack eTeX features which are required for
  quite some time in PGF.
- The file `pgfutil-common-lists.tex` is deprecated and therefore no longer
  `\input` by `pgfutil-common.tex`. The macros from this file are specifically
  meant for pgfplots and are not used in PGF at all.

### Added

- l3build support for packaging PGF/TikZ
- Add Matrix chat to README
- Add rhombic polihedra #1022
- Add Developer Certificate of Origin (DCO) to Pull Request template and enforce
- Add test set for `graphdrawing` (gd) 
- pgfkeys gained support for loading libraries
- Add dependabot to keep GitHub Actions up to date

### Fixed

- Wrap logic gate symbol in `\pgfinterruptpicture` for shapes in library
  `shapes.gates.logic.IEC`
- Remove superfluous `;` for shape `arrow box`
- Remove superfluous `/utils/exec` in animations
- Gobble `\pgf@stop` when parsing finishes in animations
- Add missing `\pgf@sys@tonumber` before `<dimen>` in drivers and animations
- Rewrite `dash expand off`
- Better unknown key error msg in decorations
- Fix `\let` in drivers for two csnames #1088
- Protect against comma in pgfkeys arguments #389
- Let active `"` expand to non-active `"` in pgfmath #1062
- Protect against comma in `/tikz/rotate fit` argument and make it
  eagerly evaluated #1071
- Set pics/code in angle #1068
- Fix for externalization and horizontal mode
- Avoid spurious tokens in `\pgfcalendarifdate` expansion
- Remove angle restriction #1048
- Fix compatibility of `external` lib with `fadings` lib
- Only clearpage and flush `\pgfutil@everybye` if non-empty #724
- Fix foreach documentation #1039
- Fix pgfmathless documentation #1040
- Blend mode as array is deprecated #1037
- One-step expansion for `\pgfmathrandomitem` in pgfmath #1033
- Check whether expanded is a primitive in all engines
- Reinsert the last token when giving up on a path #1025
- Make `/tikz/local bounding box` aware of `name prefix` and `name suffix`
- Add empty Pattern dictionary to Resources dictionary
- Spelling and typo fixes in the manual
- Update Debian installation instructions
- Suppress white space at line end when `datavisualization` reads from a file 
  #1112
- Form-only patterns have no specified color #1122 
- Make `graphdrawing` work with `name prefix` and `name suffix` options #1087
- pgfkeys was a bit too relaxed around `\relax` #1132
- Remove spurious spaces for `3d view` #1151
- Fix incorrectly placed matrix delimiters for implicitly positioned nodes #1102
- Use `/.append` to fix a wrong usage of `/.add` in pgfmanual #1201

### Changed

- Cleanup `\newif`s
- Remove unused scripts
- Remove experiments/ folder
- Simplify loading by delegating to top-level files
- Promote `Missing character` to errors in building manual
- Flatten the doc tree
- Ensure `\tracinglostchars<3` in `\pgf@picture`
- Use descriptive workflow job ids
- Ensure `doc` v2 is loaded for pgfmanual
- Ensure active `^^M` is non-expandable in `codeexample`

### Contributors

- 3geek14
- BeneIII
- graue70
- Gábor Braun
- Joel Coffman
- Jonathan Spratte
- Joseph Wright
- Mario Frasca
- Michael Kuron
- Michal Hoftich
- muzimuzhi
- PhelypeOleinik
- QJLc
- Stefan Pinnow

## [3.1.9a] - 2021-05-15 Henri Menke

Emergency release to fix pgfplots which depends on unreleased parts of PGF.

### Changed

- Merge pull request #1012 from TorbjornT/incontrol_doc
- Specify that relative coord is to end point
- Merge pull request #1005 from kechtel/patch-1
- Fix typo in guidelines on graphics
- CI: Expire the cache
- Merge pull request #1004 from michal-h21/patch-1
- Update pgfsys-dvisvgm4ht.def
- Merge pull request #1003 from tknuth/patch-1
- fixed typo
- Merge pull request #977 from muzimuzhi/pgf-point-node-border
- adjust comments
- \pgfpointshapeborder: measure by distance < 0.02pt
- \pgfpointshapeborder: more doc words
- doc: use paired \`\` and ''
- \pgfpointshapeborder: doc new behavior
- pgf/shapes: add warning when \pgfpointshapeborder gives up
- pgf/shapes: improve \pgfpointshapeborder, #908
- Merge pull request #1002 from muzimuzhi/edef-keys
- pgfkeys: enhance edef keys, #305
- fixup! build: copy the README into the TDS archive
- build: copy the README into the TDS archive

### Contributors

- Christoph Kecht
- Dr. Tobias Knuth
- Michal Hoftich
- muzimuzhi
- Torbjørn T

## [3.1.9] - 2021-03-02 Henri Menke

### Fixed

This release introduces a fix for blend mode with the dvips driver and
improvements for handling expandable material that appears on a path.

### Changed

- Merge pull request #996 from muzimuzhi/dvips-blend-mode
- dvips: fix displacement after blend group, #995
- Revert "syntax is similar to METAPOST not METAFONT"
- Merge pull request #994 from itmm/master
- syntax is similar to METAPOST not METAFONT
- Merge pull request #992 from joel-coffman/dev/fix-code-2-args-documentation
- Correct documentation for .code 2 args second arg
- Merge pull request #987 from muzimuzhi/doc-typo
- doc: fix typo #986
- Merge pull request #981 from muzimuzhi/fix-tikz@handle
- Apply suggestions from code review
- tikz: fix uses of \pgfutil@switch
- Merge pull request #979 from muzimuzhi/doc-install-only
- doc/fpu: fpu: mark /pgf/fpu/install only as not experimental
- Fix and document dim() #964
- Merge pull request #976 from muzimuzhi/tikz-math
- tikz/math: gobble spaces between for list and loop body
- Merge pull request #970 from muzimuzhi/reset-tikz@expandcount
- tikz: retry to handle \relax on path #966
- tikz/calendar: switch over \pgf@let@token in \tikz@lib@cal@handle
- Merge pull request #973 from schtandard/spurious_show
- Remove a spurious \show
- Merge pull request #972 from alisaaalehi/patch-1
- doc: fix typo
- tikz: switch over \pgf@let@token in \tikz@handle
- tikz: improve \tikz@expandcount handling
- tikz: reset \tikz@expandcount more frequent #969

### Contributors

- Ali Salehi
- Joel Coffman
- muzimuzhi
- schtandard
- Timm Knape

## [3.1.8b] - 2020-12-27 Henri Menke

Hotfix for handling of TeX conditionals on a path.  We can't forward \relax and
frozen \relax through the parser because there is existing code that relies on
this.

The recommendation is to use expandable conditionals where possible.

## [3.1.8a] - 2020-12-27 Henri Menke

Hotfix for the new topaths handling.  One instance did not yet properly
preserve relative coordinates.

## [3.1.8] - 2020-12-25 Henri Menke

### BREAKING CHANGES

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

### Fixed

This release introduces a fix for path handling which concerns expansion of
tokens on the path in particular with respect to conditional.  Previously when
the expansion of a conditonal resulted in a frozen \relax the parser would just
give up.  Now the parser will skip over the frozen \relax and continue to
expand tokens.  Whether this will result in a meaningful expansion is up to the
user.

This release also includes other bug fixes. On GitHub you can click the commit
hashes and the issue numbers to get to the fix and the ticket, respectively.

- a4c275704 #952
- 8a997bbc1 #954
- 8f37bca84 #962
- 3cbe5a192 #844
- 49e5f0a08 #654
- 17a95e4c5 #966
- ad06895a6 #966
- 79e613ae1 #966

### Changed

- CI: Use GitHub Actions from pgf-tikz/actions
- Remove empty or outdated files
- Preserve coordinate relativity across ..
- Merge pull request #967 from muzimuzhi/handle-relax
- fixup! doc: Add note on expandsion of path operations #966
- Remove spurious spaces, terminate \advance in time
- tikz: handle \relax and frozen \relax on path #966
- doc: Add note on expandsion of path operations #966
- Merge pull request #961 from muzimuzhi/improve-doc
- doc: relation of /.code & /.initial will remain
- Only force signed releases #962
- doc: clarify /.code keys don't respect /.initial #654
- Added doc for \pgfpointtransformed #844
- Merge pull request #959 from muzimuzhi/improve-doc
- doc: clarify path or full key start with slash #904
- Merge pull request #956 from muzimuzhi/improve-doc
- pgfmathdeclarerandomlist: improve doc and code comment
- Merge pull request #955 from Ordoviz/master
- pgfmathrandominteger: reordering of arguments incomplete #954
- fpu: mark /pgf/fpu/install only as not experimental
- Fix typos in manual
- Merge branch 'PimpLuaExamples' of https://github.com/Mo-Gul/pgf
- docs: set terminal table -> set table #952
- correct codeexample preamble entries in Lua file
- made some "normal" `codeexample`s compile again (when extracted)
- just added end line commata at the end of values/styles
- added hints which libraries need to be loaded as well to make the example in
  `pgfmanual-en-tikz-graphs.tex` work closes issue #755)

### Contributors

- Lennard Hofmann
- muzimuzhi
- Stefan Pinnow

## [3.1.7a] - 2020-12-01 Henri Menke

### Fixed

Another issue with the new LaTeX hook mechanism surfaced in the external
library which is being worked around now.

This release also includes other bug fixes. On GitHub you can click the commit
hashes and the issue numbers to get to the fix and the ticket, respectively.

- 3c46a6974 #947

### Changed

- Assisted release script
- Attempt uploading to CTAN in CI
- Attempt signing builds in CI
- Protect possible parentheses in computing looseness #947
- Superficial fix for hook ordering problem
- Add pgf-parametric-example-cut.table

## [3.1.7] - 2020-11-21 Henri Menke

### Fixed

Mostly spurious spaces have been fixed and some code has been adapted to work
with the latest LaTeX release.  In principle it should still be backwards
compatible to older LaTeX releases but regressions cannot be excluded.

Some other bug fixes:

- 67295ec8 #946
- 74b2cc30 #934
- 8beaf970 #928
- bf46600f #654
- 1e8ee728 #930

### Changed

- CI: Create release from tag
- pgffor: new expand list option
- Fix spurious spaces #946
- Merge pull request #943 from agrahn/offpagefading
- hiding smask in the PS viewer
- Merge pull request #940 from Ordoviz/patch-1
- Merge pull request #941 from Skillmon/improve-parser-doc
- macros are 'letters' for pgfparser as well
- fix comment in example code
- minor change to pgfparserletter
- minor change to pgfparserdefunknown
- minor change to pgfparserlet
- more info for pgfparserdef
- typos
- more precise pgfparserreinsert description
- [doc] Fix typo
- Fix trailing else problem in pgfkeys
- Merge branch 'pgfkeys-small-fixing' of https://github.com/muzimuzhi/pgf
- Always place shadings in TLT in LuaTeX #934
- DOC: typo fix in en-tikz-actions
- pgfkeys: fix spurious spaces in "/errors" keys
- pgfkeys: in "/.add code", ensure `/.@cmd` is long
- Random shifts to fix output routine shenenigans #928
- Revert "pgfkeys: make `.initial` compatible with `.code`, fix #654"
- doc: various minor fix
- doc: minor fix, #930

### Contributors

- Alexander Grahn
- Andras Deak
- Henri Menke
- Jonathan Spratte
- Lennard Hofmann
- muzimuzhi

## [3.1.6a] - 2020-10-01 Henri Menke

Hotfix for `intersections` library.  In the last version
`\pgfintersectionoflines` was set to always return the intersection in the
untransformed coordinate system #889. This however broke the interplay with
other coordinate transformations and had to be reverted.

### Changed

- Revert "Invert transform before assigning intersection #889"
- Omit missing library and fix spurious space
- Fix spurious spaces in pgfmathparse with fpu #508 #915
- Revert "Added sanity check for the catcode of '$' to avoid incompatibilities with onlyamsmath package"

## [3.1.6] - 2020-09-28 Henri Menke

### Acknowledgements

This release stands in the name of the two contributors **Alexander Grahn** and
**Yukai Chou** without whom this release would not have been nearly as great.
Thank you very much!

### BREAKING CHANGES

- In the last version, in an attempt to fix updating `local bounding box` in a
  clipping scope the `\pgf@path@size@hook` in `\pgf@protocolsizes` was set to be
  executed unconditionally.  Unfortunately, this broke all other uses of `local
  bounding box` and has been reverted.  If you need to use `local bounding box`
  in a clipping scope, use the `overlay` option.

- The recent Ghostscript version 9.53 has changed the primitives for
  transparency, blend mode, and transparency groups.  These are now supported by
  PGF and should in principle go unnoticed by the user. (Thanks Alexander
  Grahn!)

- `\pgfintersectionoflines` will now always return the intersection in the
  untransformed coordinate system.  This however requires an additional
  `\pgftransforminvert` which comes with a loss of precision and can potentially
  lead to `Dimension too large` errors in edge cases.

- PGF now supports the new hook management that will be introduced in LaTeX
  2020/10/01.  While this should not lead to any noticeable changes, please look
  out for breakages with overlays and the `current page` nodes.  Please report
  problems on the PGF or LaTeX issue trackers.

### Added

You can read about these new features in the manual:

- PS-3 functional shading, opacity masks (fadings) and image masks for
  dvips. (Thanks Alexander Grahn!)

- The `dvisvgm4ht` driver developed by Michal Hoftich has been merged into
  PGF/TikZ.

- The `pgfparser` module has been slightly refactored such that it can be used
  without loading all of PGF.

- The order in which the inner styles are applied in a `\matrix` is now
  configurable. #867

- The file `pgfmanual-en-macros.tex` is developed specifically for typesetting
  the PGF manual, however, many other package developers have found it useful
  and made good use of it.  To this end, we now install
  `pgfmanual-en-macros.tex` into a directory that is searched by kpathsea such
  that developers no longer have to copy the file into their own distribution.

- The CI system was switched from Travis CI to GitHub Actions for better
  integration with GitHub and direct deployment of build artefacts to the status
  page.

### Removed

- The `bbox` library introduced in PGF 3.1.5 was removed. I further recommend
  that if there are files containing `bbox` code left over from a previous
  version that these are removed to avoid potential issues.

### Fixed

Lots of bug fixes.  On GitHub you can click the commit hashes and the issue
numbers to get to the fix and the ticket, respectively.

- 44bb29fd #900 #923
- 2ae12cb4 #924
- f6039046 #918
- 908db001 #889
- 71becc18 #909
- 83069dce #508 #915
- c5a6dbbb #671
- 0f52b63c #654
- 17e588d5 #912
- 197450c0 #755
- eaf9c096 #888
- d96c3f2f #843
- 6a0e08db #640 #839
- bd8c9c45 #876
- 4773c311 #748
- 2145bcfb #872
- c44960e7 #872
- 1ca59c70 #871
- 65bcaaff #867
- 68bebd7a #823
- 1c380999 #808
- 494bd677 #861
- 1e520dc7 #863
- 1efebdf7 #856
- e1eac8af #859
- ca1f30e1 #795
- 6b79a6dc #855
- a7cccca0 #848
- 7098976d #855
- 8095bc57 #846
- 08041e44 #855
- 730a3437 #853
- ff3fe4c4 #852
- 6e8397b5 #851
- 6c88ed94 #851
- e6e91c40 #848
- 29de799f #845
- 2a6eaefb #840
- 357bc059 #837
- 15c943b7 #831
- 314a00ad #829
- 03aa54d2 #816
- 4e1529ba #822
- 4ccfe0d4 #813
- 1f21e3ba #819 #698

### Changed

- Activate CTAN zip action
- Adapt shipout to new hook management #900 #923
- improved functional shading (dvips); \pgfsys@definemask fixed
- More missing args to \pgfmath@error
- Add missing args to \pgfmath@error
- Replace \pgfmath@PackageError by \pgfmath@error
- Use \pgfmath@tonumber in pgfmath (fixes #924)
- Merge branch 'master' of https://github.com/erihe251/pgf
- fixed typo notes -> nodes
- Merge branch 'pgfkeys-doc' of https://github.com/muzimuzhi/pgf into master
- Remove unused `.expand two once` #918
- [doc] pgfkeys: update examples of ".search also"
- [doc] pgfkeys: document \pgfkeyssetevalue
- [doc] pgfkeys: unify order of ".code" and ".style"
- [doc] pgfkeys: typo
- Invert transform before assigning intersection #889
- pgfsys-xetex: sync with upstream, #909
- Provide a convenient workaround for #508 (also #915)
- pgfkeys: avoid \pgfkeysalso used in ".search also"
- Fix CI badge; add PR template
- Merge branch 'ps3shading-fading-imgmask-dvips-3' of https://github.com/agrahn/pgf
- Merge branch 'fix-pgfkeys' of https://github.com/muzimuzhi/pgf
- pgfkeys: make `.initial` compatible with `.code`, fix #654
- pgfkeys: specially treat `.style n args={1}{...}`, fix #912
- fixing code lines with assignments, as requested in the review
- Merging upstream changes into ps3shading-fading-imgmask-dvips-3
- Switch to GitHub Actions
- optimizing sampling procedure (funct shadings, dvips)
- merging recent upstream changes
- addressing requested changes from review
- doc: correct some typos
- [doc] pgffor: replace \diameter with \r
- [doc] fix typo, s/to/two/ in "between to point"
- PS-3 functional shading for dvips
- PS-3 shadings, opacity masks (fadings) and image masks for dvips
- doc: remove reference to old "-to" arrow
- Merge branch 'context-module-wrap' of https://github.com/LeonardKoenig/pgf
- Update build instructions [ci skip]
- context: Fix 'module wrapping error'
- Merge branch 'minor-change' of https://github.com/muzimuzhi/pgf
- Fix critical typo in documentation
- [doc] enhanced consistency
- [doc] fix wrong description for \pgfmathsubtract
- fix typo in comment
- Add library loading hints #755
- Fixed typo: of -> off
- Fixed typo, if -> of
- gs-9.53 transparency; blend mode; transparency groups
- Install pgfmanual-en-macros.tex
- Revert "- removed some trailing spaces and replaced TABs with spaces"
- Merge branch 'doc-fix-pdf-dest' of https://github.com/muzimuzhi/pgf
- Fix pt/bp confusion in dvipdfmx driver #888
- [doc] rename counter, "dummy" -> "pgfmanualentry"
- [script] use value of "maxruns" in not-converge message
- [doc] move two key labels inside "key" env
- [doc] fix typo
- [doc] fix wrong pdf dest
- [doc] external lib
- transform shape clashes with label position #843
- Add options to Lua examples #640 #839
- Resolve clash of object ids in SVG #876
- Decorations are implicitly sloped #748
- DOC:matrix:Use only default colorsin example
- DOC:matrix: Adjust the column color in example
- Fix merge conflicts
- Remove bbox library
- followed @joulev's suggestion
- Update doc/generic/pgf/text-en/pgfmanual-en-library-fpu.tex
- Update doc/generic/pgf/text-en/pgfmanual-en-library-decorations.tex
- added `codeexample` plus some text to the `decorations` library manual as
  suggested in pull request #872
- removed braces as suggested in pull request #872
- "improved" colors given in the `codeexample` of pull request #871
- added reference from `matrix` library to "basic" matrix section
- adapted formatting in `pgf/text-en/pgfmanual-en-tikz-matrices.tex`
- changed order of mentioned libraries so they fit the order of references in
  the next sentence in `pgf/text-en/pgfmanual-en-tikz-shapes.tex`
- Little improvements for matrix/inner style
- Convert quotes to TeX quotes
- DOC:matrix: Add example for every row/col keys
- Configurable matrix inner styles #867
- Add key visualize as smooth cycle #823
- /.style -> /.code #808
- Documentation for /pgf/fpu/install only
- New key `/pgf/fpu/install only` #861
- Merge branch 'new-unit-px' of https://github.com/muzimuzhi/pgf
- Remove \pgfkeys@ifcsname #863
- pgfmathparser.code.tex: add pdfTeX/LuaTeX unit px
- use fpu reciprocal is still under consideration
- fixing typo in pgfmanual-en-tutorial-Euclid.tex
- Update bbox library #856
- Shift before rotate #859
- Fix undefined control sequence in \pgfutil@pushedmacro
- Revert "Execute size hook unconditionally #795"
- Another improvement for #855
- corrected typo in patch of issue #848
- Improved fix for #855
- If prefixed name does not exist, look up global name #846
- Fix broken \foreach initializer #855
- Check if set is defined #853
- Forbid some more operations in patterns #852
- Trim surrounding whitespace from pattern name #851
- Use comma hack for pattern keys as well #851
- Merge branch 'master' of https://github.com/Mo-Gul/pgf
- incorporated tallmarmots suggestion of issue #848
- Fix \pgfmathfloattoextentedprecision #845
- (again) found double-space instances
- minor issue additionally stated in issue #840
- Fix chiral anomaly #837
- dvisvgm4ht: ProvidesFileRCS and copyright
- Merge remote-tracking branch 'dvisvgm4ht/master'
- multiple is noun; multiply is verb
- New pgfparser utility package
- Fix typo in fadings driver for Lua/pdfTeX
- Don't swallow the delimiter #831
- Include dependencies in Makefile #829
- pgfmathparser.code.tex: add pdfTeX/LuaTeX/pTeX units
- Update manual issue template
- Address the CTAN issues #816
- Cherry-pick the useable stuff from #822
- Issue template: Reminder to use latest manual
- `arrows` library replaced by `arrows.meta`
- Math parse looseness on to paths #813
- Update README and fix .travis.yml
- Error checking for postaction, correct xetex postaction
- Mistake in code example
- removed some more remaining instances of the `arrows` library (#819, #698)
- Pass emptry group as a \Picture argument
- Handle nesting
- Added comments
- Support display math inside picture
- check for the vmode
- Make the tex4ht patches active only at \begin{document}
- test for existence of tex4ht commands
- code cleanup
- Removed \Rcs command
- Initial commit

### Contributors

- Alexander Grahn
- Arkonos
- Erik
- Hironobu Yamashita
- Ilhan Polat
- Kamil Ziemian
- Leonard König
- letzfets
- Michal Hoftich
- muzimuzhi
- PhelypeOleinik
- Stefan Pinnow
- tallmarmot
- thinbold

## [3.1.5b] - 2020-01-08 Henri Menke

Hotfix for the `external` library.

The fix for #759 broke existing uses and has been reverted.

## [3.1.5a] - 2019-12-21 Henri Menke

Hotfix for `tikz-3dplot` compatibility

The release includes a bugfix for #809

## [3.1.5] - 2019-12-19 Henri Menke

### BREAKING CHANGES

- The computation of path times in the `intersection` library was wrong when
  sorting intersections and did therefore not work correctly (#480).  This is
  fixed now, but that also means that the order of intersections might change if
  you were using sorting before.  You can easily check this by looking for
  `\pgfintersectionsortbyfirstpath` and `\pgfintersectionsortbyfirstpath` or the
  `sort by` key if you are using intersections in Ti*k*Z.

- It turned out that in `\pgf@protocolsizes` the `\pgf@path@size@hook` was
  executed only if the picture was actually to be placed.  This led to the
  problem that the `local bounding box` was not updated correctly (#795).  To
  correct this, the hook is now executed unconditionally.

- To get name prefixes for `pic` working (#311) the resolution of node names in
  `\tikz@calc@anchor` now has two stages.  First it tries to look up the
  prefixed name and uses it if it exists.  If there is no prefixed name, the
  global name without prefix will be looked up and used (fixes #717).
  Previously, if the prefixed name did not exist and error was issued
  immediately without attempting to look up the global name.

- There was a bug in old PGF versions that the body of `\pgfkeysedef` was not
  fully expanded #305.  This was fixed in PGF 3.1 (ac33f7e5) by the use of
  `\scantokens`.  Unfortunately when expanding the body the catcodes at the
  point of use are taken instead of the catcodes at the point of definition.
  This led to new bugs like #669.  With the new version we are taking a middle
  ground.  We support macro definitions within edef bodies by doubling all the
  hashes followed by numbers.  All other hashes have to be escaped manually.  We
  assume that this is not a common use case.

### Added

You can read about these new features in the manual:

- The `patterns.meta` library now provides a couple of predefined patterns which
  can be used as replacements for the ones provided by the `patterns` library.

- Tight bounding boxes for Bezier curves using the `bbox` library.  This feature
  was contributed by @tallmarmot.  Thanks!

- New pgfkeys handler `.evaluated`

- The RGB color model is now supported in Plain TeX, i.e. values can be integers
  0-255 instead of floats 0-1 for rgb.

- Annotations for code examples in the manual as to which libraries are
  required.  These were contributed by Stefan Pinnow (@Mo-Gul).  Thanks!

- GitHub issue templates for more streamlined bug reporting.

- New build system based on Lua.  We'd like to have a more cross-platform build
  system.  The old system was based on Makefiles, which will be retained for a
  while but gradually phased out.  In the future we hope to be able to implement
  a regression test suite.

# Removed

- In the last release the undocumented commands `\rawx`, `\rawy`, `\rawz`, and
  `\coord` were added to the `\path let` operation.  These proved to be not as
  useful as anticipated (#731) and were therefore removed again.

# Bug fixes

Lots of bug fixes.  On GitHub you can click the commit hashes and the issue
numbers to get to the fix and the ticket, respectively.

- 0b095288 #793
- ba8628c8 #804
- c6ef774c #305 #669
- 135e361e #759
- be8dfa7e #769
- 26cea424 #805 #806
- f63131b4 #801
- 4204b35b #803
- 167a78eb #798
- 8445f362 #796
- 03b89120 #795
- acd2ca38 #480
- d2caaf3a #387
- a5989c1e #442
- 9d4e1020 #428
- 96f41c41 #730
- b2bbefda #775 #776
- d9e677f5 #400
- 94be30ee #788
- a632c4d0 #790
- 41a85559 #789
- 319cae01 #512
- 969b1f8d #726
- 888f902c #785
- 226808c3 #784
- 13dab67d #736
- 92faccff #643 #773 #774
- 3c909b77 #770
- 6ccafffa #519 #751
- 3cf72768 #627
- 37c39d0e #602
- a547358e #727
- 97a18d33 #767
- 2e11f549 #728
- f7a24c56 #719
- 88951be5 #311 #717
- 08275e30 #747
- fddaaad7 #753
- a93c47eb #762
- 88954e20 #768
- 1302de8a #756
- b2656567 #743
- 47f87253 #742
- 5e2f4a88 #284
- aee5465f #735
- 4aaa25e6 #736
- 76a69d29 #640 #711 #729
- 2d5fb0c3 #720
- bb5614ea #718
- 5c746e52 #715
- ff369f8a #721
- 7ee3a2ca #361

### Changed

- [CI] bigintcalc, etexcmds, gettitlestring, hycolor, intcalc, kvdefinekeys,
  kvsetkeys, ltxcmds, refcount, uniquecounter
- Reseed the RNG before every use
- Remove redundant definition of `center` anchor
- Rewrite explanation for `\anchorborder`
- Document loading order for translator #804
- Hash doubling in pgfkeys edef only for numbers #305 #669
- Add conditional for externalize to manual
- Check \ifmeasuring@ #759
- Add comment about 8 character filename limit in old ConTeXt #769
- [CI] atbegshi, atveryend, bitset, pdfescape, rerunfilecheck
- Typos in the manual #805 #806
- New build system
- [CI] letltxmacro
- Document that matrix on path need ampersand replacement #801
- More nitpicking #803
- Minor typo fixes and word change suggestions.
- Missing letter in functional tokens #798
- [CI] stringenc
- Remove cleanuplink and friends #796
- [CI] kvoptions
- Execute size hook unconditionally #795
- corrected some spellings - harmonized e.g. "$x$ direction" --> "$x$-direction"
  with the rest of the manual
- adjusted "mystars" example so it fits to the "blue code box"
- renamed `lines` to `mylines` in last `codeexample` to match the previous
  `mystars` example
- Fix sorting of intersections #480
- Update TeX Live CI
- Document shorten < and > #387
- pgfinterruptpath is not a scope #442
- \pgfkeys@temp is not safe to transport over other macros #428
- Draw to target instead of computed anchor #730
- Implement and document new patterns #775 #776
- \pgfmath@ensureregister produced missing characters #400
- Wrong numerical constant in ln #788
- AtBeginDocument for ConTeXt #790
- Some packages got moved out of oberdiek
- Protect parens and order of operations in turtle #789
- Missing name prefix in "<dir> of=" positioning #512
- Fix style key for datavisualization #726
- New pgfkeys handler .evaluated
- Forward scanned coordinate untouched #785
- Nitpick #784
- Fix spacing for keys in decorations manual
- Correct typo in tutorial
- Revert "Add \rawx, \rawy, \rawz to let operation"
- Revert "Check for \pgfpointxyz before \rawx, \rawy, \rawz"
- Revert "Making the declared coordinate accessible"
- Improvements for markup in the manual
- Support for RGB for Plain TeX (docs)
- GitHub: Add mailing list link
- GitHub: Issue templates
- Add bbox library to manual (oops)
- corrected spelling of `\todosp`
- added some `\todosp` comments to `... Barb` arrows where no space between the
  two words is shown in the manual (v3.1.4b)
- replaced all instances of `arrows.spaced` with `arrows.meta`
- replaced most of the instances of `arrows` with `arrows.meta`
- fixed some more wrongly spelled library names (related to issue #736)
- marked more libraries in horizontal bars, i.e. `|...|`
- Change order of options in label and pin #643 #773 #774
- Support for RGB for Plain TeX
- Reset transformation in grow cyclic #770
- First version of the bbox library
- Correct example for every pic #519 #751
- Support styling of outer \pgfmatrix node #627
- Add some predefined patterns to patterns.meta
- Improve the 'lines' example for patterns.meta #602
- pgfmathfloat@parser@install in pgfmathfloatparse #727
- Reverse anchor of spy node #767
- Cannot use commas in pgfkeys #728
- Add generated gnuplot files #719
- Fix `name prefix` for pics
- Add quotes to error message #747
- Cheap trick to avoid leading space problem #753
- Fix pgfkeys pretty printer for single key-value pair #762
- Merge branch 'master' of https://github.com/lockywolf/pgf
- Update doc/generic/pgf/text-en/pgfmanual-en-tutorial.tex
- Install iftex in CI
- /tikz/radius dropped units #768
- Update pgfmanual-en-tutorial.tex
- Fix of a typo
- Support pattern objects with dvipdfmx
- Race condition in circle radius #756
- Merge pull request #757 from Lipen/patch-1
- Fix typo 'arrow.meta' -> 'arrows.meta'
- Reset some text parameters inside a node #743
- principle -> principal
- Fix misspelled library names
- Definition should be deferred to \pgfutil@guessdriver
- ConTeXt MKIV needs the LuaTeX driver #742
- Merge remote-tracking branch 'Mo-Gul/master'
- Reset \tikz@intersect@namedpaths at scope boundaries, fixes #284
- Make \node foreach work if loop variable is used for positioning, fixes #735
- Correct some typos, fixes #736
- checked `patterns.meta` library stuff and fixed some minor issues
- corrected a word in `pgfmanual-en-dv-axes.tex`
- harmonized spelling of `i.e.` and `e.g.`
- corrected line breaking in `pgfmanual-en-math-numberprinting.tex` where a
  |...| was split across lines
- Merge pull request #733 from hmenke/PimpCodeexamples
- New .gitignore needs some special treatment
- handled one more `codeexample` that was added after branching.   (related issues #640, #711, #729)
- moved `colorlet` to the `codeexample` itself instead of to `pre` in `pgfmanual-en-base-quick.tex`
- included issue #720 ("sub-library" should load "main library" by default)
- therefore added loading `graphs` library in `graphs.standard` library   
- adjusted `preamble` code in `codeexample`s accordingly  
- there exist `graphdrawing` `codeexample`s in the manual that don't need the
  `graphs` library --> adjusted `codeexample`s accordingly
- fixed issue #718 ([manual] \usepgflibrary vs. \usetikzlibrary)
- missed to commit/push the Lua documentation stuff
- had a look at the `codeexample`s where a leading space was introduced (see
  https://github.com/pgf-tikz/pgf/pull/711#issuecomment-514506025). Some of them
  could be removed but others are introduced because of code added to the `pre`
  key where I don't have a clue if/how this can be avoided
- continued(/finished) moving `setup code,hidden` to `preamble` of the `codeexample`s
- minor stuff
- corrected wrongly commented Lua comments in the Lua documentation files (of
  commit 900d47729d91dd9ba3eb59de56d5d9a4ba2eb155
- moved `setup code` before `pre` in `extract.lua`
- started moving `setup code,hidden` to `preamble` of the `codeexample`s
- also need to Lua comment LaTeX comment in the Lua documentation files
- commented some more `\begin{codeexample}[setup code,hidden]` (as @hmenke
  suggested in https://github.com/pgf-tikz/pgf/pull/711#discussion_r304140166)
- implemented suggestions given in https://github.com/pgf-tikz/pgf/pull/711
- removed commented/unnecessary stuff from `extract.lua`
- minor stuff
- accounted for some more `codeexample`s in
  `tex/generic/graphdrawing/lua/pgf/gd`
- adapted `extract.lua` after Henri changed it in Master to also account for the
  manual files at `/tex/generic/pgf/graphdrawing/lua/pgf/`
- accounted for some more `codeexample`s in `doc/generic/pgf/text-en/`
- removed an unnecessary empty line
- % TODOsp: ... --> % TODOsp: codeexamples: ...   (so they can be found more easily)
- continued adding code to make extracted `codeexample`s work
- changed order of `setup code` and `preamble` in `extract.lua`
- continued adding code to make extracted `codeexample`s work
- continued adding code to make extracted `codeexample`s work
- continued adding code to make extracted `codeexample`s work
- finished switching from `libraries/tikz={...}` to
  `preamble={\usetikzlibrary{...}}`
- continued with following files in the manual
- adapted `extract.lua`  
- incorporated fixes from main PGF repository (provided by Henri)  
- changed `\documentclass` from `article` to `standalone`  
- reordered some stuff
- started switching from `libraries/tikz={...}` to
  `preamble={\usetikzlibrary{...}}`
- added `pre` stuff to codeexamples of the tutorial doc files so fewer files
  fail TeXing using the build bash script.
- finished adding libraries to codeexamples of the tutorial doc files (so far
  not all needed styles and definitions were added using `pre` key)
- commented line that adds all libraries to the extracted codeexamples in
  `extract.lua`
- started adding libraries to the codeexamples
- fixes #715
- .cvsignore -> .gitignore #721
- Fix a leaking space.
- Fix text color in nodes #361
- Halt on error
- On behalf of @marmot : Improving the calculation of bounding boxes for Bezier curves

### Contributors

- Benjamin Desef
- doraTeX
- fmitha
- Jonathan Spratte
- JouleV
- Konstantin Chukharev
- Lockywolf
- Matteo Gamboz
- Mo-Gul
- quark67
- samcarter
- Sašo Živanović
- Stefan Pinnow

## [3.1.4b] - 2019-08-03 Henri Menke

This is a bugfix release for the dvips driver. A regression was introduced in
the dvips driver in the last release that led to displaced objects #722. This
update fixes the regression but also reverts the fix for position tracking #690.

## [3.1.4a] - 2019-07-16 Henri Menke

This is a bugfix release to make the XeTeX driver less broken. A regression was
introduced in the XeTeX driver in the last release that lead to displaced
objects #708 #709. This update fixes the regression but also reverts the fix for
position tracking #353.

## [3.1.4] - 2019-07-12 Henri Menke

### Added

- Document and fix the `patterns.meta` library
- Stretchable dash patterns
- Use `\protected@edef` in `\pgfmathparse`

### Fixed

#672, #675, #689, #353, #693, #690, #700, #701, #702 
Revert 00f4e8d4154dcb3133ed4a106b6254b8faf874e2
`\pgfmathrandominteger` didn't handle expressions as input

### Changed

- after_script runs after deploy
- Add pgfmanual to release files
- Add URL of the pdf manual to the README.md file
- Goodbye SourceForge
- Clear trap before deploy
- Switch to a new branch for tlcontrib
- Stretchable dash patterns #629
- Try protected@edef in pgfmathparse
- Hardening patterns.meta a little
- \pgfmathrandominteger didn't handle expressions as input
- extract.lua: all extracted files are tex
- extract.lua: recurse into subdirectories, ignore remember picture
- Describe \pgfdeclarepattern and \tikzdeclarepattern
- Add patterns.meta to the manual
- /pgf/foreach/count is unscoped #702
- On the way to more configurable patterns
- Add mailing list to the README
- Missed stripping pt on dimensions #701
- Bend angle need not be integer #700
- No dedicated options for libraries (for now)
- Add option to hide code
- Stripping comments was too greedy
- Small fix to the grammar
- Typos in luamath
- Functionality to print libraries in code listings
- fixed some typos
- fixed regression   (accidentally duplicated part of code)
- \pgf@nodecallback might be called twice #693
- Default implementation of \pgfsys@hboxsynced doesn't work for dvips #690
- Fix position tracking for XeTeX #353
- Wrong order in definition of \translate #689
- FILES is generated
- Change priority of Travis jobs
- Load imakeidx before hyperref
- Remove user config from deploy script
- Revert "Missing spaces in error messages #679"
- Restored lost functionality in intersections / fillbetween feature
- Revert 00f4e8d4154dcb3133ed4a106b6254b8faf874e2
- Fixed regression: the merge cc191ed4ae5bd11df9ce42595102caa4e1f141b4 accidentally deleted a feature
- Use imakeidx for automatic index creation
- Looks like I got tex4ht working
- Use T1 for DVI output for now, see also https://github.com/mgieseki/dvisvgm/issues/2
- luaotfload was missing this whole time
- Merge remote-tracking branch 'loopspace/master'
- Disable T1 encoding for LuaTeX
- Extended the higher-level save of the last moveto so that it also works with nodes.
- Added dimensions for saving the last moveto coordinates so that -- cycle works
  with nodes.  The existing method uses the coordinates stored from the last
  soft path move to, but this has an extra transformation applied to it meaning
  that when it gets used in node placement the transformation is applied twice.
- Missing spaces in error messages #679
- Move tlcontrib to tlnet folder to make room for possible future MikTeX contrib
- Typo in alternate angles #676
- Missing xcolor definitions for Plain and ConTeXt #675
- Typo
- Some more fixes for the tex4ht manual
- Merge remote-tracking branch 'Mo-Gul/master'
- Revert all but the useful changes of 98829b450a96a6790570aba11949cd9834e49e2c
- Some more cleanup before deploy
- Fix .lastretry #672
- Deploy TDS and CTAN zip
- Get git tag in Makefile

### Contributors

- Andrew Stacey
- cfeuersaenger
- Christian Feuersaenger
- Henri Menke
- johannesborgstrom
- Stefan Pinnow

## [3.1.3] - 2019-05-09 Henri Menke

### Changed

- Further unbreaking of shadings #650
- \ifdim instead of \ifx #412
- Add push- and popmacro. Useful for smuggling. From ConTeXt
- Merge pull request #664 from dcpurton/shadings-colorspace
- Add navigation arrows to SVG manual
- Typos in pgfmanual-en-library-circuits.tex #667
- Simpler basename function for extract.lua #640
- Add copyright and attribution for CMYK and grayscale shadings
- Update documentation for color model independent shadings
- CMYK and grayscale shadings library support
- Functional shading color space conversion functions
- Support for CMYK and grayscale shadings in set up code
- Conversion from shade color to grayscale PostScript data support
- Conversion from shade color to CMYK PostScript data support
- Add grayscale shading postscript driver support
- Add CMYK shading postscript driver support
- Add grayscale shading parsing functions
- Add CMYK shading parsing functions
- Adapt shading drivers to allow for multiple color models
- Produce compilable examples from extract.lua #640
- Preliminary version of an extractor script for codeexamples #640
- Manual typos #665
- Revert "No mode switch for typesetting pictures"
- Support shading color specifications in CMYK
- Set up RGB specific shading parsing
- Fix typos #662
- No mode switch for typesetting pictures
- Correct floored division (thanks @josephwright)
- Merge pull request #661 from dcpurton/mandelbrot-fix
- Fix Mandelbrot set shading definition #658
- Add Easter to PGF calendar #593
- Document save and use path #644
- Missing definitions in tex4ht driver #660
- Fix conflicting shading declarations for dvipdfm #659
- Add some circuit symbols #641
- Add tlpkg to Travis cache
- Fix shadings in dvisvgm
- % is not allowed in DVI #657
- Fix shading regression #656
- Don't switch mode in \pgfuseshading #655
- Use TL usertree in CI
- Merge pull request #647 from Skillmon/parserx
- requested changes from review
- Merge remote-tracking branch 'official/master' into parserx
- More checks, fewer rsyncs
- fixed bug ignoring +
- fixes #628; needs the new parser version
- fixed a bug in pgfparserlet
- removed parserx from FILES
- parserx replaces parser
- Force push to SourceForge
- Add revision file to archive
- Override before_script for SourceForge mirror
- Update README [ci skip]
- Typo
- Missing packages
- Better commit message
- Deploy tlcontrib
- PGF requires etex
- Looks like we have to rerun twice
- Rerun check for dvisvgm docs
- Deployment script for website
- bugfix default space rule
- added pgfparserxlet
- Merge branch 'fix-typos' of ssh://git.code.sf.net/u/frougon/pgf
- Shading assignment has to global #650
- Correct initial value for minimum width and height #649
- use pgfutil@namedef
- no etex, no folds
- Merge remote-tracking branch 'official/master' into parserx
- Merge remote-tracking branch 'kpym/master'
- Optional e-TeX protection
- finished parserx documentation and module
- Fix Travis conditional
- Only sync when on upstream
- \noexpand instead of \ignorespaces
- Automatically mirror changes to SourceForge
- Allow optional comma in let assignment list #606 (oberdiek)

### Contributors

- David Purton
- Jonathan Spratte

## [3.1.2] - 2019-04-04 Christian Feuersaenger 

### Changed

- Update README
- Fix #523 (jkinable)
- Fix #522 (kpymtzanev)
- Welcome to GitHub :octocat:
- Renaming perspective library macros
- Fixed typo and missing backslash
- Correct copyright statement
- Added perspective library
- Fix TeX conditionals on \pgfmathdeclarefunction (Eric Domenjoud) Feature Request #121
- More accurate \pgfpointnormalised #518 #519 Feature #96
- tikzmath needs to know about fpu
- Fix shading angle #516 (Eric Domenjoud)
- Fix trivial typo #514
- Missed ligature suppression for dvisvgm #473
- Now I hopefully got all of the ligatures #473
- Some fixes for the shading patch #511 (Eric Domenjoud)
- \long\def
- Fake \scantokens has to at least strip braces
- Only use \scantokens if available #508
- Revert "Revert "Patch for shadings #511 (Eric Domenjoud)""
- Revert "Patch for shadings #511 (Eric Domenjoud)"
- Making the declared coordinate accessible
- Globally remember declare coordinate of a node
- Check for \pgfpointxyz before \rawx, \rawy, \rawz
- Add \rawx, \rawy, \rawz to let operation
- Disable strict nesting for now
- Patch for shadings #511 (Eric Domenjoud)
- minor stuff
- Merge branch 'master' of ssh://git.code.sf.net/p/pgf/git
- Merge branch 'branch_3.1_hotfix'
- updated release file

### Contributors

- Henri Menke
- Max Snippe
- Stefan Pinnow

## [3.1.1] - 2019-02-02 Christian Feuersaenger 

### Changed

- fixed bug #503: regression prevented the use of dvips. This reverts the bugfix
  for bug #362

## [3.1] - 2019-01-05 Christian Feuersaenger 

### Changed

- \pgfmathprintnumber: implemented 'retain unit mantissa=true|false' (feature #92)
- fixed wrong projection of `canvas is xy plane at z` in `3d` library (bug #410)
- added documentation of `3d` library to the manual (support request #11)
- defined CMYK colors for ConTeXt (feature request #33)
- `text along path` decoration repeated last char multiple times when 
  this was in math mode (bug #479)
- fixed accidental usage of `\rm` (bug #476)
- fixed newlines for tex4ht (bug #327)
- fixed bug that `fit` didn't work with `transform shape` (bug #330)
- fill color in nodes now respects colormodel (bug #349)
- fixed broken VTeX support (bug #350)
- `text=<color>` now works fine when in the nodes' text `\textcolor` is used (bug #362)
- allowed whitespace between layers in `\pgfsetlayers` (bug #376)
- fixed `\method` which can now contain empty lines (bug #448)
- manual improvement regarding `pgfoothis` (bug #452)
- documented commands `\pgfooeset`, `\pgfooappend`, `\pgfooprefix` (bug #452)
- fixed bug in \pgfkeysedef (bug #306)
- `miter limit` now raises an error when a value < 1 is given (bug #347)
- fixed bug that `\pgfmathmax` and `pgfmathmin` were broken when
  `fixedpointarithmetic` library was loaded (bug #360)
- added missing function `\pgfmathpneg` in `fixedpointarithmetic` library (bug #361)
- fixed bug that brace decorations were malformed for large amplitudes (bug #351)
- made node parser aware of prefix and suffix (bug #397)
- (almost) fixed guillemets for LuaTeX (bug #473)
- fixed incorrect spelling in pgflibrarydecorations.text (bug #479)
  (but this doesn't solve the bug 100%)
- fixed 'bend left' bug if used with a formula (bug #423)
- use \typeout stream instead of \write16 (bug #488)
- fixed some bugs regarding graphdrawing electrical "springs" (bugs #380 and #381)
- fixed pgf_lookup_and_require for new luaotfload (bug #493)
- fixed graphdrawing for ConTeXt (bug #477)
- added utility \pgfmathifexpression (and special treatment in luamath
  library and fpu library)
- intersections lib: improved accuracy of intersections for linear paths
- fixed incompatibility issue of tikzmath and fpu reported in 
    http://tex.stackexchange.com/questions/349766/pgfplots-on-tikzmath-function-with-conditionals-returns-an-error
- Improved driver detection (bug #395 TikZ does not create output with LuaTeX 0.95.0)
- New luatex driver now supports fallback to pdftex driver if
  luatexversion is older than 95 (let's hope this works reliably - luatex
  used to have version 240 some time ago!)
- Fixed bugs that caused pgfsys-dvips.def to generate corrupt
  PostScript for all nodes.
- Bounding box computations for animations implemented.
- Animated arrow tips are now possible.
- fixed incompatibility between textpos (absolute mode) and external
- fixed \write18 issues in luatex 0.87 and later (by using os.execute())
  affects external lib and plot function.
- Lots of bugfixes in animation and svg code.
- Added optimizations to reduce file size for svg code
  (better support by dvisvgm will be needed however for more
  compact text!).
- First working, fully documented version of TikZ animations!
- Fixed manual stuff to compile it with dvisvgm.
- Rewrote tikz animation lib.
- added context-related aux file fix of Hans Hagen
- fixed save stack issues (eliminated 'retaining' issues) about pgf@x and pgf@y
- external lib: 'force remake' now also updates .md5 files
- fpu: fixed floor and ceil
- fixed basic layer floor function
- lua library: improved interoperability of luamath and fpu
- unit test now compares luamath, fpu, and pgfbasic math
- activated math parser in foreach's end notation to allow \foreach \i in {0,...,10-9}
- Worked on pgfsys-dvisvgm.def a lot. Now requires
  dvisvgm-1.5.3 because of switch from pt to bp there. Does
  correct bounding box computations.
- fixed bug in luamath library
- external lib: added support to automatically externalize references and
  labels with 'mode=convert with system call'
- Reworked implementation of animations for tikz and started
  on documentation of the backend.
- First complete implementation of animations for tikz! (for
  svg backend). Documentation still missing, but works nicely.
- First work on animations for svg. Added commands in pgfsys
  and added module pgfmoduleanimations. No documnetation yet.

### Contributors

- Henri Menke
- Till Tantau

## [3.0.1] - 2015-08-07 Christian Feuersaenger 

- fixed regression introduced for pgf 3.0.0 (bug #149): leading empty
  lines at the beginning of plot files disabled '-- plot'
- fixed bug #291 (missing white space trimming in node labels)
- fixed bug #313 (alias option did not respect name prefix/suffix)
- fixed bug #341 ("is in pic" was not reset)
- fixed bug #365 (caused by missing adoption after copy-paste in tikzlibraryfolding)
- fixed bug #315/316 by applying the suggested patch and verifying it
- fixed fpu math functions for int, ceil, and floor
- added \pgfmathlogtwo and \pgfmathlogten as requested in bug #359
- Fixed problem in gd: Creating more than about 15 vertices
  inside a graph drawing algorithm was impossible since this
  created too many text input levels. Reorganized the interplay
  between tex and lua for the coroutine so that no input levels
  are created.
- Added number nodes option to graph lib.
- Fixed nullfont warnings in axes in datavisualization.
- Fixed wrong axes for school book plots.
- Fixed nullfont warnings when parsing logic gate inputs.
- Fixed bug in tikz.code.tex concerning colors for arrow tips:
  Setting and restoring the global color "trackers"
  pgf@fillcolor@global over groups was done only in \pgfscope,
  but not in the scopes opened and closed by tikz when drawing a
  path (\pgfsys@beginscope is used there). This caused wrong
  colors to be used.
- Updated patterns.meta library.
- context: committed patch to adopt pgfutil-context for new (incompatible)
  context handling of colors -- contains some cleanup by Hans Hagen.
- fixed bug in external lib: braces in external filenames confused the generator
- fixed bug in fpu: equal(x, 0) failed for x<0
- fixed bug in atan2 (returned wrong sign for atan2(4e-5,-5))
- implemented atan2 in FPU
- fixed save stack issue (TeX capacity exceeded, sorry [save size=250000])
  if the color changes a _huge_ number of times during a single path.
- worked on LUA math parser: ensured that a suitable first scope of
  functions works. I also added support for 'declare function'
- Added provisional code for patterns.meta library. Patterns
  can now be declared using TikZ code with additional support
  for tile transformations. Currently only PDF output supported
  at back-end (uses \pgfsys@declarepattern@meta in pgfsys-pdftex.def).
- finished first prototype of a LUA math parser. It is orders of magnitude
  faster than its TeX pendant, features a pure LUA mode and also offers a
  fallback to the TeX \pgfmathparse for unsupported operations/functions
  only defined in TeX.
- fixed bug (regression of bug #229): external lib with dvips produced
  wrong bounding box (was broken entirely)
- fixed regression in external lib: 'mode=graphics if exists' broke any
  undefined label warnigns
- added automatic "fast lane" to math parser: if the input is a number
  without units, it will return that as-is. Reduces typesetting time down to
  66% for huge scatter plots and has just 1% overhead for math intensive
  figures.
- added switch 'trig format=deg|rad' which allows to switch sin,cos,tan,
  and their friends to radians. It works for all user input
  arguments - I hope without unanticipated side-effects (marked as
  experimental)
- external lib: defined suitable defaults for 'system call' depending on driver
- external lib: solved incompatibility with biblatex's \cite[][]{name}
  command    (http://tex.stackexchange.com/questions/173465/tikz-error-for-externalized-graphics-but-output-is-correct}
- number parser/printer: added switch 'read comma as period' to read
  localized input numbers. Off by default but added useful hint to parser
  message.
- Fixed bug #308 fixedpointarithmetic: unwanted spaces by line ends 
- Fixed feature #81: signum function (fpu + pgf basic layer)
- Fixed all \begin{scope} and \end{scope} in foldings lib,
  changed them to \scope and \endscope.
- Fixed #303 Type in pgfmanual (colormixin)
- Fixed #302 pgf-3.0: Cannot plot a constant function. Will
  now center the constant line.
- Addressed #299 Precision problem with explicitily anchored
  labels: While not a bug, I added a "centered" option for cases
  similar to this one (although, in this particular case, the
  new centered option is not what is needed)...
- Fixed #298 \pgfarrowsdeclare is still mentioned in pgfmanual
- Fixed #294 Nodes for arcs, which angles are calculated
  simultaneously.
- Fixed #292 "node scale and outer sep" by introducing the new
  option "outer sep=auto", which takes care of both this problem
  (at least in all normal cases) and also of the draw versus
  fill problem with outer seps.
- Fixed #285 \tikz@intersect@namedpaths persists outside
  scopes as suggested.
- Fixed #284 Additional rerun statement for overlays (for LyX)
  by adding the proposed solution (essentially).
- Added post-fix for #288 by undoing all -- ligatures in
  verbatim code.
- Fxied #283 "Is there a smarter way to handle units in math
  engine?" by adding the "scalar" function.
- Fixed #288 "All the '£' should be '$' in the examples of
  pgfmanual..." by switching to T1 enconding.
- Fixed #282 "\pgfmathredeclarefunction does not work properly."
- Added first edge routing algorithm to gd.
- intersections libs: improved robustness and accuracy for curveto paths
  by using the floating point library together with Mark Wibrow. 
- fixed bug in latex/plain tex shipout routines for xdvipdfmx and xelatex:
  combination of shadings    and standalone package failed to work.
- Fix for 'rotate around x/y/z' keys which now evaluate
  the argument provided.
- intersections lib: detected duplicates in line-to intersections
  in endpoints and suppressed them.
- intersections lib: stored time offset for each intersections as optional
  property (i.e. if it comes for free). This is required to compute fill
  paths

### Contributors

- Christian Feuersaenger
- Mark Wibrow
- Till Tantau

## [3.0.0] - 2013-12-20 Till Tantau 

- In preparation for the release 3.0.0, I pimped the manual a
  bit. It will now automatically detect whether graph drawing
  C libs are available or not. Also, syntax hilighting is now
  always switched on. I also some subtle optical hints to
  crossreferenced words in the code examples; this is pretty
  useful, I think. 
- Did a lot of cleaning up for the release.
- Fixed a bug in Vertex.lua that returned wrong anchor
  positions for non-centered vertices.
- Fixed bug #280 "Layered layout" produces unknown key with graphs library.
- Fixed bug #279 "Some parts of arguments in foreach macro are lost".
- Fixed bug #258 "Default arrow edge style puts circumflex in
  drawn end node" by now allowing people to say tip=on proper draw.
- intersections lib: ensured that 'name path global' is reset between main paths.
- worked on intersections lib (internals only); added O(N) list
  append/prepend utilities
- Added keys 'rotate around x', 'rotate around y' and
  'rotate around z' to rotate the xyz coordinate system
  around the x, y, or z axis.
- Fixes for 'text effects along path' decoration and docs.
- external lib: added support for 'up to date check=md5' for lualatex.
  Now, lualatex and pdftex both result in the same checksums (by means of
  \usepackage{pdftexcmds})
- Finalised 'text effects along path' decoration and docs.
- Changed keyval example (and references to define@key) 
  in pgfcalendar documentation to pgfkeys stuff.
- Minor fixes to decorations.text and math libraries documentation
- Added 'text effects along path' decoration. 
- Fixed regression/bug in 'name path global'.
- Applied path for bug #277 "\beforeforegroundpath not working".
- Prepared manual for new release (fixed overful boxes and
  index problems).
- Updated math library (minor fixes).
- Applied some fixes so that C code for graph drawing works
  once more.
- Arrow tips and their doc are now officially finished!
- Added documentation of nonlinear transformations. 
- modified release script to allow uploads of unstable TDS
  zips to http://pgf.sourceforge.net using
  make -f pgf/scripts/pgf/Makefile.pgf_release upload USER=cfeuersaenger
- Fixed problem with math parser inserting extraneous
  spaces when parsing \dimenexpr
- Changed blend mode syntax to standard pgf syntax (since PDF
  and SVG do not agree on names...).
- Added scale and slant options for arrow tips.
- Added more generic arrow tips.
- First version of comlete arrow documentation finished. Still
  need to document the arrows.meta library, though.
- Added "tips" option for drawing arrow tips without drawing
  paths.
- Fixed bug #273 "Graph drawing sublayouts fails".
- Incorporated first partial documentation of the arrow tips
  into the main documentation.
- Fixed bug bugs:#272 "SVG parser error after close path" as
  suggested by Mark Wibrow.
- Also changed the default syntax for svg path command so that
  it uses braces instead of quotation marks. (Quotation marks
  still work, of course.)
- Started working on arrow doc.
- Added macro to convert string of digits to comma separated list.
- First version of new arrow tip management done. Up and
  running! Still needs documentation and the old arrow tip
  codes should (but need not) be ported.
- Did some porting of old code, added fixes. Doc still missing.
- Fixed bug #264: "\pgfkeys /errors/unknown key should (?) expand first argument"
- Fixed bug #268: "`matrix of nodes` isn't working properly any more"
- Corrected typos (bug #266 and bug #265)
- added magnetic tape shape.
- Fixed bug #262/267: "Line breaks are not working in labels anyy more."
- Fixed bug #260: "TikZ node on background in pgfextra"
- Started work on bending arrows.
- external lib: fixed bug: file dependency handling was incorrect and
  suffered from regression caused by MD5 checks
- repaired incompatibility with pgfplots <= 1.8: samples key was
  evaluated in context of floating point unit and new pgf code relied on dimension
  registers.
- Added "turn" key.
- Added "angle" pic type and "angles" library.
- Patched gd loader code so that it works with context mark IV.
- Added new pic path command.
- Patched pgfsys-dvipdfmx.def to step around the bug in
  (x)dvipdfmx that caused scaled boxes (including scaled
  graphics) inside nodes to be displayed incorrectly.
- fixed bug in fpu: 0^0 and 0^x both produced nan. Now we get
  0^0=1 and 0^x = 0.
- Removed claims from manual (not by me...) that TikZ does not
  work with Mark IV of context. I just tried it and everything
  I tried (including advanced stuff like shadings) worked fine.
- Fixed pgf intersection library to ensure that
  specialround tokens are processed.
- Added support for dvisvgm. Quite nice...
- Worked on tex4ht code. Works reasonably well know and even
  graph drawing is possible (when luatex is used for
  typesetting; for this I needed to fix some latin1 characters in
  html4.4ht). Also, I renamed /tikz/tex4ht... to /pgf/tex4ht
  (someone else added that) since tikz has nothing to do with
  that stuff. 
  Typesetting the manual in tex4ht no longer works, but that seems
  like too much bother for my taste. 
- Fixed bug #256 "The special \pgfcoordinate macro doesn't
  expand \pgfpictureid." 
- external lib: fixed incompatibility of pdflscape with
  external lib
- Fixed a problem with pdf resources of transparency groups in
  dvipdfmx. 
- Fixed bug #149 "/tikz/raw gnuplot ignoring segmented plot"
  by introducing a new way of handling plot streams. There are
  now new kinds of points (outliers and undefined points) and
  "new data sets" commands inside streams. Handlers (like the
  lineto and curve handlers) can be configured to interpret
  these as jumps (this is the default).  
- Fixed bug #255 "Trig computations offend fp via fixedpointarithmetic lib"
- Added "math" library. Could be integrated with calc library.
- Fixed bug in external lib: mode=list and make did not cope well with
  \ref in externalized images. These will be remade now.
- Fixed bug #162 "PGF manual examples use undefined "shape example" style"
- Fixed bug #169 "ghostscript error: /undefined in pgfo"
- Concerning bug #167 "node pin option sets
  inconsistent/incorrect angle" I added some clarification in
  the manual that explains the observed behaviour.
- Fixed bug #158 "\pgfmathparse does not support e-TeXs
  \numexpr and \dimexpr". You can now also use
  \pgfmathsetlength to assign a muskip a value. Internally,
  "mu" is treated like "pt", but if an expression contains
  "mu", \pgfmathsetlength and \pgfmathaddtolength will convert
  the number to "mu" before the assignment.
- Fixed bug #173 "Tikz's transparency, xelatex and preview
  package" by adding a specific fix for the interaction
  between preview.sty and everyshi.sty in pgfutil-latex.def.
- optimized mark=* and mark=o (q path versions lead to 10% time reduction)
- adopted new pgfkeys feature to /handler config/full or existing (
  required when /.search also is used to find the correct key path)
- Fixed bug #175 "In PGF oo module, calling a method strips grouping"
- Fixed bug #181 "Need to document |- coordinates using calc notation"
- Fixed bug #187 "\pgfmathanglebetweenpoints is not documented"
- Increased accuracy of atan, atan2 and
  \pgfmathanglebetweenpoints.     
- Fixed bug "#168 PGF is sensitive to dollar catcode"
- Fixed bug "#186 pgfonlayer makes pgf forget options" and
  added "every on background layer" option.
- Fixed bug "#192 pgffor scope iteration is buggy"
- Fixed bug "#196 Incoherent syntax for Bézier curves"
- Fixed bug "#199 Drawing error for chamfered rectangle"
- Fixed bug "#201 Markings fail with "Dimension too Large" on
  certain paths" by fixing a mistake and the decoration core
  and, additionally, in pgfmathanglebetweenpoints.
- Fixed bug "#254 building currenct CVS version fails on
  graphdrawing with current luatex": Will now work nicely with
  TeXLive 2013 and Lua 5.2.
- Added feature request "bug #203 Blending modes and better transparency"
- Fixed bug #204 "strange influence of \baselinestretch on
  tikz figure" by no longer sharing \pgfutil@tempa with latex:
  This register gets changed by LaTeX in a fontchange, which, in
  turn can happen at the beginning of every
  \pgfmathsetlength. 
- Fixed bug #207 "Decoration markings not on path on large
  lines" by using a more precise computation of positions on
  straight lines in decorations. Also, the angle computation
  is now much more precise by fixedin bug #201.
- Fixed bug #212 "Error if using plot into a \foreach loop in
  a single path" by making \pgffor@beginhook and friends local
  to the current \foreach. A nice side-effect is that one can
  now nest \foreach statements on a path and also mix in the
  plots. Hopefully, no one relied on the (undocumented,
  unsupported) old bevahiour of the hooks.
- Fixed bug #213 "pgfmathsetcounter only works in local scope"
  by adding a note in the documentation.
- Fixed bug #211 "\nodepart ignores text transparency"
- Fixed bug #220 "Transformations ignored in edge decoration."
- Fixed bug #221 "xyz spherical and cylindrical coordinate, radius not defined"
- Fixed bug #225 "pgfkeys "/errors/unknown choice value" ignores parameters"
- Fixed bug #253 "\pgfkeysfiltered cannot accept long arguments"
- Fixed bug #252 "I'm not able to build the current CVS
  version". This included a number of patches to fix problems
  introduced with the bugfixes introduced recently
- Fixed bug #226 "matrix column sep=-\pgflinewidth changes after empty cell"
- Fixed bug #229 "pgfpagesuselayout breaks beamer class"
  (hopefully, setting page sizes is really messy in TeX!).
- Fixed bug #232 "pow function broken for 0^x for non-integer values of x"
- Fixed bug #165 "\draw with empty domain results in infinite calculation"
- Added better error message to adress bug #244 "mindmap-style
  "invalidates" coordinate shape."
- Fixed bug #235 "\def\costhirty{0.8660256} not really used"
- Fixed bug "#237 CVS-version: pdfimage error: key interpolate undefined"
- Fixed bug "#245 broken key /pgf/decoration/reset marks"
- Fixed bug "#239 picture disappear after a zero-width rectangle width shading"
- Fixed bug "#247 Error messages hard to catch in plain TeX/ConTeXt"
- Fixed bug "#166 Possibly typos in circuits.logic.IEC"
- Fixed bug "#249 pgfkeys: /handlers/first char syntax is not
  'self-contained' (CVS version)" 
- Fixed bug "#248 circuits adjustable annotation improperly placed"
- Fixed bug "#250 pgfkyes: .append style and similar undouble # tokens"
- Fixed bug "#143 label changes center of a matrix node"
- Fixed bug #128 "fit does not scale if used in scaled scope"
- Fixed bug #136 "\hrulefill inherits or not pgf line styles"
- Fixed bug #224 "Including Tikzpicture in third part of
  multipart node" 
- Fixed bug #251 "cross out shape interacts with path options of path it is drawn on"
- Fixed bug #139 "Placement of node inside matix environment"
- Fixed bug #131 "text centering calculates wrong" and added
  new "node font" option.
- Fixed bug #121 "Annoying "Underfull \hbox (badness 10000)" message"
- Fixed bug #134 "Edge node style affecting arrowhead".
- Fixed bug #132 "Error in matrix with column sep "between"
  origins"    
- Fixed bug #133 "\draw[-<<,>=stealth] (10,45) -- (40,45); does
  not work." However, this introduces a (small, only visual)
  incompatibility with previous versions. If you need the visual
  effect "-<<" used to have (which, in a sense, was wrong), use
  "-< <" instead. The new "-> >" is also quite handy.
- Fixed bug #116 "Decorations can't be repositioned when
  pre/post used."
- Fixed bug #241 "div/null error by (270:length) and a fading line."
- Fixed bug #126 "Incorrect placed labels for inplicite positioned nodes."
- Added foreach syntax to nodes. This is useful and also
  needed to fix the problem that the foreach statement cannot
  be used after a to path.
- Fixed bug #18 and #74 (active characters and tikz) by virtue
  of the new "babel" library, which deactivates catcodes at the
  beginning of tikz pictures and reactivates them in nodes.
- Fixed bug #110 "cannot add node after cycle operation"
- Fixed bug #88 "\pgftransformarrow does not rotate with \pgfpointanchor"
- Fixed bug #86 "macro-expanded tree node has bad edge anchor"
- Fixed bug #85 "PGF + Crop package, at least for pdftex."
- Fixed bug #83 "Transparency Problem with \usepackage{endfloat}."
- Applied patch #19 pgfkeys: ".search also" fails at unbalanced "\if" values
- Applied patch #18 Missing grid lines with
  negative increment
- Applied patch #17 TikZ folding library
- Applied patch #14 inheritance in the oo module
- Applied patch #13 leaking space in \pgfpointintersectionoflines
- Applied patch #11 Patch for Bug #3165961 (\pgfmathmax and \pgfmathmin)
- Fixed problem of patch #9 Add papersize to XeTeX driver
- Applied patch #8 Support for changing physical page size with XeTeX
  (also added position saving support, while I was at it...)
- Applied patches #3, #4, #5, #6 (typos in manual) as far as possible
- Fixed bug #236 "Scaled closed paths, start/end points dont exactly match":
  "cycle" can now be used with all path operations where it
  makes sense, not only with --. In particular, things like
  ".. cycle" or "to [bend right] cycle" are now allowed.
- Reworked handling of edge and vertex paths in gd. In
  particular, edge--vertex intersections are now computed in
  Lua, rather than in TikZ. This is much more powerful and
  allows beautiful arcs between vertices. It is also very
  useful for planar graph drawings when several edges leave a
  vertex in the same direction.
- Did away with luadoc, now using simple handcoded documentor
  that will also work with Lua 5.2
- Redid OGDF support. Resonably stable base now.
- Added better C support.
- Should now work with both Lua 5.1 and 5.2
- fixed incompatibility of fixltx2e and external lib
- Reworked Storage mechanism of graph drawing system.
- Added phylogenetics library for graph drawing; documentation
  still only rudimentary.
- Started adding support for calling C graph drawing functions
  from Lua.
- First proof of concept for OGDF finished.
- Must still address luatex shared library link problems.
- fixed bug in external lib: \tikzexternalgetnextfilename did reset the
  value of \tikzsetnextfilename and 'export next'
- updated driver pgfsys-xetex: now, it supports all that the new driver
  for dvipdfmx does which includes fadings, functional shadings, and
  patterns.
- First complete documentation of the graph drawing
  system. (Finally!) 
- Renamed gd files to shorter versions: instead of
  pgf/gd/model/pgf.gd.model.Edges.lua we now have
  pgf/gd/model/Edge.lua and so on.
- Worked on gd documentation. Only binding doc is still a
  mess.
- Worked on gd documentation.
- New version of gd lib. The internals have been completely
  redone. In particular, no tikz libraries are needed for the
  individual algorithms any longer, all declarations are now
  done completely inside Lua. This makes gd usable (in
  principle) independently of tikz and pgf.
- Because of this, all declarations of algorithms need to be
  redone. 
- external lib: fixed spurious white space (caused by 'up to date check')
- manual styles: improved robustness of auto cross references & active spaces
- Fixed a bug with active colon in circuits lib. Probably more to
  fix in other libraries.
- Improved precision of math functions asin and acos (using linear
  interpolation instead of constant interpolation)
- Worked on gd.
- fixed pgfsys-pdftex.def : very old regression with \setbeamercovered{transparent}    and \pause
  Patch by Hendrik Vogt
- Added support for sublayouts in gd (not yet fully
  documented). This allows one to use several algorithms inside
  a single graph.
- Redone handling of clusters in gd yet again. Renamed them to
  "collections". Much better system now, can handle hyperedges,
  subgraphs and other stuff (in principle).
- Nodes generated by a gd algorithm now have correct size
  information (this one was tricky!).
- Redone handling of clusters in gd.
- Worked on gd documentation.
- fixed minor expansion issue \foreach \x in {a,...,d} lead to unexpanded value \x
- externalization: added special switch to deactivate incompatible
  geometry drivers during externalization 
- Redone pgf.gd.model.Arc
- Added documentation for said class.
- Worked on gd documentation.
- Replaced old luadoc by customized version. Gets called
  directly from tex.
- external lib: added support for MD5/diff based up-to-date checks.
  Changes to a picture will automatically result in a remake of the
  respective external graphics.
- Fix bug #3527068 (\pgfmathatantwo did not exist)
- Changed pgf.gd.new_graph_drawing_algorithm syntax. Not
  likely to change again...
- Added support for algorithms to create nodes and edge in the
  syntactic digraph.
- Introduced library graphdrawing.examples that includes some
  code demonstrating how "things are done".
- context: fixed catcode issues by means of suitable module
  \protect/\unprotect statements. 
- Introduced a new class model for graph drawing (Digraph,
  Arc, and Vertex instead of Graph, Edge, Node). I'm currently
  porting all the old code, but it takes a while and it's a
  bit messy right now. Some easy algorithms are already based
  on the new system, old ones not. In the end, things should
  be significantly faster and also easier to program.
- Attempt to fix bug in calc lib when '!' or ':' are active (not
  fully tested but should work).
- Attempt to fix bug with label and pin when ':' is active (not
  fully tested but should work).
- Finished the first two chapters of the documentation of gd
   (overview and tikz usage).
- Module system is now redone and the directory structure
  has been reorganized. No more messing around with lua
  modules, everything is perfectly portable now.
- Started to completely redo the module system of graph
  drawing in lua. I'm in the middle of it, so its currently
  messy, but it works.
- Implemented packing procedure for graph drawing.
- Cleaned up graph drawing source some more.
- Renamed lots of files (still not happy with it, though).
- Implemented Reingold-Tilford tree layout.
- Implemented my first graph drawing algorithm: circular layout.
- Introduced new declaration mechanism for graph drawing
  algorithm classes
- Implemented preprocessing step of decomposing a graph into
  connected components.
- Cleaned up graph drawing algorithm directories: Moved
  obsolete algorithms to special directory.
- Switched graph drawing calling interface from function-base
  to object-based: All graph drawing algorithms must now be
  implemented in a class
- Cleaned up file and class names of graph drawing engine. 
- Fixed problem that in case math library is loaded before pgf
  some math functions were broken (because \pgfmath@xa and
  \pgf@xa were different registers, which they should not be).
- Added anchoring and orientation to graph drawing library. 
- Added arrows.spaced library.
- Added quotation syntax to graph lib.
- Renamed some graph drawing layouts.
- Worked on documentation of graph drawing lib.
- Moved wrappers for luatex primitives (\pgfutil@directlua,
  \pgfutil@ifluatex, \pgfutil@luaescapestring) to pgfutil-common.tex
- Added support for luatex to the profiler library by emulating
  \pdfelapsedtime.
- Fixed wrong edef in graph lib that broke the /-syntax when
  text contained expandable stuff.
- More work on the luamath parser and evaluator.
- Fix a bug in tikz polar coordinates (reported on tex.se
  http://tex.stackexchange.com/questions/41828/using-math-in-tikz):
  braces around a delimited argument are removed.
- Fix a bug in pgfmath != operator (reported and fixed on tex.se
  http://tex.stackexchange.com/questions/40605/using-in-pgfmathparse)
- Fix a pgfmath dependency for pgffor.
- Added pos support to the arc command (finally...).
- Added support to the graph library for drawing tries.
- Added support to the graph library for adding edge labels in
  an easier way.
- Added the 'fixed relative' number formatting style.
- Added 'const plot mark mid' and 'jump mark mid' plot handlers.
- Renamed "layered drawing" to "layered layout" for
  consistency. 
- More work on the lua math parser and evaluator.
- Added wrappers for luatex primitives: \pgfutil@directlua,
  \pgfutil@ifluatex, \pgfutil@luaescapestring
- Make lua code more lua 5.2 compatible
- Work on the lua math parser and evaluator. Begin to merge Mark's
  code with mine.
- added FPU support for ==, !=, <=, >=, ?
- fixed problem with pgf number printer: it introduced spurious spaces
  tracker id 3430171. Thanks to Clemens Koppensteiner for the bugfix.
- \pgfsetlayers can now be given inside of a pgfpicture (or tikzpicture)
- The lua math parser now works on basic expressions (no units, no
  arrays, no strings, no functions, ...?).
- Some work on a lua (lpeg based) math parser.
- Added a gnuplot call key to pgfmoduleplot.code.tex (feature
  request #3308340).
- graph drawing: 
  - Initial work on layered drawing algorithms.
- Added dim function for array to pgfmath (to be documented)
- Some work on a ODE solver
- removed spurious white spaces in my bugfix for pgfmathdivide
- Second attempt at fixing spy lib...
- graph drawing:
  - added short overview for nodes and edges (lua class documentation)
- graph drawing:
  - Separate 'spring layout' and 'spring electrical layout' families.
      Rename existing algorithms accordingly.
  - Add an implementation of the Floyd-Warshall algorithm.
  - Add a new 'Hu2006 spring' algorithm based solely on springs.
  - Improve the initial layout of 'Hu2006 spring electrical' by 
    taking the graph size and diameter into account.
  - Rework existing spring electrical algorithms and improve 
    documentation.
  - Catch -!- edges and remove them from the Lua graph when detected.
- graph drawing:
  - Update documentation of spring and spring-electrical parameters.
    Add TODO items where things are missing, unclear or need to be 
    worked on.
  - Make initial step dimension and the electric charge of nodes
    configurable. Both, Walshaw2000 and Hu2006 support this.
  - Improve the approximation of the repulsive force.
- Fixed bug 3297817 (spy postscript problem).
- Fixed bug of missing newpath in postscript and opacity
  settings. 
- graph drawing:
  - Rename graphdrawing.spring to graphdrawing.force.
  - Fix NaN bug in the orientation helper.
  - Initial work on improving and documenting the parameters for
    spring and spring-electrical algorithms.
  - Properly forward default node and edge parameters to Lua.
- graph drawing:
  - Add Fibonacci heap and priority queue classes. 
  - Add Lua file for common graph algorithms. Implement Dijkstra.
  - Add method Graph:getPseudoDiameter().
  - Hu2006: Scale coordinations of nodes in a coarse graph based on 
    the quotient of its pseudo diameters and that of the parent coarse
    graph, as described in the paper.
- graph drawing:
  - Fix several interpolation bugs in the coarse graph class.
  - Use the coarse graph class in the Walshaw2000 algorithm.
- Worked on documentation of gd backend. Still need to
  document graph parameters.
- graph drawing:
  - Remove files from the old graph drawing library tree.
  - Disable verbose logging by default.
  - Specify sane initial values for spring algorithm parameters.
- Added .graph drawing parameter initial key.
- graph drawing:
  - Implement graph coarsening in the Hu2006 algorithm.
  - Name force-based algorithms after the paper author and year.
- Reorganized graph drawing documentation.
- Finished the graph drawing library reorganization started by Till.
- Reorganized the graph drawing key and directory
  structure. The documentation is still missing. Also, lots of
  files still need to be moved, but I'll leave that to Jannis.
- graph drawing:
  - implement a quadtree optimization in the Walshaw algorithm.
  - add a simple version of the Hu spring-electrical algorithm that
    seems to work almost as good as the Walshaw even without
      the multilevel approach implemented (which is the only thing
      that really makes the Walshaw algorithm useful).
- graph drawing: 
  - Initial work on a quad tree implementation for spring and spring
      electrical algorithms, with unit test.
    - Improve the internals of the Vector class.
- graph drawing: Started to cleanup pgf and tikz layers. Ongoing...
- graph drawing:
    - Fix Walshaw algorithm to properly set the subnodes when copying
      the coarse graphs. Simplify the code that updates the node
      coordinates.
- graph drawing:
  - Modify the doclet to allow underscores in parameter names.
    - Document the Vector class as well as the table, iter and traversal
      helpers.
    - Remove old table and iterator helpers. Rename helper files. Rename
      table.merge() and table.copy() to table.custom_merge() and
      table.custom_copy() to avoid name clashes with luatools. Add 
      string helpers, including string.parse_braces(). Update algorithms 
      to work with these changes.
    - Allow vectors to have an origin vector, similar to the Position
      class. Introduce new alternative table-based syntax for
      Vector:set() that is much easier to read. Update unit tests
      and algorithms. 
- fpu: added support for log10 and log2
- graph drawing: 
  - Drop the 'not yet positionedPGFGDINTERNAL' node name prefix
    internally. It's stripped off now when nodes are passed over to
      Lua and its added back again when shipping the node out to TeX.
  -    Drop the Node:shortname() method which is no longer needed.
  - Improve coding style and documentation of the Interface, Sys, 
    Node, Edge and Graph classes. 
  - Rename Sys:logMessage() to Sys:log().
  - Make parameter labels in the API docs not appear in bold.
    - Disable verbose logging by default.
    - Add methods Edge:getNodes() and Node:getEdges().
- graph drawing: 
  - Initial work on spring-electrical and layered drawing algorithms.
    - Major rework of the Lua code of the graphdrawing library: added
      a Vector class for improved math operations and node positioning,
        added quite a number of table and iterator helpers, added
        post-processing code for fixing the orientation of graph drawings,
        updated the graph/node/edge data structures to store nodes in the order
        they appear instead of storing them in a random order, implement
        coordinate keys for nodes, and much more.
- number printing: added '1000 sep in fractionals' switch
- Work on pgflibraryluamath (added pgfpointnormalised)
- Graphdrawing library documentation, split into two files, removed
  noluatex file, reworked the text (added information).
- First attempt to do math with lua (very basical): pgflibraryluamath
- bugfix for rounding error in \pgfmathdivide{83.407811000}{16.68156400}
  was 4.10, is now 5.0: it could happen in rare cases that digits where 
  appended where they shouldhave been than added (4 + .10 instead of 4 + 1.0)
- Implemented a G_n subgraph for creating grid (or: mesh) graphs.
  This also introduces a new key /tikz/graphs/wrap after=<number> that
  configures how the nodes in such a grid graph are connected. Some of
  the common subgraph keys such as /tikz/graphs/V and /tikz/graphs/n 
  can be used with G_n subgraphs as well.
- Added a simple grid placement strategy. It currently does not 
  support the chain shift and group shift keys properly and does not 
  implement any placement order other than left-to-right, so there is
  room for improvement.
- external lib: reduced number of \newwrite allocations and allowed to disable features
  to safe more of them (aux in dpth=false,disable dependency files)
- added '/pgf/number format/relative' formatting style.
- Finished documentation of data visualization (sort of)! 
- First usable version of data visualization!
- Worked on dv documentation. Finished chapter on visualizers,
  style sheets. Legends still missing
- Worked on dv documentation. Finished chapter on axes.
- Incorporated a bugfix of Hans Hagen which makes pgf compatible with
  Context Mk IV.
  Verified: the patch is backwards compatible with TL 2009 and TL 2010
  i.e. Context MkII and it works with Context Mk IV.
- Worked on dv documentation.
- Attempt to fix a bug #1911195 with pgfpages and rotation (fix
  contributed by Mark Wibrow). Note: Mark was not sure it has side
  effects.
- Documentation will now compile with auto-xref enabled (a problem
  with \_ in the graph lib not handled correctly by
  pgfmanual.pdflinks.code.tex).
- Fix bug #3104978 thanks to Heiko Oberdiek patch on ctt.
- Changed the graph syntax for anonymous nodes in the graph
  library and simplified the as= syntax.
- Added fresh nodes options to graph library.
- Fixed graph lib so that it compiles with plain TeX.
- Small fixed in the graph library.
- Finished graph library!
- Nearly finished graph lib and its documentation.
- Fixed bug #3123605 (hopefully...).
- Worked on graph lib.
- Some integer arithmetics functions for the math parser
  (contributed by Alain Matthes): gcd, isprime, isodd, iseven
- Second attempt at making \tikz work also with fragile stuff
  following. The new code will no longer fail in a situation
  like \tikz \foreach ...
- Worked on graph lib stuff.
- A luatex version of the doc is available (fixed inputenc issues
  since luatex works with utf8 by default).
- Fix bug in pgfmathfunctions.basic.code.tex (bug reported by
  Alain Matthes and fixed by Paul Gaborit on fctt): wrong
  interaction between pow and exp (linked to \pgfmath@x modified
  outside macro call).
- Make \pgfkeys@exp@call long (bug reported by Florent Chervet on
  fctt)
- Fix bug in pgflibraryshapes.callouts.code.tex: \pgf@test changed
  to \pgf@node@name (bug reported by Zarko F. Cucej on ctt and fix
  contributed by Mark Wibrow)
- fixed bug 3096333 (Fix contributed by Mark Wibrow): pgffor
  failed to update \lastx in some cases 

### Contributors

- Christophe Jorssen
- Jannis Pohlmann
- Mark Wibrow
- Matthias Schulz
- Till Tantau
   
## [2.10] - 2010-10-25  Christian Feuersaenger 

### Changed

- closed a lot of bugs on sourceforge, especially documentation bugs
- fixed bug 2429749: gnuplot invocation in tabularx did not work.
- fixed bug: there was an incompatibility between pgf and beamer due to a
  missing \interlineskip in the shipout handling for latex.
- renamed 'halfcircle' marker to 'halfcircle*' and added 'halfcircle'.
- provided special case 'mark color=none' for the half-filled markers.
- fixed incorrect fill/stroke coloring of new marker contributions (see
  ChangeLog 2010-09-27)
- added more predefined dashed and dotted line patterns for black/white plots
  to fulfill a related feature request of Tomek
- fixed bug: the 'name path global' feature did not work in every case...
  the actual implementation might need to be revised eventually.
- Imported spell checking results of Stefan Pinnow (thanks!)
- Dealed with typo in 'sci generic' number formatting style: it now
  accepts 'mantissa' *and* 'mantisse'
- External lib: Fixed bug. The 'failed ref warnings for' was not properly \protect'ed.
- Started on graph lib. Not yet finished and not documented.
- Added plot markers of Magnus Tewes and Tomek: halfcircle, halfsquare*,
  halfsquare left*, halfsquare right*, heart
- Added \pgfpositionnodelater and \pgfpositionnodenow
  commands.
- externalization+\ref: fixed a bug
- external lib: documented how to generate .png graphics and added support
  switches.
- added 'baseline=default', 'trim left=default' and 'trim right=default' choices to reset these keys.
- added support to provide paragraphs in "pin" arguments
- Worked on data visualization and its documentation.
- basic level externalization: added \hoffset=0pt and \voffset=0pt to improve
  compatibility with special document classes
- added docs for \deferredanchor feature contributed by Christophe Jorssen
- ConTeXt support: fixed loading problem of calendar lib
- pgfsys-tex4ht.def: fixed problem with \par in a non-long macro argument,
  thereby eliminating a compilation problem
- pgfsys-tex4ht.def: renamed offending macro invocation \Par to \par
- basic level image externalization: added '/pgf/images/trim external={<left>}{<bottom>}{<right>}{<top>}'
  to allow modifications to the hardcoded '1truein' shifts.
- added '/.style n args' key.
- \usetikzlibrary / \usepgflibrary: added support for white-space trimming
  and empty arguments in the lists. Now, lines do not need to be terminated
  by '%' and ',,' is valid.
- external lib: documented how to solve compatibility problems with
  \tikzifexternalizing
- added \deferredanchor feature contributed by Christophe Jorssen 
- added optimized and numerically stable arc path command
  \pgfpatharctoprecomputed which interpolates start- and end points
- external lib: fixed incompatibility with 2010/06/08 v2.0b eso-pic package 
- external lib: added sanity checking for failed \ref,\pageref,\cite commands in external images.
- math parser: improved error messages by providing the complete math expression.
- added 'trim left' and 'trim right' features to simplify bounding box
  modifications and allow support for restricted bounding boxes and image
  externalization.    
- pgfutil-latex.def: changed \usepackage to \RequirePackage (thanks to Christophe Jorssen)
- external lib: added \tikzappendtofigurename{} shortcut for '\tikzset{external/figure name/.add={}{suffix}}'
- external lib: added warning at end of document if not all graphics have
  been found.
- updated file 'tikzexternal.sty' for \label and \ref support inside of
  externalized graphics
- documented how \label and \ref support in external graphics works.
- activated \label support for mode=convert with system call and
  documented limitations.
- added \tikzifinpicture{<true code>}{<false code>} macro
- Worked on data visualization.
- Added .list key handler.
- Worked on data visualization.
- improved sanity checking in number printer: now, the zero flag is
  checked even if its exponent > 0
- floatparsenumber: number format errors after exponents now contain the offending
  character instead of '\relax' 
- number printer: added 'frac denom' and 'frac whole' for fine tuning of
  fractional number printing.
- number printer: made \protect portable across TeX variants (doesn't
  produce bugs with context anymore)
- fpu: optimized \pgfmathfloatgetflagstomacro
- added \pgfresetboundingbox
- added \pgfgetlastxy coordinate macro
- added '/pgf/images/include external/<image name>' code key.
- fpu: added convenience method \pgfmathfloattoint
- number printer: added 'frac' style to automatically create fractionals.
- splitted basic level file pgfcoreimage.code.tex: there is now a 
  pgfcoreexternal.code.tex file.
- \pgfmathprintnumber is no longer a "fragile" command (it is \protect'ed
  automatically in LaTeX).
- Fixed baseline alignment with "text width" option in LaTeX.
- New divide function
- Rewrote code foreach extensions. Now no longer an impenetrable mess.
  pgffor.code.tex is much larger, but contains some (as yet) undocumented 
  features which may get optimised out.
- Image externalization: added '/pgf/images/aux in dpth' feature.
  It allows to store \label and other .aux file related stuff in the image's
  .dpth file which is processed when when the main document includes the
  image.
  The new switch is on for the semi-automatic modes of the external lib, otherwise it is
  off.
- pgfkeys: added '.code n args' handler. The difference to '.code
  args={#1#2#3}' is that keys defined with 'code n args' gobble spaces
  between the arguments.
  Note: 'code 2 args' remains as-is (it has the special feature that the
  second argument is optional).
- fixed bug in '/.add code' key handler: it didn't work properly for
  complicated keys
- pgfkeys manual section: updated xrefs and docs
- external lib: \tikzexternalize no longer needs (but still accepts) the
  main job's name. Changes are now documented and the replacement |.sty|
  file has been updated.
- intersection lib: added 'name path global' feature.
- external lib: partially fixed incompatibility with glossary package and
  documented work-around
- FPU: added \pgfmathfloatifapproxequalrel 
- number printing: added style to configure |sci precision|
- number printing: added style to configure |std=<lower e>:<upper e>|
- external lib: the <real job's name> argument from \tikzexternalize is
  now optional. It can be deduced automatically if it is missing.
- number printing: added 'sci generic' style to customize the appearance
  of scientific format and a 'verbatim' style which doesn't use TeX macros
  for the formatted numbers.
- external lib: now, a |\jobname.auxlock| file will be generated in order
  to detect whether the \jobname.aux file is in its final state. This allows
  to export any images containing |\ref{}| manually; the automatic procedure
  will not use the .aux file.
- Added \ifpgfexternalreadmainaux switch. Will be used to avoid buffering
  problems during externalization mode 'convert with system call'.
- Fixed bug "papersize not supported by pgfsys-xetex.def - ID: 2934982"
- Improved automatic cross referencing: auto key path prefixing failed for
  spaces in key paths.
- Added "on background layer" key to backgrounds lib.
- added \pgfmathifisint
- supported \nofiles in auto xref generation
- externalization: both, basic layer and external lib now support \ref{}s
  inside of externalized pictures. Furthermore, they won't generate any aux
  files on their own (which wouldn't be thread safe and is not useful
  anyway)
- external lib: fixed bug with figure list/makefile handling and file
  deps: calling file dependency handlings outside of a picture could result
  in compilation failures
- external lib: mode=list and make now supports the force remake keys.
- external lib: the -shell-escape switch for nested system calls is
  activated only if it was active for the main document. This should allow a
  reasonable security measure for mode=list and make (which will also work
  without system calls from within TeX).
- external lib: added support for file dependencies.
  For mode=list and make, any file dependencies configured with
  \tikzpicturedependsonfile{<name>} will be checked by the generated
  makefile.
- profiler library now uses an output file which contains the current date
  and time. Furthermore, it counts every invocation and allows to show every
  command invocation (optionally with arguments expanded).
- profiler library can now profile macros with arbitrary argument pattern
  and is more rebust with respect to save stack usage
- worked on profiler library and added docs for it.
- added first draft of the pgf 'profiler' library
- Fix for rounded corners affecting custom fills in rectangle 
  split shape.
- updated the 'make dist' documentation target such that it compresses
  every pdf object. The resulting manual is half as large than without
  compression, but it requires pdf 1.5 (at least acrobat 6.0).
- external lib: some output messages did not respect the 'verbose
  IO=false' flag; fixed that
- fixed buggy treatment of some automatic cross references in manual
- external lib: improved the tikzexternal.sty package which can be used
  without pgf installed.
- added spy library.
- imported a patch of Andy Schlaikjer which extends the 'plot gnuplot'
  feature to read the “unbounded point” information provided by gnuplot.
- added \r@pgf@reada temporary \openin register for compatibility with
  other packages
- fixed an auto xref bug which wrote '\pgfkeys{}' although the manual
  contained |\pgfkeys|.
- external lib: the 'optimize command away' things where not activated
  accidentally. I fixed it.
- added support for new paragraphs in pgfkeys values
- fixed bug in |const plot| handler (and all its variants): the first
  coordinate was transformed twice
- auto xrefs now support point coordinate systems.
- auto xrefs now provide an interface to deal with tricky active
  characters (for |-)
- external lib: improved compatibility with |fadings| libary.
- replaced 'set terminal table; set output "<file>"' by 'set table "<file>"'
  to maintain compatibility with the new gnuplot version.
- pgfmanual.pdf: provided a 'make dist' target in version_for_pdftex/en
  which activates automatic hyper references from codeexamples to key
  declarations.
  This utilizes larger memory limits, configured in
  doc/generic/pgf/text-en/texmf.cnf
- Added the 'small mindmap' style.
- FPU: improved sanity checks and exception handling for the decompose
  routines (pgfmathfloatgetexponent etc) and the number parser.
  Added exception 'wrong lowlevel format'.
- renamed 'text mark/style' to 'text mark style' and 'text mark/as node'
  to 'text mark as node' (there are backw. compatibility hooks).
  This should avoid confusion with '.unknown' handlers.
- improved error recovery of external lib.
- temporarily disabled the auto cross references -- it seems they compile
  only with increased memory.
- Installed preliminary version of automatic cross referencing tool.
  Now, every codeexample is parsed for options and control sequences which
  have been defined somewhere else in the document; pdf cross references are
  built automatically as well.
- configured links to be blue throughout the document.
- external lib: added \tikzexternaldisable such that partial externalization is possible
  although the document contains unsupported constructs (where environments
  can't be identified without macro expansion).
  The pgfmanual compiles with image externalization now.
- added \pgfutilsolvetwotwoleq to solve 2x2 linear equation systems using
  column pivotisation and gauss elim. Should result in improved quality
  compared with \pgftransforminvert as internal equation solver
- Defined \pgfdeclaregenericanchor to allow anchors which get the shape
  name as argument. Only useful internally.
- Fixed buggy treatment of white spaces in \jobname and 'plot function'
  using \pgfutilpreparefilename.
- Fixed bug item #2834141 [wrong reversed double arrows]
- Fixed bug item #2834233 [shapes libraries]
- Fixed bug item #2822265 [tangent coordinates not working in CVS]
- Changed \rm to \tf in Context.
- external lib: added 'mode=list and make'. Now, image externalisation
  time can be reduced with 'make -j 2 -f mainfile.makefile'.
- external lib: fixed treatment of long arguments in \tikz ... ; shortcut
  command.
- fixed white space bug in \pgfkeysdeactivatefamily
- added \pgfmathfloatvalueof
- added a '*' feature to '\pgfmathdeclarefunction' which overwrites
  existing functions.
- added '/tikz/no marks' key.
- fixed typo in external lib documentation: the key is called 'figure name',
  not 'file name'
- added \pgfgettransformentries and \pgfsettransformentries.
- updated the external library such that it deals with active characters
  in the same way as without external library.
- fixed bug in fpu cosh, sinh and tanh
- provided two new aliases for key filters, added \pgfkeyssetfamily.
- allowed numbers like '.9' in fpu.
- Fix for signal shape. 
- Applied the patches for dvipdfmx driver,
  pgf-doc-diff.version2cvs (2009-04-18) and
  pgf-generic-diff.version2cvs (2009-04-19).
- Restored processing of unknown keys in the predefined key filters 'and',
  'not', 'or' and 'false': it was not improvement...
- fixed the sequence of arguments of
  \pgfqkeysactivatefamiliesandfilteroptions and 
  \pgfqkeysactivatesinglefamilyandfilteroptions
  in the reference manual.
- key filtering: the composed key filter handlers 'not', 'and', 'false' and 'or' now 
  ignore unknown options and call the .unknown handlers.
- pgfkeys: removed the experimental \pgfkeyssetdefaultpathforhandled method.
  It doesn't fit into the clean interface for pgfkeys - and the problem of
  default paths for handled keys can be solved better with the '/handler
  config' method.
- provided API function \pgfmathfloatifflags to simplify special cases in
  FPU.
- added (primitive) veclen implementation for FPU.
- added cosh, sinh, tanh to FPU
- fixed bug in external lib: empty lines in tikzpicture environments were not accepted 
  for some operating modes.
- added \pgfqpointscale
- added an optional argument count to 'optimize command away' in external
  library.
- added the |figure name| key to the externalization library
- improved docs for externalization library
- improved sanity checking of floating point comparison: does now also
  yield results for infty/nan
- added fix for precedence bug for unary minus (fix has been suggested by
  Mark Wibrow, by mail conversation)
- Replaced \z@ by 0pt for context.
- external library: fixed the 'optimize' feature: pictures which won't be
  exported could not be optimized away (although they should)
- Replaced \toks@ and \voidb@x by \pgfutil@toks@ and
  \pgfutil@voidb@x. 
- improved docs for .search also.
- fixed initial value for 'domain' such that it really uses the default
  samples=25.
- Added patch for context color support in luatex.
- improved the optimization facilities of the external library:
  |optimize=false| will now properly restore any optimized material 
  when used in \tikzset
- added |/handler config=all,only existing,full or existing|
  configuration.
- added |.search also| key handler as a simple implementation of key
  search paths.
- fixed default value for /tikz/samples at- there are no really 25
  samples, not 26. I forgot to fix this last time when I fixed 'samples'
- added |\pgfkeyssetdefaultpathforhandled| feature as improvement for
  multiple key paths to pgfkeys. Reference documentation and an 
  application example is in the manual.
- added 'mark=text' which draws arbitrary TeX content as plot marks to
  plot mark library.
- Added key 'define function' to define simple local functions. 
- Worked on dv stuff.
- Index argument to array is automatically truncated to an 
  integer.
- Text decoration can now be aligned along or fitted to a path.
- Added key '/pgf/decoration/reverse path' to decorate a path 
  backwards.
- the FPU deactivation command is now assembled once and for all during
  its first usage.
- Changed the "ellipse", "circle" and "arc" commands, so that
  they take options. This gives a much clearer and more
  flexible syntax. Naturally, the old syntax continues to work
  as expected. 
- Documented svg stuff and added tikz interface. Most useful
  for quickly converting svg pictures to tikz pictures...
- fixed fpu 'round' method - it rounded mantissas instead of the complete
  number before.
- Fixed some math stuff
- Renamed \pgfpathcurvebetweentime* to
  \pgfpathcurvebetweentimecontinue. 
- Added svg.path lib. It allows one to directly use
  the svg syntax for paths (like "M10 10 L 20 20"). Not yet
  documented. 
- Added tutorial for mind/lecture maps.
- implemented fpu factorial
- if the fixed point library is activated, the fpu will be deactivated
  automatically.
- added draft for FPU documentation
- fixed bug in fpu sqrt.
- added logical commands to fpu.
- fixed bug in fpu related to multi-argument-commands
- provided feature to disable fpu manually.
- added support for pgf 2.00 and the fpu (works only with additional
  and technical work - the fpu file is not all which is needed)
- added pow and greaterthan to FPU
- fixed some FPU issues
- fixed processing of '/tikz/domain' key - it produced N+1 samples instead
  of N.
- added further functions to fpu; improved sanity checking; fixed smaller
  bugs related to fpu
- improved internal floating point code: it is possible to change the
  low-level representation with minimal number of code lines.
- modified low-level floating point representation. All high level code
  should be completely unaffected; the changes are backwards compatible.
- Wrote first draft of a floating point unit library (fpu) similar in
  spirit to the fixed point library of Mark Wibrow.
- Moved all floating point math operations (functions) into the fpu
  library. It is now necessary to include the library in order to use
  floating point math operations. The number formatting methods are still
  available as before.
- added trigonometric functions to floating point unit.
- Added \colorlet to ConTeXt stuff.
- Worked some more on data visualization stuff. Still in
  pre-alpha. 
- added \pgfmathfloatexp.
- floating point macros now always use the basic pgf math methods for
  mantisse computations, even if the fixed point library is active.
- 'mark=none' is now equivalent with 'mark=' (disables plot marks).
  The previous behavior was to issue \pgfuseplotmark{none} which is
  equivalent to \relax (and wastes time).
- Changed exp function code in
  pgfmathfunctions.basic.code.tex. It is now *much* more
  precise for negative values and also more precise for
  positive values.
- optimized \pgfmathfloattofixed for speed (although it introduces
  redundand zeros)
- Added '/pgf/image/include external' command key as public interface 
  to modify the '\includegraphics' command in image externalization routines.
- fixed bug with |overlay| option and matrizes: now, cell pictures won't 
  collapse any more if the matrix has |overlay| enabled. However, the
  matrix' bounding box won't contribute to the image as desired.
- added support for active '!' characters (for example in blue!30!black
  and french babel setting)
- modified processing of 'domain' option: the argument is '\edef'ed such
  that any potentially active ':' characters will be expanded to non-active
  ones (avoiding errors in the following processing).
- Fixed \pgfnodealias bug that caused chains to fail in matrices.
- Added shading library, mainly containing the new color wheel
  shading donated by Ken Starks.
- More fixes for insertion of spaces.
- Added square arrow send by
  gvtjongahung@users.sourceforge.net.
- Changed pgfutil-context.def so that driver detection should
  work once more.
- Fixed insertion of space when parsing exponents.
- added int truncation to floating point unit.
- added abs, abserror and relerror to floating point unit.
- added sqrt for floating point unit, built on top of pgfmathsqrt.
- Fixed the wrong lengths of support vectors for circles. Used to
  be 0.555 (found by trial and error), while the correct value
  is 4/3*(sqrt(2)-1) = 0.5522847, which gives much better
  circles.
  Thanks to Ken Starks for point this out.
- Fixed rounded rectangle right arc bug.
- Fixed missing treatment of 'assume math mode' in \pgfmathprintnumber'
- Fixed missing switching off of auto anchors in positioning
  library. 
- Fixed matrix/pdfsync incompatibility.
- Fixed some parsing bugs with arrays.
- Fix for parsing of arrays in TikZ coordinates. 
- Added number formatting option 'min exponent for 1000 sep'.
- Fixed bug in math parser which inserted spaces into text
  or picture.
- added number formatting style 'sci superscript'
  Example: formats the number 42 as 4.2^1 instead of 4.2 \cdot 10^1
- Fixed bug "TikZ, the shadow library and ConTeXt MKIV
  (LuaTeX)". 
- Fixed bug #2105132 for rounded rectangle.
- Fixed bug #2044129 for chamfered rectangle.
- Added \pgfpathcurvebetweentime.
- Fixed problem with nodes on a line inside a picture that is
  inside a node of another picture. Pictures will now always
  start with "pos=.5" set.
- Slight hack of decorations so that the input path can consist of a
  single move to. This enables stuff like 
  \path [decoration={some decoration}, decorate] (4,5);
- fixed small bug related to '@dec sep mark' and not-a-number in number
  formatting routines.
- Solutions for path intersections can now be sorted along either path.
- \pgfintersectionsolutions is now a macro, not a count register.
- fix for `Missing character...` warnings in logfile when using 
  foreach.
- removed `trim integers' option from foreach as int function 
  can now be used.
- Rewrote math parser. Anyone who relies on, or has hacked internal 
  parser or function macros, or has defined their own functions for
  the parser will need to reconsult the code and/or documentation. 
- Files for functions definitions split (possibly permanantly) into 
  different files.
- Scaling of results at the end of the parse is no longer the default 
  action. This doesn't break PGF or TikZ, but it may break user code
  that depended on this scaling. To turn it back on use 
  \let\pgfmathpostparse=\pgfmathscaleresult. 
- Modifying existing functions or creating new functions must now be
  done using \pgfmathdeclarefunction and \pgfmathredeclarefunction.
- Single argument functions do not need parentheses, provided the
  funtion is followed by a space, so sin 60 is the same as sin(60).
  But! Functions have the highest precedence, so sin 60*\x is the 
  same as sin(60)*\x.
- Added {} operators for array specification and [] operators for 
  array access - see docs for details.
- added postfix ! factorial operator.
- added c++/java style conditional e.g., \x > 10 ? 13 : 20.
- added >=, <=, !=, prefix !, &&, || operators.
- added atan2, log10, log2, e, int and frac functions.
- adapted cosh, sinh and tanh from Martin Heller.
- added lua-style random function for generating random integers.
- added Mod function (note capital letter). Uses floored division
  and is never negative.
- min, max, veclen and pow can now be nested in any argument 
  position.
- min and max can now take a variable number of arguments.
- For compatability \pgfmathmax and \pgfmathmin still take two 
  arguments (although these can contain comma separated expressions). 
  However \pgfmathmin@ and \pgfmathmax@ now only take
  one argument in the form \pgfmathmin@{{1}{2}{3}{4}{5}} (for 5 
  arguments).
- added hex, Hex, bin, and oct functions. These functions will not
    work properly if the post-parse scaling is turned back on.
- 0 prefix for integers now specifies an octal number which is 
  automatically converted to base 10.
- 0x or 0X prefix for integers now specifies a hexadecimal number, 
  which is automatically converted to base 10. 
- 0b or 0B prefix for integers now specifies a binary number, 
  which is automatically converted to base 10.
- "" characters turn off parsing (!) for part of an expression.
- added width, height, and depth functions for text e.g., 
  width("Some text"), but as an expression is \edef'ed before
  parsing other commands will have to be `protected` e.g.,
  width("\noexpand\Huge Some text").
- bugfix for tan and cot. 
- added '/tikz/external/export={true,false}' key for externalization
  library.
- added documentation for basic layer externalization and baseline option.
- added 'showpos' key to number printing (and alias 'print sign').
- fixed typo in pgfmathfloat.code.tex
- added 'optimize command away=\macro' key to externalization library. It
  allows to discard unnecessary and possibly expensive user macros during
  export (unnecessary = not in selected picture).
- Fixed bug in system layer path collecting. Very long paths
  are now processed more efficiently (the bug disabled an optimization).
- added "marker" positions into the output of number formatting routines
  to find period positions (even if no period is typeset) and exponent
  positions. Allows alignment within auxiliary routines.
- Fixed dash phase bug.
- Fixed missing library include in automata lib.
- Added "align" option. "text ragged" and friends are now
  deprecated. Text width need no longer not, but can, be
  specified. The following now has the expected effect: \node
  [draw,align=center] {Hello\\world.}; 
- added \pgfqpointxy and \pgfqpointxyz to complement the "quick" point
  commands in basic layer.
- added 'every mark' style.
- 'mark options' simply overwrites 'every mark' (consistent with its old
  definition)
- Finished circuit library and documentation (well, some
  shapes still missing, but that's something users should
  contribute). 
- the external library now handles active double quotes ",
  single quotes ', and active semicolons ';' in its system call
  correctly. Furthermore, \\ will expand to a normal
  backslash. The initial system call now uses double quotes
  for indows compatibility, it also contains the shell-escape
  feature for gnuplot invocations.
- Did some documentation of circuit lib.
- Removed the separated documentation of the intersection
  library and made this documentation part of the main
  documentation. 
- The intersection cs is now deprecated, the documentation
  is now only based on the intersection lib. 
- Added a "by" option so that "name intersections={of=A and
  B,by={c,d,e}}" will create an alias c for intersection-1, d
  for intersection-2 and e for intersection-3.
- Renamed "path name" to "name path" in the intersection
  lib. This is more consistent with "name intersections".
- Minor changes on float stuff, wrote pgfmathfloatmultiply and
  pgfmathfloatdivide on top of pgfmathmultiply and pgfmathdivide
- Added `Fixed Point Arithmetic' library, which provides
  a parsing interface to the fp package. Dealing with plotting
  files still a bit crude. 
- This library means the manual now requires the fp pacakge 
  to compile.
- Fixed floor function for negative numbers.
- Fixed \pgfmathsetseed.
- Font and group fix for external documentation.
- Complete change of TikZ intersections (PGF unchanged).
- Slight hack of the TikZ scopes library to permit local
  path naming. Should work...
- Continued with circuit library.
- Introduced subdirectories inside the pgf library
  directory and moved libs into them.
  You may need to update your checkout.
- The external library now typesets as horizontal material by issueing
  \leavevmode. This fixes an inconsistency with the normal tikzpictures.
- Added intersection library + documentation for 
  intersecting “named” paths.
- Fixed bug in external library. Now, strings like '#1' occuring 
  somewhere in an image is collected correctly.
- Removed new intersection stuff. Need to restart from scratch...
- Started working on circuit library documentation.
- Added PGF code and docs for intersections of two curves and 
  intersections of a line and a curve.
- Fixed bug in foreach code when registers are used with dots
  statement.
- Created first version of circuit libraries for electrical
  engineering (circuits.ee.*). 
- Added libraries so that ee circuits and logical circuits can
  be accessed using the same interface. (circuits.logic.*)
- The tikz lib shapes.gates.logic.* will no
  longer be needed, the circuits.logic.* will replace them. (The
  pgf libs shapes.gates.* are still used as before, however.)
- Minor patch in shapes.gates.logic.US so that the .0 and .180
  anchors of a not gate or a buffer gate are the same as the
  input or output anchors.
- All this is not documented, yet.
- Worked some more on dv stuff, but nothing to "show", yet.
- Fixed parsing bug in foreach code.
- Added "rotate fit" key to fit library, so (e.g.) a rotated 
  rectangle can be fitted around nodes/coordinates.
- Added documentation for tikz 'external' library.
- created pgfexternalwithdepth.tex file to use the 'baseline' information.
- improved some issues of the external library.
- Added '/pgf/images/draft' option
- Modified implementation of draft images to show the image file name
  instead of the internal image name
- Added tikz library 'external' which allows automatic or semiautomatic 
  export of each tikzpicture to pdf. Documentation is not yet ready.
- Added self-contained latex package tikzexternal.sty to read those images
  without tikz/pgf installed.
- Added support for the 'baseline' option in \beginpgfgraphicnamed ... \endpgfgraphicnamed
  by storing the box depth into a separate file.
- Added first ideas for a circuit library.
- Bugfixes in scoping behaviour.
- Changed scoping rules for to path operation: Options are now
  local. This may break existing code, but is much more
  consistent with everything else and removes other problems. 
- Patched mindmap lib to account for these changed rules.
- Added insert path option.
- Deprecated "after node path". Use "append after command" and
  "prefix after command" instead.
- Moved datavisualization libraries to separate subdirectory.
- Changed label and pin options once again, to allow more
  flexibility. In particular, the angle can now be
  omitted. Also, for rotated main nodes the anchors are now
  chosen in more sensible ways.
- Added tiny little turtle graphics library for fun.
- Changed scoping rules for \foreach statement on a path: the
  last coordinate is now persistent not only after the foreach
  statement, but also between different iterations.
- Changed positioning of "label" when you attach a label to a
  transformed shape. The position is now absolute with respect
  to the page, unless the "transform shape" option is used.
- Fixed the bug fix for character checking in foreach.
- Updates and fixes for new foreach code.
- Fixed bug in new \foreach stuff that causes an error on
  things like \foreach \i in {1,...,\foo}. If a list element
  is a macro, no is-it-a-character check is done.
- Checked in proposed \foreach extensions. Possibly the
  extensions would be better contained in a pgflibrary...
- list items can now be evaluated.
- dots replacement is context sensitive.
- sequences indicated by dots can be character sequences.
- a list item can be “remembered” in the next iteration.
- access to the number of the current item in the list is
  provided. 
- Worked a bit on data visualization stuff.
- Added '/pgf/number format/1000 sep' and 'dec sep' shortcut 
  styles which simply call 'set thousands separator' and 'set 
  decimal separator'. Those option are somewhat long...
- Fixed the "local bounding box" option so that it honors the
  "relevant for picture size"-if.
- Fixed buggy "mid left" and "mid right" options.
- Added "between positions" option to the "mark" option. This
  makes it possible to create paths with "repeated arrows along
  the path". This did not work before.
- Added '/pgf/number format/assume math mode' to disable math checks. 
  This allows to assemble tabulars, apply \pgfmathprintnumber to each cell
  and use the dcolumn package to align at decimal separators (no
  documentation for that feature yet)
- Fixed pgfpages in conjunction with everyshi.
- Semantics of |/pgf/number format/fixed zerofill| changed: it now simply
  sets a boolean which affects all numbers in fixed format; it does not
  SET fixed format. The same holds for sci zerofill.
- Provided \pgfmathprintnumberto macro in addition to
  \pgfmathprintnumber.
- Revised Lindenmayer system stuff. Documentation should 
  now be up to date.
- Added 'xbar interval' and 'ybar interval' plot handlers.
- Moved plot handler options to /pgf key tree.
- added 'bar shift' option.
- bar width option is now evaluated when needed.
- Added documentation for plot handler library changes and for tikz-plot
  interfaces.
- Modified pgf manual macros: codeexamples section now employs pgfkeys,
  xkeyval no longer required. Introduced style 'every codeexample' to
  maintain compatibility and allow customization for users.
- Added missing documentation of moveto-decoration.
- Changed the processing of \pgflsystemstep. Now a TeX
  dimension, it permits a symbol to shorten the step.
- Added Lindemayer system drawing library.
- Renamed the ranomization keys for the step and angle.
- Updated the L-system docs.
- Added documentation of oo-subsystem.
- Started documentation of data visualization-subsystem.
- Fixed hyperlink problem in dvipdfm(x)/xetex.
- Fixed typos in Lindemayer system doc.
- Added \pgfmathfloatadd, \pgfmathfloatsubtract and
  \pgfmathfloatmultiplyfixed based on pgf's normal math parser
- Added tests for float arithmetics
- Added \pgfmathfloattoextentedprecision for 8-digit mantisse precision
- Added documentation for these methods
- Added basic layer input stream methods to set zero levels for [xy]comb/[xy]bar;
  allows to start bars at different offsets than x=0 / y=0.
- Added documentation for zero level streams.
- Added "path picture" option, mostly for the implementation
  of the corrected mindmap connecting bars.
- Fixed buggy code of mindmap connect bars: Shading angles
  where sometimes wrong and shading was sometimes at the wrong
  position.  
- Completely rewrote management of pdf resources. This affects
  pdftex, dvipdfm, dvipdfmx and xetex backends and all front
  ends. They should now all work together in harmony, as far
  as this is supported by them.
- Completely rewrote driver detection in plain and context
  mode. 
- dvipdfmx and xetex now use \special{pdf:literal direct},
  which can *considerably* reduce file sizes (up to a factor
  of 2).
- Fixed compatability issue with old calc code.
- documented '.lasttry' key handler
- introduced documentation for key filtering routines (as \input section
  in pgfmanual-en-pgfkeys.tex). Main section of pgfkeys not really updated
  yet; I only removed the 'family limitation' item in the introduction.
- Multiple fixes for signal shape.
- added \pgfplotbarwidth and docs
- used \pgfmathparse to assign \pgfsetplotbarwidth
- added 'const plot mark right' to plot handler library to complete the
  different variants of left/right connected/jump handlers.
- Fixed parser for expressions that begin and end with braces.
- Added \pgfmathapproxequalto operation and documentation below
  \pgfmathequalto
- Added some user-interface methods to floating point arithmetics
- Added options
    /pgf/number format/set decimal separator
    /pgf/number format/set thousands separator
    /pgf/number format/skip 0.
- Added documentation for floating point arithmetics
- Added documentation for number printing
- Added PGF plot handlers to plot handler library:
    - \pgfplothandlerxbar
    - \pgfplothandlerybar
  with parameter \pgfsetplotbarwidth{} and
    - \pgfplothandlerconstantlineto
    - \pgfplothandlerjumpmarkleft
    - \pgfplothandlerjumpmarkright
- Added Tikz-Plot handlers
    - /tikz/xbar
    - /tikz/ybar
  with option '/tikz/bar width' and
    - /tikz/const plot
    - /tikz/jump mark left
    - /tikz/jump mark right
- Added documentation for new plot handlers to Tikz- and plot handler
  section in manual
- Documented changed double line handling.
- Made some arrow tips work with double lines.
- Added (not yet documented) "inner lines", which move the
  double line mechanism from tikz to the basic layer. This
  allows the definition of special arrow tips for double lines.
- Added (not yet documented) new arrow tip "implies" using
  this mechanism.
- New version of rectangle split shape. Now supports horizontal
  as well as vertical spliting. Also supports up to 20 parts. 
- Added pgfkeysfiltered.code.tex which provides key filtering
  and provides key-selection utilities like xkeyvals families
- changed pgfkeys.code.tex to '\input' pgfkeysfiltered.code.tex
- Added \tikzaddtikzonlycommandshortcutlet and
  \tikzaddtikzonlycommandshortcutdef to install shortcut commands at the
  beginning of tikzpicture.
- pgfkeys.code.tex: fixed incompatibility .try with .is choice
- Fixed patterns in dvips mode (were broken).
- Switched to everyshi in latex mode to hack into
  \shipout. Wrote direct code to hack into \shipout in plain
  mode. Hacking into \shipout in Context is still unclear.
- Added space arrow.
- Reimplemented parsing of operands. 
- Added cirlce solidus shape by Manuel Lacruz.
- `curve control points` decoration no longer exists. It is 
  replaced by the `show path construction` decoration.
- added code + docs for defining changable patterns.
- Parser altered to access \pgfmathfloatparsenumber when 
  \ifpgfmathfloat is true (old interface to \pgfmathfloat deleted).
- Added generic/pgf/math/pgfmathfloat.code.tex
- Modified pgfmath.code.tex to include pgfmathfloat.code.tex
- Added generic/pgf/testsuite/mathtest/pgfmathtestsuite.tex [dvipdfm/pdflatex]
  which provides testing for pgfmathfloat.code.tex
- Fixed minimum width handling in rounded rectangle shape. 
- Added key for rectangle split to ignore empty parts.
- Extended \pgfshadecolortorgb to define macros for the
  individual color components.
- Added `curve control points` decoration for drawing
  curve controls. NB: names/keys may change.
- Fix for (some) “hidden” bugs: `Missing character: 
  There is no <char> in font nullfont!`. This is usually
  only seen in log file. Fixed for star, circular sector
  and math macros.
- Fixed documentation "placment" replaced by "positioning"
- Fixed ConTeXt page resource problem. (ConTeXt support is
  still not as smooth as support of other formats)
- Checked in some data visualization stuff, without any
  documentation. Everything still likely to change
  completely. 
- Moved module management to pgfutil.
- Added support for simple oo-programming, not documented. 
- Fixed bug in pgfkeysaddvalue.
- Fixed bug of stack leak in function shadings in postscript.
- Fixed missing image inclusion documentation.
- Fixed atan bug in documentation example.
- Fixed missing dependency of chains--positioning library
- Fixed missing dependency of mindmap--decorations library

### Contributors

- Christian Feuersaenger
- Jin-Hwan Cho
- Mark Wibrow

## [2.00] - 2008-02-20 Till Tantau 

### Changed

- Fixed "initial"/"accepting" distance bug.
- Fixed wrong intersection computation bug.
- Added "local bounding box" option for Fabien...
- Finished chains and chain tutorial.
- Fixed height of rounded rectangle shape.
- Added "auto end on length" and "auto corner on length"
  options to decorations.
- Added "if input segment is closepath" option to
  decorations. 
- Renamed "subpath" in decoration code to "inputsegment". In
  the pdf-specification (and in the rest of the pgf manual) a
  path is made up of subpath, which are started by movetos,
  and these in turn are made up of segments. In decorations,
  segments used to be called subpaths, which was too
  confusing... 
- More renaming in chains, but its stabilizing now.
- Started a tutorial on chains.
- Moved chain part inside "positioning" into "chains"
  library. 
- Renamed things in the chains library, yet again and added
  branches.
- Fixed bug with "xyz of" placements.
- Renamed "placements" library to "positioning".
- Renamed and changed all chain commands.
- Added scopes library.
- Renamed cap and join to line cap and line join (but old ones
  are still available).
- Patched Makefiles according to suggestion by Hans Meine.
- Fixed bug: duplicate fading name in pgflibraryfadings.
- Fixed bug: wrong size of functional shading in dvips.
- Fixed bud: documentation a4paper setting.
- Fixed bug: Manual now compiles with tex4ht once more.
- Fixed bug: Manual now is hyperlinked also for dvipdfm.
- Fixed bug: wrong size of all shadings in svg code.
- Slight change in placement lib, default chain now has a
  name. 
- Removed internal asin tables as asin is now calculated from 
  acos tables.
- Misc. updates for shapes docs.
- Changed fit library, so that nodes are now "completely"
  fitted. 
- Changed tutorial so that fit library is now used.
- Added placement library and documentation.
- Fixes in snake compatibility code.
- Added dvipdfmx support (identical to dvipdfm).
- Fixed missing braces and color stack problem in
  shapes.logic.IEC. 
- Patched (and hopefully fixed) hyperref support.
- Made matrix inversion more precise.
- Added tutorial for geometric constructions.
- Fixed partway and intersection computations.
- Added line to circle intersection.
- Added through library (still very simple...).
- Added computation of intersection of circles and tangent to
  a circle.
- Updated isosceles triangle shape. Positioning of node
  contents improved. Added key so minimum width and height
  can be applied independently
- Fix for trapezium shape for minimum height. This fix may
  “break” exisiting code by making any trapezium enlarged using
  minimum height to appear slightly wider than before. But...
- Added keys for trapezium so that minimum width and height
  can be applied independently, or to just the `body` of the
  trapezium. 
- Reimplemented shape `tape`. Anchors should behave a bit
  better now.
- Fixed problem with pin a relative coordinates.
- Added `logic gate IEC symbol color` key to change color
  for all symbols simultaneously.
- Fix for loading US and IEC shape library separately.
- Misc. updates for decoration docs.
- Modified calc library. Working on documentation.
- Added calc library and ($...$) notation for coordinates.
- Reorganised logic shapes. Now two libraries:
  shapes.gates.logic.US (for “American” gates) and 
  shapes.gates.logic.IEC (for rectangular gates).
  Gates are now named `and gate US` or `and gate IEC` etc.
  TikZ key `use US style logic gates` and `use IEC style
  logic gates` set up styles so that (e.g.) `and gate` 
  becomes a synonym for `shape=and gate US`. See docs for
  details.
- Added decorations.markings.
- Fixed pgfpatharc: Fractional angles are now handled
  correctly. 
- Fixed incompatability with bm package: Changed hack to
  \@@end to \AtEndDocument.
- Changed things in the math engine to speed up things: First,
  \pgfmath@returnone now uses simpler and faster code. Second,
  some marshals in the internal math commands like
  \pgfmathadd@ have been removed. This makes it necessary that
  the second operand in a call to an internal math macro no
  longer uses \pgf@x or \pgf@xa and I fixed the 3 places where
  this was the case.
- Added footprint decoration and merged Marks footprints.
- Added buffering to the subpath mechanism. This speeds up
  constructions of very long paths by a factor of 10 or more. 
- Fixed missing declaration of \iftikz@decoratepath in
  tikz.code.tex. 
- Added logic shapes library. Includes AND gate, NAND gate,
  OR gate, NOR gate, XOR gate, XNOR gate and NOT gate.
- Fooled around with title page.
- Changed TikZ path scoping rules: Scopes no longer affect the
  last point on a path. This was a nuiseance before and became
  a real problem with decorations.
- Finished my move from snakes to decorations. Also finished
  documentation. 
  We are now ready for a new release!
- Removed \externalcode command for decoration states as
  persistent pre/postcomputation stuff does a similar job.      
- Added \externalcode command for decoration states. Allows
  code to be executed outside the TeX-group the state code
  is executed in.
- Split decoration lib into several libs. 
- Renamed lineto decoration to curveto decoration.
- Renamed many keys of decorations and snakes to shorter
  names.
- Changed the tikz setting of decoration options.
- No documentation yet.
- Started merging snakes and decorations. Not yet finished.
- (Partly) rewrote the tikz support for decorations. There is
  now a "decorate" path command:
  \draw ... decorate [decoration=zigzag] { (0,0) -- (1,2) };
      This yields a much cleaner interface.
- There is also a decorate=true/false option that causes the
  whole path to be decorated.
- Decorated path can now contain nodes.
- Node paths can also be decorated now.
- Fixed missing \pgftransformreset inside decoration
  environment. 
- Changed the decoration documentation a bit. Still not quite
    perfect... 
- Restructured the basic layer. There is a central core (which
  got slightly larger) and "modules", which can be included
  using \usepgfmodule. All the pgfbaseXXX files are now
  obsolete and only included for the old ones for
  compatibility.
  The {pgf} package no longer includes the modules "pattern",
  "snakes" and "decorations" by default. However, these
  modules are loaded by their respective libraries, so,
  normally, no one will notice.    
- Fix for minimum size in ellipse split shape.
- Added decorations documentation.
- Coordinates like (2,3cm) are now allowed. Has the same
  effect as ([shift={(2,0)}]0pt,3cm), which is what everybody
  would expect.
- Moved tikz hacks inside tikzlibrarydecorations into
  tikz.code.tex itself.
- Fix for save stack overflow in decorations.
- Renamed \pgfdecorate \endpgfdecorate, now \pgfdecoration
  \endpgfdecoration. Makes it more consistent with...
- Meta decorations! Automata that decorate the path with
  decoration automata! Increased fancyness! Docs soon.
- Removed a bunch of keys from \tikzlibrarydecorations as
  not really necessary.
- Changed shadow lib once more and added it to CVS.
- Added decorations files. Docs to follow soon(ish).
- Fix for `star point ratio` and `star point height`
  keys in star shape.
- Added copy shadow.
- Added random steps snake.
- Added shadow library, removed shadow shapes (no longer
  needed).
- Added preaction and postaction options (very useful).
- Added transform canvas option.
- Added scale around option.
- Moved tikz.code.tex to tikz/tikz.code.tex
- Moved .../libraries/pgflibrarytikzXXXX.code.tex to
  .../frontendlayer/tikz/libraries/tikzlibraryXXXX.code.tex.
- Fixed missing example bbs for dvipdfm.
- Fixed buggy swirl shading.
- Finished documentation switch from \itemoption to {key}.
- Changed TikZ fading options. More consistent and easier to use,
  now. 
- Added `ellipse split` shape.
- Fixed spaces problem with external graphics.
- Added [missing] option to supress children.
- Reduced number of libs includes by {shapes} to geometric,
  misc and symbol. Shapes is now more or less deprecated.
- Added shadowed shapes.
- Added pgfsys-xetex for native xetex support.
- Added documentation hint on scoping inside \foreach.
- Fixed bug [1620194] "tikz library mindmap requires trees"
- Fixed bug [1787504] "Usage of \@namelet in xxcolor.sty clases with memoir."
- Fixed bug [1809693] "background rectangle is scaled".
- Added fadings.
- Added functional shadings.
- Fixed bug in double drawing with arrows.
- Fix for all math functions with two arguments.
- Fix for tikz when y-coordinate is a function within braces.
- Fix for distance calculation in shape snake.
- Added `cloud callout` shape.
- cloud shape can now use (or ignore) `aspect` key.
- More key updates/fixes for shapes.
- Corrected minimum size of a diamond shape (was twice the
  correct size -- this may break existing code, but that cannot
  be avoided!).
- Changed some more documentation from \itemoption to {key}s. Not
   yet finished.
- Updated math documentation. Code examples now consistent with
  the rest of the manual.
- Fixed hyperref-dvipdfm-problem.
- Updated cloud shape for minimum size calculations.
- Reimplemented rounded rectangle. Now supports concave arcs.
- Removed all stuff for Fancy hyperlinked picture of shapes.
- \foreach will now allow a macro name to be given as list
  argument (as in \foreach \x in \mylist {...})
- Fixed keys problem when .try is used with a comma.
- Fixed shape snake for drawing to other pictures.
- Added shapes `arrow box` shape, `rectangle callout` and 
  `ellipse callout`.
- Fixed dvipdfm problem with hyperref.
- pgfbasesnakes: changed length calculation and added angle calculation.
- added `shape snake` to snake library.
- added cylinder shape to geometric shapes.
- renamed `bevelled rectangle`. Now called `chamfered rectangle`.
- renamed pgfsavepgf@process. Now called pgfextract@process. 
- Fixed bug #1803811 gobbling of tokens after \pgfmathaddtocounter.
- Fixed insertion of spaces after \pgfmath stuff.
- Fixed bug #1811862.
- Fix for cot and tan. Now correctly return negative values.
- Added `...head indent` option for single and doube arrow
  shapes (allows the arrowheads to look more “fancy”).
- Updated tikzshapes.geometric and tikzshapes.symbols so
  the incircle border construction can be used in TikZ
  if libraries are loaded separately.
- Misc. fixes and updates for shapes doc.
- Fixed isosceles triangle, circular sector and circle split
  for `text width` key.
- Fixed star, cloud and rectangle shape for using anchors for
  positioning.
- New shapes:Rectangle split, rounded rectangle,
  bevelled rectangle, tape, signal, single arrow and double arrow.
- Fancy hyperlinked picture of all shapes added to shape lib. doc.
- Updated math doc.
- Fix for square root.
- Fix for parsing negative box dimensions.
- (Yet another) division version.
- Added cloud shape.
- Updated all shapes (and doc.) for pgfkeys.
- Changed Kite key: Now use (e.g.) '/pgf/kite vertex angles=60 and 70' (see doc.)
- Added keys /pgf/shape aspect and /pgf/shape aspect inverse, (but \pgfsetshapeaspect
  and, TikZ option `apsect` are still there for compatability).
- Updated diamond shape (and doc.) to use keys.
- “Housekeeping” stuff (moved some macros around).
- Trapezium shape updated. No longer uses left and right 
  extensions. Uses internal angles instead.
    - Updated pgfkeys for shapes (not done \pgfsetshapeaspect for
  diamond shape)
    - Added new starburst shape to misc shapes.
    - Updated all shapes to pgfkeys.
- Added fitting library.
    - Fixed parser for expressions beginning with groups
      preceeded by signs e.g. -(4+3)
    - This also fixes problem in TikZ when specifiying coordinates
      contatining groups. Coordinates in the form (1, {(2+3)}) will
      work even if there are spaces after the comma.
- Started to use new pgfkeys also in pgf. In particular,
  commands like \pgfsetshape... are now replaced by keys.
  (Not yet finished.)
- Added new geometric shape: `circular sector`.
- Updated pgfbaseshapes.code.tex for saved macro support.
- Added overlay functionality to \node.
- Added pgfkeys and its documentation.
- Updated all “new” geometric shapes: polygon, star, trapezium,
  semicircle, isosceles triangle, kite, dart.
- `isosceles triangle` and `simple isosceles triangle` combined
  into one shape.
- more accurate anchor positioning in polygon and star shapes.
- Added `shape border uses incircle` option for supporting shapes.
- Added `shape border rotate` option for supporting shapes.
- Added support for sec, cosec and cot.
- Fixed missing compatibility \pgfsincos
- Fixed wrong \pgfmathsincos
- Added semicircle shape.
- Updated documentation for all new shapes.
- Added support for savedmacros in \pgfdeclareshape.
- Added trapezium shape.
- Added support for “legacy” calc code (\real, \minof, \maxof, \ratio).
- Fixed 'public' sqrt macro in \pgfmathoperations.code.tex
- Added isosceles triangle shape: uses incircle, but supports arbitrary 
  rotation of border.
- Added simple isosceles triangle shape: much tighter fit of node 
  contents, but restricted rotation of border.
- Fixed text width problem in matrix of nodes.

### Contributors

- Mark Wibrow

## [1.18] - 2007-01-18 Till Tantau 

- Added regular polygon and star shapes (by Mark Wibrow).
- Added graphic externalization commands.
- Added barycentric coordinate system.
- Added direct TikZ plotting of function based on math engine.
- Added math documentation into main documentation.
- Added Mark Wibrow's math library. 
- Added calendar support.
- Added matrix stuff.
- Added automatic driver selection for xetex.
- Added "growth parent anchor" option.
- Fixed superfluous spaces in quick math parse code
- Fixed superfluous \newboxes in math and image code
- Fixed mth parser to recognize \wd\mybox. 
- Fixed wrong \pgfmathsetrandomseed
- Fixed wrong \pgfmathradians@
- Fixed problems with long mantissa and plain tex math code.
- Fixed things so that \setlength works in pictures, once
  more. 
- Fixed selectfont problem in pdfsys-dvipdfm.def
- Fixed problem with lost lastx/lasty in foreach in TikZ.
- Fixed snake+rectangle+transform problem.
- Fixed rectangle+rounded corner problem.
- Fixed postscrip eofill1 problem.
- Fixed amsmath/pgf clash because of wrong definition of \:
- Fixed size of hyperlinks inside nodes.
- Fixed ConTeXt problem in pgfbaseplot.
- Fixed .aux problems in plain and ConTeXt mode. Using .pgf as
  extension now.

## [1.10] - 2006-10-26 Till Tantau 

- Renamed \pgf@sys@pdf@mark to \pgfsyspdfmark.
- Fixed the ConTeXt support so that it is usable (which is wasn't).

## [1.09] - 2006-10-11 Till Tantau 

- Added \usepgflibrary and \usetikzlibrary to simplify adding
  new libraries.
- Added native ConTeXt support in the form of module
  wrappers.
- Added patterns.
- Added crosses snake.
- Added to and edge path operations.
- Added to path library. In particular, this gives decent
  curved paths. 
- Added tikz automata library.
- Added tikz er diagram library.
- Added tikz Petri net library.
- Added tikz mindmap library.
- Added access to nodes in other pictures (!).
- Added extended baseline setting.
- Added functionality to add new coordinate systems.
- Added polar xy coordinate system.
- Added diamond shape (!).
- Added plot mark phase, repeat and indices.
- Added text height and text depth options.
- Added label and pin options.
- Added automatic node placement (!). 
- Added pgfsys-dvi.def for pure dvi mode. Supports only
  black and white drawing (not documented and not really usable).
- Added 3d library (not documented and not really usable).
- Cleared up license chaos.
- Reorganized library documentation.
- Removed pgflibraryautomata, use pgflibrarytikzautomata instead.
- Fixed tree level option bug.
- Fixed missing options for coordinates.
- Fixed bug in TikZ parabola code.
- Fixed bug in TikZ snake cycle code.
- Fixed bug with empty list in pgffor
- Fixed bug in code for insertion of dvips header specials.
- Fixed bug in shading code (wrong bigpoint correction).
- Fixed bug #1472666.
- Fixed bug #1473255.
- Fixed bug #1526175.
- Fixed bug #1542512.
- Fixed bug in TikZ transformation code for nested pictures.
- Fixed patch #1443606.
- Fixed path #1526178.

## [1.01] - 2005-11-16 Till Tantau 

- Added textures support.
- Added text opacity option.
- Fixed bug in pgfbasesnakes.code.tex causing lot's of
  'missing = in nullfont' message in log file.
- Fixed bug that made plain tex mode unusable.
- Fixed missing pgfsys-vtex.def in FILES.
- Fixed wrong box placements in compatibility mode.
- Fixed SVG support to create legal xml.
- Moved documentation to doc/generic/pgf.

## [1.00] - 2005-10-23 Till Tantau 

- There have not been any real changes since 0.99.

## [0.99] - 2005-10-11 Till Tantau 

- Added vtex support (finally!).
- Added multi part mechanism to nodes.
- Added very simple pgflibraryautomata.
- Changed coordinate shape such that it now never produces a
  text label.
- Renamed \pgfshapebox to \pgfnodeparttextbox (made necessary
  by the node part mechanism).

## [0.98] - 2005-09-20 Till Tantau 

- Added transparency to PGF (quite nice...).
- Added foreach option to child path operation (also nice...).
- Fixed problem with \\ in centered text.
- Fixed problem with hyperlinks in nodes.
- Fixed wrong arrows in trees.

## [0.97] - 2005-09-08 Till Tantau 

- Reorganised directory structure of documentation.
- Added tree mechanism.
- Added snake mechanism.
- Added layer mechanism.
- Added new shapes: cross out, strike out, forbidden sign.
- Added some more documentation.
- Added "none" drawing and filling colors.
- Added pgflibrarytikzbackgrounds.
- Changed syntax of \pgfqbox.
- Changed syntax of several \pgfsys@xxxx commands.
- Added SVG support / a tex4ht backend. (Complicated text
    inside svg graphics is not supported well, but that's mainly
  a shortcoming of the svg specification.)

## 0.96 - 2005-07-06 Till Tantau 

This is a beta version. Version 1.00 will be the first stable
version of TikZ/pgf.

- Fixed spacing problem in dvips.
- Changed syntax of plot and plot marks.
- Changed syntax of ellipse and elliptical arc options.
- Fixed baseline bug in tikz.
- Fixed bug in pgfpages.
- Introduced "every xxxx" styles, got rid of shape actions option.
- Added "intersection of" syntax for coordinates.
- Started revising the documentation.
- Changed names of some pgfpages commands.
- Changed syntax of parabola command.
- Proof read documentation.

## 0.95 - 2005-06-12 Till Tantau 

This is an *alpha* prerelease version. Syntax changes
are still possible before the beta version. Version 1.00
will be the stable version.

### Changed (this is almost a new program):

- Introduced three layers: system, basic, frontends.
- Wrote two frontends: TikZ (*most* useful!) and pgfpict2e (a
  demonstration).
- Largely rewrote the basic layer.
- Largely rewrote the system layer.
- Completely rewrote the documentation.
- Added two utilities: pgfpages and pgffor.
- Made macro naming more consistent.
- Added plain tex support.
- Added dvipdfm support.
- Restructured directory structure.
- Zillions of small bugfixes.

## 0.65 - 2004-10-20 Till Tantau 

- Fixed bug in pgfshade.sty that arises in conjunction with
  calc.sty and latex+dvips.

## 0.64 - 2004-10-08 Till Tantau 

- Fixed missing depth of \pgfnodebox.
- Fixed bug that caused infinite stack loop with pictures inside
  nodes. 

## 0.63 - 2004-07-08 Till Tantau 

- Added \pgfextractx, \pgfextracty, \pgfcorner.
- Added some documentation on masks and images.
- Fixed a somewhat obscure bug having to do with the modification
  of \spaceskip.
- \pgfex and \pgfem no loner needed. Use 1ex etc. once more.
- calc.sty is now supported.

## 0.62 - 2004-07-06 Till Tantau 

- Fixed problem in xxcolor with option "gray" and xcolor.
- Switched to xcolor version 2.00.
- Added eofill and eofillstroke commands.
- Added option to shadings, so that they are automatically
  recalculated upon color changes.
- Changed names of example images to start with pgf.

## 0.61 - 2004-04-07 Till Tantau 

- Added \pgfex and \pgfem dimensions.
- Fixed bug that causes pgfshade to fail to work if xcolor 
  is called with option "gray".
- Fixed PostScript code for radial shadings.
- xxcolor now works with xcolor 1.10 (and only 1.10).

## 0.60 - 2004-02-18 Till Tantau 

- Replaced some commands for the postscript code by shorter
  versions for smaller file size.
- Fixed bug in pgfbox command that caused incorrect kerning in
  postscript output.
- Fixed bug in pgfsys@defineimage that made page inclusion
  impossible. 
- Fixed bug in pgfshading that did not reset dash patterns in
  shadings in the PostScript version. 
- Spaces are now allowed inside the pgfpicture environment.
- Added \pgfgrid command.

## 0.50 - 2004-01-13 Till Tantau 

- Switched to version 1.06 of xcolor.
- Core pgf no longer relies on xxcolor.
- The syntax of the mechanism for choosing alternate images and
  shadings is more flexible now. The syntax has been changed
  (mainly, you now have to have a dot between the original name and
  the alternate extension).
- Some xxcolor commands have been removed.

## 0.43 - 2003-12-02 Till Tantau 

- Fixed \normalcolor, so that it works also in preamble.

## 0.42 - 2003-11-20 Till Tantau 

- Documented masks.
- Fixed bug in pgf.sty for nested pictures.

## 0.41 - 2003-11-18 Till Tantau 

- Added masks (not yet documented).

## 0.40 - 2003-11-12 Till Tantau 

- Changed syntax of \pgfdeclareimage. Uses key=value scheme
  now. All parameters may now be omitted. 
- Added \pgfimage command.
- Option for selecting a specific page from an image file.
- Fixed bug in xxcolor.sty having to do with \@ifempty command.
- Reworked the formatting of the user's guide.

## 0.34 - 2003-10-29 Till Tantau 

- Shadings now work together with color mix-ins.
- Shadings can now take color names as parameters.

## 0.33 - 2003-10-24 Till Tantau 

- Fixed problem with missing \leavevmode in \pgfuseimage.
- Reworked code for image inclusion. 
- "Draft" option is now supported. Supresses reading of images. 
- Added xxcolor package.
- pgfpictures will now inherit the color from their surroundings.

## 0.32 - 2003-10-20 Till Tantau 

- Updated installation procedure information.

## 0.31 - 2003-09-18 Till Tantau 

- One parameter for \pgfdeclareimage may now be omitted. It will
  be computed automatically.
    
## 0.30 - 2003-08-21 Till Tantau 

- Created ChangeLog
- Added pgfshade.sty

[3.1.10]: https://github.com/pgf-tikz/pgf/compare/3.1.9a...3.1.10
[3.1.9a]: https://github.com/pgf-tikz/pgf/compare/3.1.9...3.1.9a
[3.1.9]: https://github.com/pgf-tikz/pgf/compare/3.1.8b...3.1.9
[3.1.8b]: https://github.com/pgf-tikz/pgf/compare/3.1.8a...3.1.8b
[3.1.8a]: https://github.com/pgf-tikz/pgf/compare/3.1.8...3.1.8a
[3.1.8]: https://github.com/pgf-tikz/pgf/compare/3.1.7a...3.1.8
[3.1.7a]: https://github.com/pgf-tikz/pgf/compare/3.1.7...3.1.7a
[3.1.7]: https://github.com/pgf-tikz/pgf/compare/3.1.6a...3.1.7
[3.1.6a]: https://github.com/pgf-tikz/pgf/compare/3.1.6...3.1.6a
[3.1.6]: https://github.com/pgf-tikz/pgf/compare/3.1.5b...3.1.6
[3.1.5b]: https://github.com/pgf-tikz/pgf/compare/3.1.5a...3.1.5b
[3.1.5a]: https://github.com/pgf-tikz/pgf/compare/3.1.5...3.1.5a
[3.1.5]: https://github.com/pgf-tikz/pgf/compare/3.1.4b...3.1.5
[3.1.4b]: https://github.com/pgf-tikz/pgf/compare/3.1.4a...3.1.4b
[3.1.4a]: https://github.com/pgf-tikz/pgf/compare/3.1.4...3.1.4a
[3.1.4]: https://github.com/pgf-tikz/pgf/compare/3.1.3...3.1.4
[3.1.3]: https://github.com/pgf-tikz/pgf/compare/3.1.2...3.1.3
[3.1.2]: https://github.com/pgf-tikz/pgf/compare/3.1.1...3.1.2
[3.1.1]: https://github.com/pgf-tikz/pgf/compare/3.1...3.1.1
[3.1]: https://github.com/pgf-tikz/pgf/compare/3.0.1...3.1
[3.0.1]: https://github.com/pgf-tikz/pgf/compare/version-3-0-0...3.0.1
[3.0.0]: https://github.com/pgf-tikz/pgf/compare/2.10...version-3-0-0
[2.10]: https://github.com/pgf-tikz/pgf/compare/version-2-00...2.10
[2.00]: https://github.com/pgf-tikz/pgf/compare/version-1-18...version-2-00
[1.18]: https://github.com/pgf-tikz/pgf/compare/version-1-10...version-1-18
[1.10]: https://github.com/pgf-tikz/pgf/compare/version-1-09...version-1-10
[1.09]: https://github.com/pgf-tikz/pgf/compare/version-1-01...version-1-09
[1.01]: https://github.com/pgf-tikz/pgf/compare/version-1-00...version-1-01
[1.00]: https://github.com/pgf-tikz/pgf/compare/version-0-99...version-1-00
[0.99]: https://github.com/pgf-tikz/pgf/compare/version-0-98...version-0-99
[0.98]: https://github.com/pgf-tikz/pgf/compare/tag-version-0-97...version-0-98
[0.97]: https://github.com/pgf-tikz/pgf/releases/tag/tag-version-0-97
