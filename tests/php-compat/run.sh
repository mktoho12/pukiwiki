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
rm -rf "$OUT"; mkdir -p "$OUT"
# The containers get the files as tar files (see render.sh).
# Archive the trees, not the commits: the old tar does not know the
# pax global header that holds the commit id.
git -C "$TOP" archive -o "$OUT/src-base.tar"   "$BASE^{tree}"
git -C "$TOP" archive -o "$OUT/src-target.tar" "$TARGET^{tree}"
(cd pages && COPYFILE_DISABLE=1 tar --format=ustar -cf "$OUT/pages.tar" *.txt)

status=0
for v in $VERSIONS; do
	case $v in
	# The old Debian images are for x86 only (emulated on arm64 hosts)
	412) img=pukiwiki-php-compat:php$v; platform="--platform linux/386" ;;
	4*)  img=pukiwiki-php-compat:php$v; platform="--platform linux/amd64" ;;
	*)   img=php:`echo $v | sed 's/^\(.\)/\1./'`-cli; platform="" ;;
	esac
	case $v in
	4*)
	    if ! docker image inspect $img > /dev/null 2>&1; then
	        echo "Building $img (first time only; see $OUT/build-php$v.log)"
	        docker build $platform -t $img -f docker/php$v.Dockerfile docker \
	            > "$OUT/build-php$v.log" 2>&1 || { tail -30 "$OUT/build-php$v.log"; exit 1; }
	    fi ;;
	esac
	for side in base target; do
		docker run --rm $platform -u `id -u`:`id -g` --tmpfs /tmp:rw,size=512m \
			-v "$OUT:/out" -v "$HERE:/test:ro" $img \
			sh /test/render.sh /out/src-$side.tar /out/$v-$side /out/pages.tar
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
