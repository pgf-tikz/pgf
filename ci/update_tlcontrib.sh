#!/bin/sh

set -e


if [ "${TRAVIS_PULL_REQUEST}" != "false" ]; then
    echo "INFO: This is a PR.";
    echo "INFO: Not deploying repo.";
    exit 0;
fi;


if [ "${TRAVIS_BRANCH}" != "master" ]; then
    echo "INFO: We are not on the master branch.";
    echo "INFO: Not deploying repo.";
    exit 0;
fi;


if [ -z "${GH_TOKEN}" ]; then
    echo "INFO: The GitHub access token is not set.";
    echo "INFO: Not deploying repo.";
    exit 0;
fi;


# Prepare sources for tlpkg
mkdir -p texmf-dist/web2c
for dir in doc source tex; do
    git mv ${dir} texmf-dist
done
touch texmf-dist/doc/generic/pgf/pgfmanual.pdf # In case you forgot to move it
git add texmf-dist/doc/generic/pgf/pgfmanual.pdf
git add texmf-dist/tex/generic/pgf/pgf.revision.tex # This file HAS to exist!
git commit --no-gpg-sign --quiet -m "Move files"

# Prepare tlpkg
mkdir -p tlpkg/tlpsrc
rsync -avzP --delete --exclude=.svn tug.org::tldevsrc/Master/tlpkg/tlpsrc/00texlive.*.tlpsrc tlpkg/tlpsrc/
rsync -avzP --delete --exclude=.svn tug.org::tldevsrc/Master/tlpkg/tlpsrc/pgf.tlpsrc tlpkg/tlpsrc/
rsync -avzP --delete --exclude=.svn tug.org::tldevsrc/Master/tlpkg/bin/ tlpkg/bin/
rsync -avzP --delete --exclude=.svn tug.org::tldevsrc/Master/tlpkg/installer/ tlpkg/installer/
rsync -avzP --delete --exclude=.svn tug.org::tldevsrc/Master/tlpkg/TeXLive/ tlpkg/TeXLive/

# Target directory
rm -rf tlnet/
mkdir -p tlnet/

# Build
perl tlpkg/bin/tl-update-tlpdb -from-git -master "${PWD}"
perl tlpkg/bin/tl-update-containers -master "${PWD}" -location "${PWD}/tlnet" -all -recreate -no-sign

# Reset git to previous state
git reset --hard HEAD~1

# Deploy the tree
cd tlnet/
touch .nojekyll
git init
git checkout -b gh-pages
git add .
git commit --no-gpg-sign --quiet -m "Deployment for ${TRAVIS_COMMIT}"
git remote add origin https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG};
git push --quiet --force origin gh-pages > /dev/null 2>&1
