# =============================================================================
# Site PHP + MariaDB.
# Base commune : images/php-apache (Alpine + Apache + PHP par défaut Alpine).
# Le code du site est cloné dans ./src (voir make php-site-src) et monté
# dans /var/www/html. La racine web est ./src/public.
# =============================================================================
FROM altherneum/php-apache:latest

COPY apache.conf /etc/apache2/conf.d/10-php-site.conf
COPY entrypoint.sh /usr/local/bin/php-site-entrypoint
COPY db-ready.php /usr/local/bin/php-site-db-ready
COPY init-db.php /usr/local/bin/php-site-init-db

RUN chmod +x /usr/local/bin/php-site-entrypoint \
    && chmod 0644 /usr/local/bin/php-site-db-ready /usr/local/bin/php-site-init-db

ENTRYPOINT ["/usr/local/bin/php-site-entrypoint"]
CMD ["httpd", "-DFOREGROUND"]
