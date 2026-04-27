FROM alpine:3.19

# 1. INSTALL CORE STACK
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata curl && mkdir -p /run/nginx /var/www/localhost/htdocs

# 2. STABLE NGINX CONFIG
RUN echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_read_timeout 300; \
    } \
}' > /etc/nginx/http.d/default.conf

# 3. MASTER HUD PHP CODE
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
session_start();
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$smtp_host = 'ssl://142.251.10.108';
$log = 'registry.json';

if(!file_exists($log)) { file_put_contents($log, json_encode(['today'=>0,'date'=>date('Y-m-d')])); }
$reg = json_decode(file_get_contents($log), true);
if ($reg['date'] !== date('Y-m-d')) { $reg = ['today' => 0, 'date' => date('Y-m-d')]; }

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['token'])) {
    if ($_POST['token'] !== $_SESSION['last_token'] && $reg['today'] < 99) {
        $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
        $headers = ["From: $name <verified@elite.qzz.io>", "To: $to", "Subject: $sub", "MIME-Version: 1.0", "Content-Type: text/html; charset=UTF-8"];
        $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
        $sock = @stream_socket_client($smtp_host.':465', $errno, $errstr, 10, STREAM_CLIENT_CONNECT, $ctx);
        if ($sock) {
            fread($sock, 512); fwrite($sock, "EHLO relay\r\n"); fread($sock, 512);
            fwrite($sock, "AUTH LOGIN\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($user)."\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($pass)."\r\n"); fread($sock, 512);
            fwrite($sock, "MAIL FROM: <$user>\r\n"); fread($sock, 512);
            fwrite($sock, "RCPT TO: <$to>\r\n"); fread($sock, 512);
            fwrite($sock, "DATA\r\n"); fread($sock, 512);
            fwrite($sock, implode("\r\n", $headers) . "\r\n\r\n" . $msg . "\r\n.\r\n");
            fwrite($sock, "QUIT\r\n"); fclose($sock);
            $reg['today']++; file_put_contents($log, json_encode($reg));
            $_SESSION['last_token'] = $_POST['token'];
            header("Location: index.php?success=1"); exit;
        }
    }
}
$token = bin2hex(random_bytes(16));
?>
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MASTER HUD</title><script src="https://cdn.tailwindcss.com"></script>
<style>
    body { background: #000; color: #fff; font-family: sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; }
    .box { background: #080808; border: 1px solid #151515; border-radius: 2rem; width: 100%; max-width: 450px; padding: 35px; }
    input, textarea { background: #000; border: 1px solid #222; border-radius: 0.75rem; color: #fff; width: 100%; padding: 14px; margin-bottom: 12px; outline: none; font-size: 14px; }
    .btn { background: #fff; color: #000; font-weight: 900; width: 100%; padding: 18px; border-radius: 1rem; text-transform: uppercase; font-size: 12px; cursor: pointer; }
    .btn:hover { background: #38bdf8; color: #fff; }
</style></head>
<body><div class="box">
    <div class="flex justify-between items-start mb-10">
        <div><h1 class="text-2xl font-black italic">MASTER<span class="text-sky-400">SYNC</span></h1><a href="https://mail.google.com/mail/u/0/#search/newer_than%3A1d" target="_blank" class="text-[9px] text-sky-500 font-bold uppercase hover:underline">Verify →</a></div>
        <div class="text-right"><p class="text-[9px] text-slate-600 font-bold uppercase">Sent</p><p class="text-3xl font-black"><?php echo $reg['today']; ?><span class="text-slate-800 text-xs italic">/99</span></p></div>
    </div>
    <form method="POST">
        <input type="hidden" name="token" value="<?php echo $token; ?>">
        <input name="name" placeholder="FROM NAME" required>
        <input name="to" placeholder="TO@EMAIL.COM" type="email" required>
        <input name="sub" placeholder="SUBJECT" required>
        <textarea name="msg" placeholder="HTML..." class="h-32 resize-none"></textarea>
        <button class="btn">Execute Protocol</button>
    </form>
</div></body></html>
EOF

# 4. REPAIR PERMISSIONS
RUN touch /var/www/localhost/htdocs/registry.json && \
    chmod 777 /var/www/localhost/htdocs/registry.json && \
    chown -R nginx:nginx /var/www/localhost/htdocs

EXPOSE 80

# 5. STARTUP SCRIPT (Ensures PHP-FPM is ready before Nginx starts)
CMD php-fpm82 && nginx -g "daemon off;"
