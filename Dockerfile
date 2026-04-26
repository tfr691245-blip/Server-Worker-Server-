# Use Alpine for the smallest, fastest footprint
FROM alpine:latest

# 1. Install Postfix and SASL modules
# Removed --no-network so it can actually download the packages
RUN apk add --no-cache \
    postfix \
    cyrus-sasl \
    cyrus-sasl-plain \
    cyrus-sasl-login \
    ca-certificates \
    tzdata

# 2. Master Level Postfix Optimization
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "inet_protocols = ipv4" \
    && postconf -e "maillog_file = /dev/stdout" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && postconf -e "smtp_tls_verify_cert_match = nexthop" \
    && postconf -e "minimal_backoff_time = 30s" \
    && postconf -e "maximal_backoff_time = 120s" \
    && postconf -e "smtp_destination_concurrency_limit = 20"

# 3. Finalize setup
RUN /usr/bin/newaliases

# Start Postfix
EXPOSE 25
CMD ["postfix", "start-fg"]
