# PHP 4.1.2 (CGI) from Debian 3.0 "woody"
FROM debian/eol:woody
RUN apt-get update -q && apt-get install -y -q php4-cgi \
 && ln -s /usr/lib/cgi-bin/php4 /usr/local/bin/php-cgi
