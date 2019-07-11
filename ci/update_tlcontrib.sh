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


if [ -z "$(git ls-remote --heads https://github.com/${TRAVIS_REPO_SLUG} gh-pages)" ]; then
    echo "INFO: The branch gh-pages does not exist.";
    echo "INFO: Not building docs.";
    exit 0;
fi;


if ! git diff --quiet HEAD -- && [ "$1" != "-f" ]; then
    echo "Your working tree is not clean!"
    echo "Please commit your changes before continuing or use the -f option."
    exit 1
fi

CURRENT_DIRECTORY="${PWD}"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
function cleanup {
    echo "Cleaning up changes"
    cd "${CURRENT_DIRECTORY}"
    git reset --hard "${CURRENT_BRANCH}"
    git checkout "${CURRENT_BRANCH}"
}
trap cleanup EXIT

# Switch to a new branch
git checkout -f -B tlcontrib

# Prepare sources for tlpkg
mkdir -p texmf-dist/web2c
for dir in doc source tex; do
    git mv ${dir} texmf-dist
done
touch texmf-dist/doc/generic/pgf/pgfmanual.pdf # In case you forgot to move it
git add texmf-dist/doc/generic/pgf/pgfmanual.pdf
git add texmf-dist/tex/generic/pgf/pgf.revision.tex # This file HAS to exist!
git commit --no-gpg-sign --quiet --amend --no-edit

# Prepare tlpkg
mkdir -p /tmp/tlpkg/tlpsrc
rsync -avzP --delete --exclude=.svn tug.org::tldevsrc/Master/tlpkg/tlpsrc/00texlive.autopatterns.tlpsrc \
                                           ::tldevsrc/Master/tlpkg/tlpsrc/00texlive.config.tlpsrc \
                                           ::tldevsrc/Master/tlpkg/tlpsrc/00texlive.installation.tlpsrc \
                                           ::tldevsrc/Master/tlpkg/tlpsrc/pgf.tlpsrc \
                                           /tmp/tlpkg/tlpsrc/
rsync -avzP --delete --exclude=.svn tug.org::tldevsrc/Master/tlpkg/bin \
                                           ::tldevsrc/Master/tlpkg/installer \
                                           ::tldevsrc/Master/tlpkg/TeXLive \
                                           /tmp/tlpkg/

# Copy tlpsrc
mkdir -p tlpkg
cp -r /tmp/tlpkg/tlpsrc tlpkg/

# Target directory
rm -rf tlcontrib/
mkdir -p tlcontrib/tlnet/

# Build
perl /tmp/tlpkg/bin/tl-update-tlpdb -from-git -master "${PWD}"
perl /tmp/tlpkg/bin/tl-update-containers -master "${PWD}" -location "${PWD}/tlcontrib/tlnet" -all -recreate -no-sign

# Deploy the tree
cp texmf-dist/doc/generic/pgf/pgfmanual.pdf tlcontrib/
cd tlcontrib/
touch .nojekyll
git init
git checkout -b gh-pages
git add .
git commit --no-gpg-sign --quiet -m "Deployment for ${TRAVIS_COMMIT}"
git remote add origin https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG};
git push --quiet --force origin gh-pages > /dev/null 2>&1
