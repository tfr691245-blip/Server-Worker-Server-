# Master Official Sync - Kernel v5 (2026)
FROM alpine:3.19

# 1. Official Stack
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs /var/lib/sys-kernel \
    && chown -R nginx:nginx /var/lib/sys-kernel

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

# 3. Automated Kernel-Sync HUD
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
// CORE AUTH
$smtp_host = 'ssl://142.251.10.108'; 
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$alias = 'verified@elite.qzz.io';
$kernel_file = '/var/lib/sys-kernel/registry.json';
$safe_limit = 99; // 100% Secure Threshold

// AUTOMATED KERNEL TRACKING
$reg = file_exists($kernel_file) ? json_decode(file_get_contents($kernel_file), true) : ['today' => 0, 'date' => date('Y-m-d')];
if ($reg['date'] !== date('Y-m-d')) {
    $reg = ['today' => 0, 'date' => date('Y-m-d')];
}

$status = "SYSTEM_READY";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if ($reg['today'] >= $safe_limit) { 
        $status = "LIMIT_BLOCK_ACTIVE"; 
    } else {
        $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
        $headers = ["From: $name <$alias>", "To: $to", "Subject: $sub", "MIME-Version: 1.0", "Content-Type: text/html; charset=UTF-8"];
        $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
        $sock = @stream_socket_client($smtp_host.':465', $errno, $errstr, 5, STREAM_CLIENT_CONNECT, $ctx);
        
        if ($sock) {
            fread($sock, 512); fwrite($sock, "EHLO kernel.sync\r\n"); fread($sock, 512);
            fwrite($sock, "AUTH LOGIN\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($user)."\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($pass)."\r\n"); fread($sock, 512);
            fwrite($sock, "MAIL FROM: <$user>\r\n"); fread($sock, 512);
            fwrite($sock, "RCPT TO: <$to>\r\n"); fread($sock, 512);
            fwrite($sock, "DATA\r\n"); fread($sock, 512);
            fwrite($sock, implode("\r\n", $headers) . "\r\n\r\n" . $msg . "\r\n.\r\n");
            fwrite($sock, "QUIT\r\n"); fclose($sock);
            
            // SYNC REGISTRY
            $reg['today']++; 
            file_put_contents($kernel_file, json_encode($reg));
            $status = "INJECTION_SUCCESS";
        } else { $status = "NET_TIMEOUT"; }
    }
}
?>
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>KERNEL SYNC HUD</title><script src="https://cdn.tailwindcss.com"></script>
<style>
    body { background: #010204; color: #fff; font-family: ui-monospace, monospace; height: 100vh; display: flex; align-items: center; justify-content: center; }
    .hud { background: #0d1117; border: 1px solid #30363d; border-radius: 24px; width: 400px; padding: 40px; box-shadow: 0 20px 50px rgba(0,0,0,0.5); }
    input, textarea { background: #000; border: 1px solid #21262d; border-radius: 12px; color: #fff; width: 100%; padding: 14px; font-size: 13px; outline: none; margin-bottom: 15px; }
    input:focus { border-color: #58a6ff; }
</style></head>
<body>
    <div class="hud">
        <div class="flex justify-between items-end mb-10">
            <div>
                <p class="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Official Sync</p>
                <h1 class="text-3xl font-black italic">KERNEL<span class="text-sky-500">V5</span></h1>
            </div>
            <div class="text-right">
                <p class="text-[10px] font-bold text-slate-500 uppercase mb-1">Sent Today</p>
                <p class="text-2xl font-black text-emerald-400"><?php echo $reg['today']; ?> <span class="text-slate-700 text-sm">/ 99</span></p>
            </div>
        </div>

        <form method="POST">
            <input name="name" placeholder="Sender Name" required>
            <input name="to" placeholder="Target Email" type="email" required>
            <input name="sub" placeholder="Subject" required>
            <textarea name="msg" placeholder="HTML Body" class="h-32 resize-none"></textarea>
            <button class="w-full bg-white text-black font-black py-4 rounded-2xl hover:bg-sky-500 hover:text-white transition-all uppercase tracking-widest text-xs">Execute Injection</button>
        </form>
        
        <div class="mt-6 text-center">
            <span class="text-[10px] font-bold text-slate-600 tracking-tighter">STATUS: <?php echo $status; ?></span>
        </div>
    </div>
</body></html>
EOF

# 4. Final Lock
RUN chown -R nginx:nginx /var/www/localhost/htdocs /var/lib/sys-kernel
EXPOSE 80
CMD php-fpm82 && nginx -g "daemon off;"
