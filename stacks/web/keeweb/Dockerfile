# =============================================================================
# KeeWeb (release HTML officielle) + WebDAV Apache.
# Docs : https://keeweb.info/
# Release : https://github.com/keeweb/keeweb/releases
# =============================================================================
FROM httpd:2.4.69-alpine3.24

ARG KEEWEB_VERSION=1.18.7

RUN apk add --no-cache curl unzip \
    && curl -fsSL --retry 5 \
        -o /tmp/keeweb.zip \
        "https://github.com/keeweb/keeweb/releases/download/v${KEEWEB_VERSION}/KeeWeb-${KEEWEB_VERSION}.html.zip" \
    && unzip -q /tmp/keeweb.zip -d /usr/local/apache2/htdocs \
    && rm -f /tmp/keeweb.zip \
    && sed -i 's|<meta name="kw-config" content="(no-config)">|<meta name="kw-config" content="./config.json">|' \
        /usr/local/apache2/htdocs/index.html

COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY config.json.template /opt/keeweb/config.json.template
COPY entrypoint.sh /usr/local/bin/keeweb-entrypoint

RUN chmod +x /usr/local/bin/keeweb-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/keeweb-entrypoint"]
CMD ["httpd-foreground"]
