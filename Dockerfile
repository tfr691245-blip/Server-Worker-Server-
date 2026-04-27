FROM alpine:3.19

# 1. THE STABLE CORE (Only what is necessary)
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs

# 2. HARDENED NGINX (Prevents the 4:40 PM ghost duplicates)
RUN echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    proxy_next_upstream off; \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_read_timeout 60s; \
    } \
}' > /etc/nginx/http.d/default.conf

# 3. ELITE HUD (Modern PC/Mobile + Google Sync Link)
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
session_start();
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$smtp_host = 'ssl://142.251.10.108';
$log = 'registry.json'; // Stored in webroot to prevent folder errors

// REAL-TIME LOCAL SYNC
$reg = file_exists($log) ? json_decode(file_get_contents($log), true) : ['today' => 0, 'date' => date('Y-m-d')];
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
            
            $reg['today']++; 
            file_put_contents($log, json_encode($reg));
            $_SESSION['last_token'] = $_POST['token'];
            header("Location: index.php?success=1"); exit;
        }
    }
}
$token = bin2hex(random_bytes(16));
?>
<!DOCTYPE html><html lang="en"><head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MASTER HUD</title><script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: #000; color: #fff; font-family: sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .box { background: #080808; border: 1px solid #151515; border-radius: 2.5rem; width: 100%; max-width: 480px; padding: 40px; }
        input, textarea { background: #000; border: 1px solid #222; border-radius: 1rem; color: #fff; width: 100%; padding: 16px; margin-bottom: 16px; outline: none; font-size: 14px; }
        input:focus { border-color: #38bdf8; }
        .btn { background: #fff; color: #000; font-weight: 900; width: 100%; padding: 20px; border-radius: 1.2rem; text-transform: uppercase; transition: 0.2s; letter-spacing: 1px; }
        .btn:hover { background: #38bdf8; color: #fff; transform: translateY(-2px); }
    </style></head>
<body class="p-4">
    <div class="box">
        <div class="flex justify-between items-start mb-12">
            <div>
                <h1 class="text-3xl font-black italic tracking-tighter">MASTER<span class="text-sky-400">SYNC</span></h1>
                <a href="https://mail.google.com/mail/u/0/#search/newer_than%3A1d" target="_blank" class="text-[10px] text-sky-500 font-bold uppercase tracking-widest hover:underline">Check Google Real Count →</a>
            </div>
            <div class="text-right">
                <p class="text-[10px] text-slate-600 font-bold uppercase mb-1">Today</p>
                <p class="text-4xl font-black"><?php echo $reg['today']; ?><span class="text-slate-800 text-sm italic">/99</span></p>
            </div>
        </div>
        <form method="POST">
            <input type="hidden" name="token" value="<?php echo $token; ?>">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-4">
                <input name="name" placeholder="SENDER NAME" required>
                <input name="to" placeholder="TARGET EMAIL" type="email" required>
            </div>
            <input name="sub" placeholder="SUBJECT" required>
            <textarea name="msg" placeholder="HTML PAYLOAD..." class="h-40 resize-none"></textarea>
            <?php if($reg['today'] >= 99): ?>
                <div class="text-red-500 text-[10px] font-black text-center border border-red-900/20 p-5 rounded-2xl bg-red-950/10">LIMIT BREACHED: GOOGLE LOCK ACTIVE</div>
            <?php else: ?>
                <button class="btn">Execute Injection</button>
            <?php endif; ?>
        </form>
    </div>
</body></html>
EOF

# 4. FIXED PERMISSIONS (Correct paths only)
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm82 && nginx -g "daemon off;"
