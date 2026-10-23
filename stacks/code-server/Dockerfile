# =============================================================================
# code-server officiel (Coder).
# Docs : https://coder.com/docs/code-server
# =============================================================================
FROM codercom/code-server:4.141.0

USER root
RUN install -d -o coder -g coder /home/coder/workspace
USER coder

WORKDIR /home/coder/workspace
