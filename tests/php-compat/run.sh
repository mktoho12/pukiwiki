#!/bin/sh
# Usage: tests/php-compat/run.sh <base-rev> <target-rev> [version ...]
#
# Renders the wiki pages (wiki/ and tests/php-compat/pages/) of two git
# revisions with each PHP version, and compares the HTML.
# Versions: 412 444 449 (PHP 4, built from docker/*.Dockerfile on first use)
#           56 70 71 72 73 74 80 81 82 83 84 85 (official php:X.Y-cli images)
# Results: tests/php-compat/out/ (the HTML and errors.log of each run)
#
# Example: tests/php-compat/run.sh r1_5_4 HEAD 412 449 85
set -e
[ $# -ge 2 ] || { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
cd "`dirname "$0"`"
HERE=`pwd`
TOP=`git rev-parse --show-toplevel`
BASE=$1; TARGET=$2; shift 2
VERSIONS=${*:-"412 444 449 56 70 74 82 83 84 85"}
OUT=$HERE/out
rm -rf "$OUT"; mkdir -p "$OUT/src-base" "$OUT/src-target"
git -C "$TOP" archive "$BASE"   | tar -x -C "$OUT/src-base"
git -C "$TOP" archive "$TARGET" | tar -x -C "$OUT/src-target"

status=0
for v in $VERSIONS; do
	case $v in
	# The old Debian images are for amd64 only (emulated on arm64 hosts)
	4*) img=pukiwiki-php-compat:php$v; platform="--platform linux/amd64"
	    docker image inspect $img > /dev/null 2>&1 ||
	        docker build -q $platform -t $img -f docker/php$v.Dockerfile docker > /dev/null ;;
	*)  img=php:`echo $v | sed 's/^\(.\)/\1./'`-cli; platform="" ;;
	esac
	for side in base target; do
		docker run --rm $platform -u `id -u`:`id -g` -v "$OUT:/out" -v "$HERE:/test:ro" $img \
			sh /test/render.sh /out/src-$side /out/$v-$side /test/pages
	done
	pages=`ls "$OUT/$v-target"/*.html | wc -l`
	# Pages that did not finish (fatal error, crash, or not run at all)
	ub=`grep -L -e '</html>' -e '</rss>' -e '</rdf:RDF>' "$OUT/$v-base"/*.html | wc -l`
	ut=`grep -L -e '</html>' -e '</rss>' -e '</rdf:RDF>' "$OUT/$v-target"/*.html | wc -l`
	diffs=`diff -r -x errors.log -x stderr.log "$OUT/$v-base" "$OUT/$v-target" | grep -c '^[<>]' || true`
	eb=`cat "$OUT/$v-base/errors.log" 2>/dev/null | wc -l`
	et=`cat "$OUT/$v-target/errors.log" 2>/dev/null | wc -l`
	echo "PHP $v ($img): $pages pages, differing lines: $diffs, unfinished pages: $ub -> $ut, errors: $eb -> $et"
	[ "$diffs" -eq 0 ] && [ "$ut" -le "$ub" ] || status=1
done
exit $status
