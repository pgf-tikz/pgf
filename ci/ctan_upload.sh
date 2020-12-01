#!/usr/bin/env bash

die() {
	>&2 echo "$@"
	exit 1
}

[[ -n ${GIT_TAG+x} ]] || die "The GIT_TAG variable is unset"

case "$1" in
	validate|upload) ;;
	*) die "Unsupported action: $1" ;;
esac

CTAN_NOTES=$(mktemp)
cat > "$CTAN_NOTES" <<EOF
The release files are signed using a detached signature.  You can obtain the
signature from the GitHub release page

    https://github.com/pgf-tikz/pgf/releases/download/${GIT_TAG}/pgf_${GIT_TAG}.ctan.flatdir.zip.sig
EOF

curl \
	-F "update=true" \
	-F "pkg=pgf" \
	-F "version=${GIT_TAG}" \
	-F "author=Christian Feuersänger" \
	-F "author=Henri Menke" \
	-F "author=The PGF/TikZ Team" \
	-F "author=Till Tantau" \
	-F "uploader=github-actions" \
	-F "email=pgf-tikz@tug.org" \
	-F "summary=Create PostScript and PDF graphics in TeX" \
	-F "description=<doc/generic/pgf/description.html" \
	-F "ctanPath=/graphics/pgf/base" \
	-F "announcement=<doc/generic/pgf/RELEASE_NOTES.md" \
	-F "note=<$CTAN_NOTES" \
	-F "license=fdl" \
	-F "license=gpl2" \
	-F "license=lppl1.3c" \
	-F "file=@pgf_${GIT_TAG}.ctan.flatdir.zip" \
	-F "bugs=https://github.com/pgf-tikz/pgf/issues" \
	-F "support=https://tug.org/mailman/listinfo/pgf-tikz" \
	-F "repository=https://github.com/pgf-tikz/pgf" \
	"https://www.ctan.org/submit/$1"
