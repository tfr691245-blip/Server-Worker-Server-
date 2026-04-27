FROM alpine:3.19

# 1. Official Kernel Stack (Everything needed for Real Sync)
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json php82-imap \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs

# 2. Optimized Nginx (Prevents Duplicate 500 Retries)
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

# 3. Modern Animated HUD
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
session_start();
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$smtp_host = 'ssl://142.251.10.108';

// REAL OFFICIAL SYNC LOGIC
function get_real_count($u, $p) {
    // Attempting to sync with Google Sent Folder
    $mbox = @imap_open("{imap.gmail.com:993/imap/ssl}[Gmail]/Sent Mail", $u, $p);
    if (!$mbox) return "OFFLINE";
    $since = date("d-M-Y", strtotime("-1 day"));
    $emails = imap_search($mbox, 'SINCE "'.$since.'"');
    $count = $emails ? count($emails) : 0;
    @imap_close($mbox);
    return $count;
}

$official_count = get_real_count($user, $pass);
$token = bin2hex(random_bytes(16));

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['token'])) {
    if ($_POST['token'] !== $_SESSION['last_token'] && $official_count < 99) {
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
            
            $_SESSION['last_token'] = $_POST['token'];
            header("Location: index.php?success=1"); exit;
        }
    }
}
?>
<!DOCTYPE html><html lang="en"><head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MASTER RELAY HUD</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;700;800&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Plus Jakarta Sans', sans-serif; background: #000; color: #fff; overflow-x: hidden; }
        .glass { background: rgba(15, 15, 15, 0.7); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.08); }
        .glow-btn { transition: 0.4s; background: #fff; color: #000; box-shadow: 0 0 20px rgba(255,255,255,0.1); }
        .glow-btn:hover { background: #38bdf8; color: #fff; transform: translateY(-3px); box-shadow: 0 10px 30px rgba(56, 189, 248, 0.4); }
        .input-style { background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.08); transition: 0.3s; }
        .input-style:focus { border-color: #38bdf8; background: rgba(255,255,255,0.05); outline: none; }
        @keyframes float { 0% { transform: translateY(0px); } 50% { transform: translateY(-10px); } 100% { transform: translateY(0px); } }
        .animate-float { animation: float 4s ease-in-out infinite; }
    </style>
</head>
<body class="min-h-screen flex items-center justify-center p-4">
    <div class="glass w-full max-w-lg p-8 md:p-12 rounded-[2.5rem] shadow-2xl relative overflow-hidden">
        <div class="absolute -top-24 -right-24 w-64 h-64 bg-sky-500/10 rounded-full blur-[100px]"></div>
        
        <div class="flex justify-between items-start mb-12 relative z-10">
            <div>
                <h1 class="text-3xl font-[800] tracking-tighter italic">MASTER<span class="text-sky-400">SYNC</span></h1>
                <p class="text-[10px] text-slate-500 font-bold uppercase tracking-[0.3em] mt-1">Official Protocol v7</p>
            </div>
            <div class="text-right">
                <p class="text-[10px] text-slate-500 font-bold uppercase mb-1">Official Sent</p>
                <p class="text-3xl font-black text-white"><?php echo $official_count; ?><span class="text-slate-700 text-sm italic">/99</span></p>
            </div>
        </div>

        <form method="POST" class="space-y-5 relative z-10">
            <input type="hidden" name="token" value="<?php echo $token; ?>">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <input name="name" placeholder="FROM NAME" required class="input-style p-4 rounded-2xl text-xs w-full">
                <input name="to" placeholder="TARGET EMAIL" type="email" required class="input-style p-4 rounded-2xl text-xs w-full">
            </div>
            <input name="sub" placeholder="SUBJECT LINE" required class="input-style p-4 rounded-2xl text-xs w-full">
            <textarea name="msg" placeholder="HTML PAYLOAD..." class="input-style p-4 rounded-2xl text-xs w-full h-32 md:h-40 resize-none"></textarea>
            
            <?php if($official_count >= 99): ?>
                <div class="w-full bg-rose-500/20 text-rose-400 p-5 rounded-2xl text-center text-xs font-bold border border-rose-500/30">
                    GOOGLE LIMIT BREACHED - LOCKING SYSTEM
                </div>
            <?php else: ?>
                <button class="w-full glow-btn py-5 rounded-2xl font-black uppercase tracking-widest text-xs">Execute Official Fire</button>
            <?php endif; ?>
        </form>

        <div class="mt-12 flex justify-between items-center text-[10px] font-bold text-slate-600 relative z-10">
            <div class="flex items-center gap-2">
                <span class="w-2 h-2 rounded-full bg-sky-400 animate-pulse"></span>
                <span>SYSTEM: SYNCED</span>
            </div>
            <span>24H ROLLING WINDOW</span>
        </div>
    </div>
</body></html>
EOF

# 4. Permissions
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm82 && nginx -g "daemon off;"
