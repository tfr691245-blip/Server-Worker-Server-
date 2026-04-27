FROM alpine:3.19

# 1. INSTALL STACK + SUPERVISOR
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata supervisor && mkdir -p /run/nginx /var/www/localhost/htdocs /var/log/supervisor

# 2. NGINX CONFIG
RUN echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/http.d/default.conf

# 3. SUPERVISOR CONFIG (Ensures processes don't exit)
RUN echo '[supervisord] \n\
nodaemon=true \n\
[program:php-fpm] \n\
command=php-fpm82 -F \n\
[program:nginx] \n\
command=nginx -g "daemon off;"' > /etc/supervisord.conf

# 4. MASTER HUD CODE
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
session_start();
$log = 'registry.json';
if(!file_exists($log)) { file_put_contents($log, json_encode(['today'=>0,'date'=>date('Y-m-d')])); }
$reg = json_decode(file_get_contents($log), true);

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://142.251.10.108:465', $e, $s, 10, STREAM_CLIENT_CONNECT, $ctx);
    if ($sock) {
        fwrite($sock, "EHLO relay\r\nAUTH LOGIN\r\n".base64_encode('pyypl2005@gmail.com')."\r\n".base64_encode('gnrbyxyyjxyoaljv')."\r\n");
        fwrite($sock, "MAIL FROM: <pyypl2005@gmail.com>\r\nRCPT TO: <$to>\r\nDATA\r\nFrom: $name <v@q.io>\r\nSubject: $sub\r\nContent-Type: text/html\r\n\r\n$msg\r\n.\r\nQUIT\r\n");
        fclose($sock);
        $reg['today']++; file_put_contents($log, json_encode($reg));
    }
}
?>
<!DOCTYPE html><html><body style="background:#000;color:#fff;font-family:sans-serif;padding:50px;display:flex;justify-content:center;">
<div style="background:#111;padding:30px;border-radius:20px;width:100%;max-width:400px;border:1px solid #222;">
<h1 style="font-weight:900;">MASTER<span style="color:#38bdf8">SYNC</span> [<?php echo $reg['today']; ?>]</h1>
<form method="POST" style="margin-top:20px;">
<input name="name" placeholder="FROM" style="width:100%;padding:10px;margin-bottom:10px;background:#000;border:1px solid #333;color:#fff;">
<input name="to" placeholder="TO" style="width:100%;padding:10px;margin-bottom:10px;background:#000;border:1px solid #333;color:#fff;">
<input name="sub" placeholder="SUBJECT" style="width:100%;padding:10px;margin-bottom:10px;background:#000;border:1px solid #333;color:#fff;">
<textarea name="msg" style="width:100%;height:100px;background:#000;border:1px solid #333;color:#fff;"></textarea>
<button style="width:100%;padding:15px;background:#fff;margin-top:10px;font-weight:bold;">EXECUTE</button>
</form></div></body></html>
EOF

# 5. PERMISSIONS & PORTS
RUN touch /var/www/localhost/htdocs/registry.json && chmod -R 777 /var/www/localhost/htdocs
EXPOSE 80

# 6. START SUPERVISOR
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
