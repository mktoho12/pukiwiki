# PHP 4.1.2 (CGI) from Debian 3.0 "woody" (i386 only)
FROM debian/eol:woody
# When emulated on arm64 hosts, the old 32-bit programs cannot list a
# directory ("Value too large for defined data type"), and dpkg stops.
# So download the packages and unpack them without dpkg and without globs.
RUN apt-get update -q \
 && apt-get install -y -q --print-uris php4-cgi | grep "^'" | cut -d' ' -f2 > /tmp/debs \
 && apt-get install -y -q -d php4-cgi \
 && for f in `cat /tmp/debs`; do dpkg-deb -x /var/cache/apt/archives/$f / || exit 1; done \
 && ln -s /usr/lib/cgi-bin/php4 /usr/local/bin/php-cgi \
 && test -x /usr/local/bin/php-cgi
