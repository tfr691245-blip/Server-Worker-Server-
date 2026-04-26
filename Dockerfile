# Use the latest stable Ubuntu
FROM ubuntu:noble

# Prevent interactive prompts during the build
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Postfix and the CRITICAL SASL modules
# We explicitly name libsasl2-modules to ensure SMTP support is included
RUN apt-get update && apt-get install -y \
    postfix \
    libsasl2-modules \
    libsasl2-2 \
    ca-certificates \
    sasl2-bin \
    && rm -rf /var/lib/apt/lists/*

# 2. Pre-configure Postfix for Gmail Relay
# This replaces the need to run postconf commands manually after deployment
RUN postconf -e "relayhost = [smtp.gmail.com]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"

# 3. Ensure the worker keeps running
# This starts Postfix and then tails the logs so the container doesn't exit
CMD /usr/sbin/postfix start-fg
