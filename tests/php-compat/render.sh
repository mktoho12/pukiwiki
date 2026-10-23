#!/bin/sh
# Runs inside a container: render.sh <src.tar> <out-dir> <pages.tar>
# Unpacks a PukiWiki tree and the test pages into /tmp, renders every page
# and some commands with php-cgi, and logs all errors (E_ALL) to errors.log.
#
# Written for old tools (Debian woody: no "sed -i", no "find -exec +").
# All the work is done in /tmp (tmpfs): when an old 32-bit program is
# emulated on arm64 hosts, it cannot list a directory on other file systems
# ("Value too large for defined data type"). So this script never lists
# <out-dir>; it only copies the results there.
SRC_TAR=$1; OUT=$2; PAGES_TAR=$3
CGI=/usr/local/bin/php-cgi
RUN=/tmp/run; WORK=/tmp/out
rm -rf $RUN $WORK; mkdir $RUN $WORK; cd $RUN
tar -xf $SRC_TAR
(cd wiki && tar -xf $PAGES_TAR)
sed 's/^error_reporting(E_ERROR | E_PARSE);/error_reporting(E_ALL);/' index.php > index.tmp && mv index.tmp index.php
mkdir phpini
printf "display_errors=0\nlog_errors=1\nerror_log=$WORK/errors.log\nerror_reporting=2047\nmemory_limit=256M\ndate.timezone=UTC\n" > phpini/php.ini
chmod -R a+w wiki cache counter diff backup attach 2>/dev/null
find . -type f -exec touch -d '2020-01-01 00:00:00' {} \;
req() { # $1 = query string, $2 = output name
	env -i REDIRECT_STATUS=200 GATEWAY_INTERFACE=CGI/1.1 REQUEST_METHOD=GET \
		QUERY_STRING="$1" SCRIPT_FILENAME=$RUN/index.php SCRIPT_NAME=/index.php \
		PATH_TRANSLATED=$RUN/index.php \
		REQUEST_URI="/index.php?$1" SERVER_NAME=localhost SERVER_PORT=80 \
		SERVER_PROTOCOL=HTTP/1.0 REMOTE_ADDR=127.0.0.1 HTTP_USER_AGENT=Mozilla/5.0 \
		HTTP_ACCEPT_LANGUAGE=ja PHPRC=$RUN/phpini \
		$CGI > "$WORK/$2.html" 2>> $WORK/stderr.log
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
for f in $WORK/*.html; do
	sed -e 's/[0-9][0-9]*\.[0-9][0-9]* sec/N sec/g' \
	    -e 's/data-mtime="[^"]*"/data-mtime=""/g' $f > $f.tmp && mv $f.tmp $f
done
mkdir -p $OUT
cp $WORK/* $OUT/
rm -rf $RUN $WORK
