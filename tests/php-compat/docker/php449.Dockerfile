# PHP 4.4.9 (CGI) built from source on Debian 4.0 "etch"
FROM debian/eol:etch
RUN echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99unauth \
 && apt-get update -q && apt-get install -y -q --force-yes build-essential flex bison
ADD https://museum.php.net/php4/php-4.4.9.tar.gz /tmp/
RUN cd /tmp && tar xzf php-4.4.9.tar.gz && cd php-4.4.9 \
 && ./configure --prefix=/opt/php449 --enable-mbstring --without-mysql \
 && make -j4 && make install \
 && ln -s /opt/php449/bin/php /usr/local/bin/php-cgi \
 && cd / && rm -rf /tmp/php-4.4.9*
