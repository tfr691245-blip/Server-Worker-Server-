FROM alpine:3.19

# 1. Official Kernel Stack (Adds PHP-IMAP for real sync)
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

# 3. Real-Time Rolling Sync HUD
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$smtp_host = 'ssl://142.251.10.108';

// --- THE REAL KERNEL CALCULATION ---
// This talks to Google's IMAP server to get the REAL count of sent mail
function get_google_sync_count($u, $p) {
    $mbox = @imap_open("{imap.gmail.com:993/imap/ssl}[Gmail]/Sent Mail", $u, $p);
    if (!$mbox) return "ERR";
    
    // Search for all mail sent in the rolling 24h window
    $yesterday = date("d-M-Y", strtotime("-1 day"));
    $emails = imap_search($mbox, 'SINCE "'.$yesterday.'"');
    
    $count = $emails ? count($emails) : 0;
    imap_close($mbox);
    return $count;
}

$official_count = get_google_sync_count($user, $pass);
$status = "SYNCED";

if ($_SERVER["REQUEST_METHOD"] == "POST" && $official_count < 99) {
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
        // Instant Refresh to update count
        header("Location: " . $_SERVER['PHP_SELF']);
        exit;
    }
}
?>
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>OFFICIAL SYNC</title>
<script src="https://cdn.tailwindcss.com"></script></head>
<body class="bg-[#030303] text-white font-mono flex items-center justify-center min-h-screen">
    <div class="w-full max-w-md p-10 border border-white/5 bg-[#080808] rounded-[2rem] shadow-2xl">
        <div class="flex justify-between items-center mb-10">
            <div>
                <h1 class="text-2xl font-black italic tracking-tighter">OFFICIAL<span class="text-blue-500">SYNC</span></h1>
                <p class="text-[9px] text-slate-500 font-bold uppercase tracking-widest">Rolling 24H Window</p>
            </div>
            <div class="text-right">
                <p class="text-[10px] text-slate-500 font-bold mb-1">SENT</p>
                <p class="text-3xl font-black <?php echo $official_count >= 90 ? 'text-orange-500' : 'text-emerald-400'; ?>">
                    <?php echo $official_count; ?> <span class="text-slate-800 text-sm">/ 99</span>
                </p>
            </div>
        </div>

        <form method="POST" class="space-y-4">
            <input name="name" placeholder="SENDER NAME" required class="bg-black border border-white/5 p-4 rounded-2xl text-xs w-full focus:border-blue-500 outline-none">
            <input name="to" placeholder="RECIPIENT EMAIL" type="email" required class="bg-black border border-white/5 p-4 rounded-2xl text-xs w-full focus:border-blue-500 outline-none">
            <input name="sub" placeholder="SUBJECT" required class="bg-black border border-white/5 p-4 rounded-2xl text-xs w-full focus:border-blue-500 outline-none">
            <textarea name="msg" placeholder="HTML MESSAGE..." class="bg-black border border-white/5 p-4 rounded-2xl text-xs w-full h-32 focus:border-blue-500 outline-none resize-none"></textarea>
            
            <?php if($official_count >= 99): ?>
                <div class="bg-red-500 text-black font-black p-4 rounded-2xl text-center uppercase text-xs">LIMIT REACHED</div>
            <?php else: ?>
                <button class="w-full bg-white text-black font-black py-4 rounded-2xl hover:bg-blue-500 hover:text-white transition-all uppercase tracking-widest text-xs">Execute Protocol</button>
            <?php endif; ?>
        </form>

        <div class="mt-8 pt-6 border-t border-white/5 flex justify-between items-center text-[10px] text-slate-600 font-bold">
            <span>ENGINE: IMAP-KERNEL</span>
            <span class="flex items-center gap-1"><span class="w-1.5 h-1.5 bg-blue-500 rounded-full animate-ping"></span> SYNCED</span>
        </div>
    </div>
</body></html>
EOF

# 4. Final System Lock
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm82 && nginx -g "daemon off;"
