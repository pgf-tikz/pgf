#!/usr/bin/env bash

set -euo pipefail

die() {
	>&2 echo "$@"
	exit 1
}

[[ -n ${1+x} ]] || die "No tag specified"

# Check if the working tree is clean
cd "$(git rev-parse --show-toplevel)"
if ! git diff --quiet HEAD --; then
    echo "Your working tree is not clean!"
    echo "Please commit your changes before continuing."
    exit 1
fi

echo "Updating changelog"
TMPFILE=$(mktemp)
cat  >> $TMPFILE << EOF
$(date -I) $(git config user.name)

    - Release $1

EOF
GIT_TAG=$(git describe --abbrev=0 --tags)
git log --date=short --pretty=format:'%ad %an%n%n    - %s%n' $GIT_TAG.. >> $TMPFILE
echo >> $TMPFILE
cat doc/generic/pgf/ChangeLog >> $TMPFILE
mv $TMPFILE doc/generic/pgf/ChangeLog

echo "Updating release notes"
echo -n "Launch ${EDITOR:-vim} doc/generic/pgf/RELEASE_NOTES.md? [ENTER]"
read
${EDITOR:-vim} doc/generic/pgf/RELEASE_NOTES.md

# Tagging release
echo -n "I'm about to tag release '$1'. Continue? [ENTER]"
read

git add doc/generic/pgf/ChangeLog
git add doc/generic/pgf/RELEASE_NOTES.md
git commit -m "Release $1"
git tag "$1"
