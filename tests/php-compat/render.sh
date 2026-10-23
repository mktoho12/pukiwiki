#!/bin/sh
# Runs inside a container: render.sh <src-dir> <out-dir> <pages-dir>
# Copies a PukiWiki tree, adds the test pages, and renders every page and
# some commands with php-cgi, logging all errors (E_ALL) to <out-dir>/errors.log.
# Written for old tools too (Debian woody: no "sed -i", no "find -exec +").
SRC=$1; OUT=$2; PAGES=$3
CGI=/usr/local/bin/php-cgi
RUN=/tmp/run.$$
rm -rf $RUN $OUT; mkdir -p $OUT; cp -R $SRC $RUN; cd $RUN
cp $PAGES/*.txt wiki/
sed 's/^error_reporting(E_ERROR | E_PARSE);/error_reporting(E_ALL);/' index.php > index.tmp && mv index.tmp index.php
mkdir phpini
printf "display_errors=0\nlog_errors=1\nerror_log=$OUT/errors.log\nerror_reporting=2047\nmemory_limit=256M\ndate.timezone=UTC\n" > phpini/php.ini
chmod -R a+w wiki cache counter diff backup attach 2>/dev/null
find . -type f -exec touch -d '2020-01-01 00:00:00' {} \;
req() { # $1 = query string, $2 = output name
	env -i REDIRECT_STATUS=200 GATEWAY_INTERFACE=CGI/1.1 REQUEST_METHOD=GET \
		QUERY_STRING="$1" SCRIPT_FILENAME=$RUN/index.php SCRIPT_NAME=/index.php \
		PATH_TRANSLATED=$RUN/index.php \
		REQUEST_URI="/index.php?$1" SERVER_NAME=localhost SERVER_PORT=80 \
		SERVER_PROTOCOL=HTTP/1.0 REMOTE_ADDR=127.0.0.1 HTTP_USER_AGENT=Mozilla/5.0 \
		HTTP_ACCEPT_LANGUAGE=ja PHPRC=$RUN/phpini \
		$CGI > "$OUT/$2.html" 2>> $OUT/stderr.log
}
for f in wiki/*.txt; do
	hex=`basename $f .txt`
	req "`echo $hex | sed 's/\(..\)/%\1/g'`" "page-$hex"
done
req "cmd=list" cmd-list
req "cmd=filelist" cmd-filelist
req "cmd=search&word=PukiWiki&type=AND" cmd-search
req "cmd=rss" cmd-rss
req "cmd=edit&page=FormattingRules" cmd-edit
req "cmd=diff&page=FormattingRules" cmd-diff
req "cmd=backup&page=FormattingRules" cmd-backup
req "cmd=related&page=FrontPage" cmd-related
req "cmd=source&page=FormattingRules" cmd-source
# Remove what changes on every run (RecentChanges is written while rendering)
for f in $OUT/*.html; do
	sed -e 's/[0-9][0-9]*\.[0-9][0-9]* sec/N sec/g' \
	    -e 's/data-mtime="[^"]*"/data-mtime=""/g' $f > $f.tmp && mv $f.tmp $f
done
rm -rf $RUN
