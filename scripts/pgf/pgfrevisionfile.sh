#!/bin/bash
# it generates generic/pgf/pgf.revision.tex which, in turn, will be loaded
# by pgf.sty
#
# The resulting macros define the current version of pgf.

LATEST_TAG=`git describe --abbrev=0 --tags`
REVISION=`git describe --tags HEAD`


rm -f generic/pgf/pgf.revision.tex
echo '\begingroup' >> generic/pgf/pgf.revision.tex
echo '\catcode`\-=12' >> generic/pgf/pgf.revision.tex
echo '\catcode`\/=12' >> generic/pgf/pgf.revision.tex
echo '\catcode`\.=12' >> generic/pgf/pgf.revision.tex
echo '\catcode`\:=12' >> generic/pgf/pgf.revision.tex
echo '\catcode`\+=12' >> generic/pgf/pgf.revision.tex
echo '\catcode`\-=12' >> generic/pgf/pgf.revision.tex

# this is the REVISION, i.e. the unique hash of the changeset.
echo '\gdef\pgfrevision{'"$REVISION}" >> generic/pgf/pgf.revision.tex

# this is the public version name. It corresponds to the latest tag name in the git repo.
echo '\gdef\pgfversion{'"$LATEST_TAG}" >> generic/pgf/pgf.revision.tex

# this is the commit date of the latest tag, i.e. the date when \pgfversion has been committed.
# It is NOT the date of \pgfrevision.
echo -n '\gdef\pgfversiondatetime{' >> generic/pgf/pgf.revision.tex
git log -n 1 "$LATEST_TAG" --pretty=format:"%ci" >> generic/pgf/pgf.revision.tex
echo '}' >>  generic/pgf/pgf.revision.tex

echo -n '\gdef\pgfrevisiondatetime{' >> generic/pgf/pgf.revision.tex
git log -n 1 "$REVISION" --pretty=format:"%ci" >> generic/pgf/pgf.revision.tex
echo '}' >>  generic/pgf/pgf.revision.tex

# convert to latex format YYYY/MM/DD :
echo '\gdef\pgf@glob@TMPa#1-#2-#3 #4\relax{#1/#2/#3}' >>  generic/pgf/pgf.revision.tex
echo '\xdef\pgfversiondate{\expandafter\pgf@glob@TMPa\pgfversiondatetime\relax}' >>  generic/pgf/pgf.revision.tex
echo '\xdef\pgfrevisiondate{\expandafter\pgf@glob@TMPa\pgfrevisiondatetime\relax}' >>  generic/pgf/pgf.revision.tex
echo '\endgroup' >> generic/pgf/pgf.revision.tex
exit 0
