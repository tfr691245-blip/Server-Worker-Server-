# Use Alpine for the smallest, fastest footprint (approx 5MB base)
FROM alpine:latest

# 1. Install Postfix and SASL modules
# Alpine's package manager (apk) is much faster than apt
RUN apk add --no-network --no-cache \
    postfix \
    cyrus-sasl \
    cyrus-sasl-plain \
    cyrus-sasl-login \
    ca-certificates \
    tzdata

# 2. Master Level Postfix Optimization
# - inet_protocols = ipv4: Stops DNS lag
# - bounce_queue_lifetime = 1h: Don't clog memory with old failed mail
# - maximal_queue_lifetime = 1h: Keeps the queue lean
# - smtp_destination_concurrency_limit = 20: Sends more emails at once
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

# 3. Create the spool directory and fix permissions
RUN /usr/bin/newaliases

# Start Postfix in foreground mode for Docker
EXPOSE 25
CMD ["postfix", "start-fg"]
