# =============================================================================
# Azuriom — release officielle, installée dans l'image PHP/Apache.
# Docs : https://azuriom.com/docs/
# Release : https://github.com/Azuriom/Azuriom/releases
# =============================================================================
FROM altherneum/php-apache:latest

ARG AZURIOM_VERSION=1.2.13

RUN curl -fsSL --retry 5 \
        -o /tmp/azuriom.zip \
        "https://github.com/Azuriom/Azuriom/releases/download/v${AZURIOM_VERSION}/Azuriom-${AZURIOM_VERSION}.zip" \
    && unzip -q /tmp/azuriom.zip -d /var/www/html \
    && rm -f /tmp/azuriom.zip \
    && chown -R apache:apache /var/www/html

COPY apache.conf /etc/apache2/conf.d/10-azuriom.conf
COPY entrypoint.sh /usr/local/bin/azuriom-entrypoint

RUN chmod +x /usr/local/bin/azuriom-entrypoint

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/azuriom-entrypoint"]
CMD ["httpd", "-DFOREGROUND"]
