# Official Google-Sync Kernel (Real-Time IMAP Check)
FROM alpine:3.19

# 1. Install Stack with PHP-IMAP support
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json php82-imap \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs

# 2. Optimized Routing
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

# 3. The Real-Time Sync HUD
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
// CORE AUTH
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$smtp_host = 'ssl://142.251.10.108';

// --- REAL KERNEL SYNC (OFFICIAL GOOGLE CHECK) ---
function get_official_count($u, $p) {
    $mbox = @imap_open("{imap.gmail.com:993/imap/ssl}[Gmail]/Sent Mail", $u, $p);
    if (!$mbox) return "ERR";
    $since = date("d-M-Y", strtotime("-1 day"));
    $emails = imap_search($mbox, 'SINCE "'.$since.'"');
    $count = $emails ? count($emails) : 0;
    imap_close($mbox);
    return $count;
}

$official_count = get_official_count($user, $pass);
$safe_limit = 99;

$status = "REAL_TIME_SYNC_ACTIVE";
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['fire'])) {
    $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
    $headers = ["From: $name <verified@elite.qzz.io>", "To: $to", "Subject: $sub", "MIME-Version: 1.0", "Content-Type: text/html; charset=UTF-8"];
    
    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client($smtp_host.':465', $errno, $errstr, 5, STREAM_CLIENT_CONNECT, $ctx);
    
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
        header("Location: " . $_SERVER['PHP_SELF'] . "?sent=true");
        exit;
    }
}
?>
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>REAL KERNEL SYNC</title>
<script src="https://cdn.tailwindcss.com"></script></head>
<body class="bg-[#050505] text-white font-mono flex items-center justify-center min-h-screen">
    <div class="w-full max-w-md p-8 border border-white/10 bg-[#0a0a0a] rounded-3xl shadow-2xl">
        <div class="flex justify-between items-start mb-8">
            <h1 class="text-2xl font-black italic tracking-tighter">REAL<span class="text-blue-500">SYNC</span></h1>
            <div class="text-right">
                <p class="text-[10px] text-slate-500 font-bold uppercase">Official Google Count</p>
                <p class="text-2xl font-black <?php echo $official_count >= 90 ? 'text-red-500' : 'text-emerald-400'; ?>">
                    <?php echo $official_count; ?> <span class="text-slate-700 text-sm">/ 99</span>
                </p>
            </div>
        </div>

        <form method="POST" class="space-y-4">
            <input type="hidden" name="fire" value="1">
            <div class="grid grid-cols-2 gap-4">
                <input name="name" placeholder="FROM NAME" required class="bg-black border border-white/10 p-4 rounded-xl text-xs outline-none focus:border-blue-500">
                <input name="to" placeholder="TO EMAIL" type="email" required class="bg-black border border-white/10 p-4 rounded-xl text-xs outline-none focus:border-blue-500">
            </div>
            <input name="sub" placeholder="SUBJECT" required class="bg-black border border-white/10 p-4 rounded-xl text-xs outline-none focus:border-blue-500 w-full">
            <textarea name="msg" placeholder="HTML PAYLOAD..." class="bg-black border border-white/10 p-4 rounded-xl text-xs outline-none focus:border-blue-500 w-full h-32 resize-none"></textarea>
            
            <?php if($official_count >= 99): ?>
                <div class="bg-red-500/20 text-red-500 p-4 rounded-xl text-[10px] font-bold text-center border border-red-500/30">
                    GOOGLE LIMIT REACHED - SYSTEM LOCKED
                </div>
            <?php else: ?>
                <button class="w-full bg-white text-black font-black py-4 rounded-xl hover:bg-blue-500 hover:text-white transition-all uppercase tracking-widest text-xs">Execute Protocol</button>
            <?php endif; ?>
        </form>

        <div class="mt-6 flex justify-center">
            <div class="flex items-center gap-2">
                <span class="w-2 h-2 rounded-full bg-blue-500 animate-pulse"></span>
                <span class="text-[9px] text-slate-500 font-bold uppercase tracking-widest">Linked to newer_than:1d</span>
            </div>
        </div>
    </div>
</body></html>
EOF

# 4. Final Setup
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm82 && nginx -g "daemon off;"
