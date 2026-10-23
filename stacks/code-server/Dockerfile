# =============================================================================
# code-server officiel (Coder).
# Docs : https://coder.com/docs/code-server
# =============================================================================
FROM codercom/code-server:4.141.0

USER root
RUN install -d -o coder -g coder \
        /home/coder/workspace \
        /home/coder/.local/share/code-server/extensions

COPY entrypoint.sh /usr/local/bin/code-server-entrypoint
RUN chmod +x /usr/local/bin/code-server-entrypoint

USER coder

WORKDIR /home/coder/workspace

ENTRYPOINT ["/usr/local/bin/code-server-entrypoint"]
