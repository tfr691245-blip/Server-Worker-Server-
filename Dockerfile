FROM alpine:latest

# 1. Install core requirements (Fixed package list)
RUN apk add --no-cache \
    postfix cyrus-sasl ca-certificates tzdata \
    nginx php83 php83-fpm \
    && update-ca-certificates

# 2. Your Verified SMTP Logic
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && /usr/bin/newaliases

# 3. Force-Create Directories & Nginx Config
# This section prevents the "No launch" error by pre-creating paths
RUN mkdir -p /run/nginx /var/www/localhost/htdocs
RUN echo 'server { \
    listen 80 default_server; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Minimalist Web UI (Clean & Fast)
RUN echo '<?php \
if ($_SERVER["REQUEST_METHOD"] == "POST") { \
    $h = "From: ".$_POST["n"]." <verified@elite.qzz.io>\r\nContent-Type: text/html"; \
    echo mail($_POST["t"], $_POST["s"], $_POST["m"], $h) ? "SENT" : "FAIL"; \
} ?> \
<form method="POST"> \
<input name="n" placeholder="Name"><input name="t" placeholder="To"><input name="s" placeholder="Sub"> \
<textarea name="m"></textarea><button>SEND</button></form>' > /var/www/localhost/htdocs/index.php

# 5. Global Permissions & Launch
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && nginx && postfix start-fg
