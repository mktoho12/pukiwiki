# PHP 4.4.4 (CGI) from Debian 4.0 "etch"
FROM debian/eol:etch
RUN echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99unauth \
 && apt-get update -q && apt-get install -y -q --force-yes php4-cgi \
 && ln -s /usr/bin/php4-cgi /usr/local/bin/php-cgi
