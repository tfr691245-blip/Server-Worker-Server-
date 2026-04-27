FROM alpine:3.19

# 1. INSTALL STACK
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata supervisor && mkdir -p /run/nginx /var/www/localhost/htdocs /var/log/supervisor

# 2. DEBUG PHP-FPM (Enables logging to stdout)
RUN sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/;php_flag\[display_errors\] = off/php_flag[display_errors] = on/g' /etc/php82/php-fpm.d/www.conf

# 3. DEBUG NGINX CONFIG
RUN cat > /etc/nginx/http.d/default.conf <<'EOF'
server {
    listen 80;
    root /var/www/localhost/htdocs;
    index index.php;
    # CRITICAL: This will show the exact error in logs
    error_log /dev/stdout info;
    access_log /dev/stdout;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        # Debugging timeouts
        fastcgi_read_timeout 300;
    }
}
EOF

# 4. SUPERVISOR (DEBUG MODE)
RUN cat > /etc/supervisord.conf <<'EOF'
[supervisord]
user=root
nodaemon=true
logfile=/dev/stdout
logfile_maxbytes=0

[program:php-fpm]
command=php-fpm82 -F
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:nginx]
command=nginx -g "daemon off;"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

# 5. UI CODE
RUN cat > /var/www/localhost/htdocs/index.php <<'EOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
session_start();
$log = 'registry.json';
if(!file_exists($log)) { file_put_contents($log, json_encode(['today'=>0,'date'=>date('Y-m-d')])); }
$reg = json_decode(file_get_contents($log), true);
?>
<!DOCTYPE html><html><body style="background:#000;color:#fff;font-family:sans-serif;padding:50px;">
<div style="background:#111;padding:30px;border-radius:20px;max-width:400px;border:1px solid #222;margin:auto;">
<h1 style="font-weight:900;">DEBUG_MODE: [<?php echo $reg['today'] ?? 'ERR'; ?>]</h1>
<p>PHP Version: <?php echo phpversion(); ?></p>
<form method="POST">
<input name="to" placeholder="TEST" style="width:100%;padding:10px;background:#000;border:1px solid #333;color:#fff;">
<button style="width:100%;padding:15px;background:#fff;margin-top:10px;font-weight:bold;color:#000;">TEST SEND</button>
</form></div></body></html>
EOF

# 6. PERMISSIONS
RUN touch /var/www/localhost/htdocs/registry.json && chmod -R 777 /var/www/localhost/htdocs
EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
