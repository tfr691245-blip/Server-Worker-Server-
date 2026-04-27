# Master Stealth Relay - Ultimate 8DEA Edition (2026)
FROM alpine:3.19

# 1. Performance Stack (Optimized for Northflank/Docker)
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs /var/lib/mail-tracker \
    && chown -R nginx:nginx /var/lib/mail-tracker

# 2. Optimized Nginx Config (Instant Pass-through)
RUN echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_keep_conn on; \
    } \
}' > /etc/nginx/http.d/default.conf

# 3. The Smart Hacker HUD + Stealth Engine
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
// --- MASTER CONFIG ---
$smtp_host = 'ssl://142.251.10.108'; 
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$alias = 'verified@elite.qzz.io';
$limit_file = '/var/lib/mail-tracker/master_v3.json';
$daily_max = 99; // Safe Red-Line

// --- 8DEA SYNC LOGIC ---
$log = file_exists($limit_file) ? json_decode(file_get_contents($limit_file), true) : ['history' => [], 'today' => 0, 'last' => date('Y-m-d')];
if ($log['last'] !== date('Y-m-d')) {
    array_unshift($log['history'], $log['today']);
    $log['history'] = array_slice($log['history'], 0, 8);
    $log['today'] = 0;
    $log['last'] = date('Y-m-d');
}
$reputation = count($log['history']) > 0 ? round(100 - ((array_sum($log['history'])/count($log['history'])) / $daily_max * 100)) : 100;

$status = "READY";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if ($log['today'] >= $daily_max) { $status = "LIMIT HIT"; }
    else {
        $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
        $headers = ["From: $name <$alias>", "To: $to", "Subject: $sub", "MIME-Version: 1.0", "Content-Type: text/html; charset=UTF-8"];
        $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
        $sock = @stream_socket_client($smtp_host.':465', $errno, $errstr, 5, STREAM_CLIENT_CONNECT, $ctx);
        if ($sock) {
            fread($sock, 512); fwrite($sock, "EHLO elite.qzz.io\r\n"); fread($sock, 512);
            fwrite($sock, "AUTH LOGIN\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($user)."\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($pass)."\r\n"); fread($sock, 512);
            fwrite($sock, "MAIL FROM: <$user>\r\n"); fread($sock, 512);
            fwrite($sock, "RCPT TO: <$to>\r\n"); fread($sock, 512);
            fwrite($sock, "DATA\r\n"); fread($sock, 512);
            fwrite($sock, implode("\r\n", $headers) . "\r\n\r\n" . $msg . "\r\n.\r\n");
            fwrite($sock, "QUIT\r\n"); fclose($sock);
            $log['today']++; file_put_contents($limit_file, json_encode($log));
            $status = "SUCCESS";
        } else { $status = "ERROR"; }
    }
}
?>
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>MASTER CONSOLE</title><script src="https://cdn.tailwindcss.com"></script>
<style>
    body { background: #020617; color: white; font-family: 'JetBrains Mono', monospace; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    .glass { background: rgba(15, 23, 42, 0.8); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.05); border-radius: 2rem; }
    input, textarea { background: rgba(0,0,0,0.4); border: 1px solid rgba(255,255,255,0.1); border-radius: 1rem; color: #fff; width: 100%; padding: 12px; font-size: 13px; }
    input:focus { border-color: #38bdf8; outline: none; box-shadow: 0 0 15px rgba(56, 189, 248, 0.2); }
    .rep-bar { background: linear-gradient(90deg, #38bdf8, #818cf8); height: 100%; transition: width 1s ease; }
</style></head>
<body class="p-4">
    <div class="glass w-full max-w-lg p-10 shadow-2xl animate-fade-in">
        <div class="flex justify-between items-start mb-10">
            <div>
                <h1 class="text-2xl font-black italic tracking-tighter text-white">STEALTH<span class="text-sky-400">HUB</span></h1>
                <p class="text-[9px] text-slate-500 font-bold uppercase tracking-[0.3em]">Protocol: 8DEA Dynamic Sync</p>
            </div>
            <div class="text-right">
                <span class="text-[9px] text-slate-500 uppercase font-bold">Account Health</span>
                <div class="text-2xl font-black text-sky-400"><?php echo $reputation; ?>%</div>
            </div>
        </div>

        <div class="grid grid-cols-2 gap-4 mb-8">
            <div class="bg-black/40 p-4 rounded-2xl border border-white/5">
                <p class="text-[9px] text-slate-500 uppercase mb-1">Today's Pulse</p>
                <p class="text-lg font-bold"><?php echo $log['today']; ?> <span class="text-slate-600">/ 99</span></p>
            </div>
            <div class="bg-black/40 p-4 rounded-2xl border border-white/5">
                <p class="text-[9px] text-slate-500 uppercase mb-1">Engine Status</p>
                <p class="text-lg font-bold <?php echo $status=='SUCCESS'?'text-emerald-400':'text-sky-400'; ?>"><?php echo $status; ?></p>
            </div>
        </div>

        <form method="POST" class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
                <input name="name" placeholder="FROM NAME" required>
                <input name="to" placeholder="TARGET@MAIL.COM" type="email" required>
            </div>
            <input name="sub" placeholder="SUBJECT LINE" required>
            <textarea name="msg" placeholder="HTML PAYLOAD..." class="h-32 resize-none"></textarea>
            <button class="w-full bg-sky-500 hover:bg-white hover:text-black text-white font-black py-4 rounded-2xl transition-all active:scale-95 uppercase tracking-widest text-xs">Execute Protocol</button>
        </form>
    </div>
</body></html>
EOF

# 4. Final Permissions & Launch
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm82 && nginx -g "daemon off;"
