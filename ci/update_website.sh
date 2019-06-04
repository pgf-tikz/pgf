#!/bin/sh

set -e;


if [ "${TRAVIS_PULL_REQUEST}" != "false" ]; then
    echo "INFO: This is a PR.";
    echo "INFO: Not deploying docs.";
    exit 0;
fi;


if [ "${TRAVIS_BRANCH}" != "master" ]; then
    echo "INFO: We are not on the master branch.";
    echo "INFO: Not deploying docs.";
    exit 0;
fi;


if [ -z "${GH_TOKEN}" ]; then
    echo "INFO: The GitHub access token is not set.";
    echo "INFO: Not deploying docs.";
    exit 0;
fi;


if [ "${TRAVIS_REPO_SLUG}" != "pgf-tikz/pgf" ]; then
    echo "INFO: No access to upstream GitHub pages.";
    echo "INFO: Not deploying docs.";
    exit 0;
fi;

touch .nojekyll;
cp pgfmanual.html index.html

git init;
git remote add origin https://github.com/pgf-tikz/pgf-tikz.github.io.git;

git add .nojekyll index.html *.svg;

git commit --quiet -m "Documentation build from Travis for commit ${TRAVIS_COMMIT}";

git remote add upstream https://${GH_TOKEN}@github.com/pgf-tikz/pgf-tikz.github.io.git;
git push --quiet --force upstream master > /dev/null 2>&1;
