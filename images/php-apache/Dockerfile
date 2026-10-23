# =============================================================================
# Image de base Apache httpd + PHP pour Alpine Linux.
# Utilisée par le site PHP et Azuriom.
#
# PHP n'est volontairement pas épinglé à une version majeure : les paquets
# virtuels `php`, `php-apache2` et `php-*` sont résolus par apk vers la version
# par défaut du dépôt Alpine (actuellement PHP 8.5). Pour figer une version,
# remplacer ces noms par les paquets versionnés (`php85-*`) et taguer l'image
# en conséquence.
#
# Docs : https://wiki.alpinelinux.org/wiki/Apache_HTTP_Server
#        https://www.php.net/manual/fr/install.unix.apache2.php
# =============================================================================
FROM alpine:3.24

RUN set -eu; \
    apk add --no-cache \
        apache2 \
        php \
        php-apache2 \
        php-bcmath \
        php-ctype \
        php-curl \
        php-dom \
        php-fileinfo \
        php-gd \
        php-iconv \
        php-intl \
        php-mbstring \
        php-mysqli \
        php-openssl \
        php-pdo \
        php-pdo_mysql \
        php-pdo_pgsql \
        php-phar \
        php-session \
        php-simplexml \
        php-sodium \
        php-tokenizer \
        php-xml \
        php-xmlwriter \
        php-zip \
        curl \
        unzip \
        tzdata \
    && PHP_DIR=$(ls -d /etc/php[0-9]* | sort | tail -n1) \
    && if [ ! -d /etc/php ]; then ln -sfn "$PHP_DIR" /etc/php; fi \
    && if [ ! -e /usr/bin/php ]; then \
           PHP_BIN=$(ls /usr/bin/php[0-9]* 2>/dev/null | grep -E '/php[0-9]+$' | sort | tail -n1); \
           ln -sf "$PHP_BIN" /usr/bin/php; \
       fi \
    && sed -i 's/^#LoadModule rewrite_module/LoadModule rewrite_module/' /etc/apache2/httpd.conf \
    && sed -i 's/^#LoadModule expires_module/LoadModule expires_module/' /etc/apache2/httpd.conf \
    && sed -i 's/^#LoadModule remoteip_module/LoadModule remoteip_module/' /etc/apache2/httpd.conf \
    && mkdir -p /var/www/html /etc/php/conf.d \
    && chown -R apache:apache /var/www/html

COPY apache/altherneum.conf /etc/apache2/conf.d/000-altherneum.conf
COPY php/99-altherneum.ini /usr/local/share/php/99-altherneum.ini
COPY entrypoint.sh /usr/local/bin/php-apache-entrypoint

RUN cp /usr/local/share/php/99-altherneum.ini /etc/php/conf.d/99-altherneum.ini \
    && chmod 0644 /etc/php/conf.d/99-altherneum.ini \
    && chmod +x /usr/local/bin/php-apache-entrypoint

WORKDIR /var/www/html
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/php-apache-entrypoint"]
CMD ["httpd", "-DFOREGROUND"]
