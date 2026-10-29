# =============================================================================
# Azuriom - release officielle, installée dans l'image PHP/Apache.
# Docs : https://azuriom.com/docs/
# Release : https://github.com/Azuriom/Azuriom/releases
# =============================================================================
FROM php-apache:latest

ARG AZURIOM_VERSION=1.2.13
ARG AZURIOM_SHOP_VERSION=${AZURIOM_SHOP_VERSION:-1.2.26}
ARG AZURIOM_PRISM_VERSION=${AZURIOM_PRISM_VERSION:-1.1.0}

RUN curl -fsSL --retry 5 \
        -o /tmp/azuriom.zip \
        "https://github.com/Azuriom/Azuriom/releases/download/v${AZURIOM_VERSION}/Azuriom-${AZURIOM_VERSION}.zip" \
    && unzip -q /tmp/azuriom.zip -d /var/www/html \
    && rm -f /tmp/azuriom.zip \
    && chown -R apache:apache /var/www/html

# Extensions nécessaires aux données de démonstration (thème Prism, boutique).
# Elles sont installées dans les volumes au premier démarrage.
# Le plugin Shop doit suivre la branche 1.2.x d'Azuriom : la 0.2.x utilise
# Bootstrap 4/jQuery et n'est plus compatible avec Azuriom 1.2 (Bootstrap 5).
RUN set -eu; \
    mkdir -p \
        /opt/azuriom-seed/extensions/plugins/shop \
        /opt/azuriom-seed/extensions/themes/prism; \
    curl -fsSL --retry 5 \
        -o /tmp/shop.zip \
        "https://market.azuriom.com/api/resources/1/download/${AZURIOM_SHOP_VERSION}"; \
    unzip -q /tmp/shop.zip -d /opt/azuriom-seed/extensions/plugins/shop; \
    curl -fsSL --retry 5 \
        -o /tmp/prism.zip \
        "https://market.azuriom.com/api/resources/15/download/${AZURIOM_PRISM_VERSION}"; \
    unzip -q /tmp/prism.zip -d /opt/azuriom-seed/extensions/themes/prism; \
    rm -f /tmp/shop.zip /tmp/prism.zip

# Données de démonstration : SQL, images, vues et script d'application.
COPY seed /opt/azuriom-seed
COPY apache.conf /etc/apache2/conf.d/10-azuriom.conf
COPY entrypoint.sh /usr/local/bin/azuriom-entrypoint

RUN chmod +x /usr/local/bin/azuriom-entrypoint /opt/azuriom-seed/apply.sh \
    && ln -s /opt/azuriom-seed/apply.sh /usr/local/bin/azuriom-seed

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/azuriom-entrypoint"]
CMD ["httpd", "-DFOREGROUND"]
