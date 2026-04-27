FROM alpine:3.19

# 1. Install Performance Stack
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs /var/lib/mail-tracker \
    && chown -R nginx:nginx /var/lib/mail-tracker

# 2. Optimized Nginx Config
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

# 3. Modern UI + Proven Engine
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
// --- CORE ENGINE (RETAINED) ---
$smtp_host = 'ssl://142.251.10.108'; 
$smtp_port = 465;
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$alias = 'verified@elite.qzz.io';
$limit_file = '/var/lib/mail-tracker/count.json';
$daily_max = 2000;

$data = file_exists($limit_file) ? json_decode(file_get_contents($limit_file), true) : ['date' => date('Y-m-d'), 'count' => 0];
if ($data['date'] !== date('Y-m-d')) { $data = ['date' => date('Y-m-d'), 'count' => 0]; }

$status = "READY";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST['to'];
    $name = $_POST['name'];
    $sub = $_POST['sub'];
    $msg = $_POST['msg'];

    $headers = ["From: $name <$alias>","To: $to","Subject: $sub","MIME-Version: 1.0","Content-Type: text/html; charset=UTF-8"];
    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client($smtp_host.':'.$smtp_port, $errno, $errstr, 5, STREAM_CLIENT_CONNECT, $ctx);

    if ($sock) {
        fread($sock, 512);
        fwrite($sock, "EHLO elite.qzz.io\r\n"); fread($sock, 512);
        fwrite($sock, "AUTH LOGIN\r\n"); fread($sock, 512);
        fwrite($sock, base64_encode($user)."\r\n"); fread($sock, 512);
        fwrite($sock, base64_encode($pass)."\r\n"); fread($sock, 512);
        fwrite($sock, "MAIL FROM: <$user>\r\n"); fread($sock, 512);
        fwrite($sock, "RCPT TO: <$to>\r\n"); fread($sock, 512);
        fwrite($sock, "DATA\r\n"); fread($sock, 512);
        fwrite($sock, implode("\r\n", $headers) . "\r\n\r\n" . $msg . "\r\n.\r\n");
        fwrite($sock, "QUIT\r\n");
        fclose($sock);
        $data['count']++;
        file_put_contents($limit_file, json_encode($data));
        $status = "SENT";
    } else { $status = "ERROR"; }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relay Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: radial-gradient(circle at top right, #1e293b, #0f172a); min-height: 100vh; font-family: 'Inter', sans-serif; }
        .glass { background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.1); }
        .input-style { background: rgba(0, 0, 0, 0.2); border: 1px solid rgba(255, 255, 255, 0.1); transition: all 0.3s ease; }
        .input-style:focus { border-color: #38bdf8; box-shadow: 0 0 10px rgba(56, 189, 248, 0.2); outline: none; }
        @keyframes slideIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        .animate-ui { animation: slideIn 0.5s ease forwards; }
    </style>
</head>
<body class="flex items-center justify-center p-6">
    <div class="glass w-full max-w-lg rounded-3xl p-8 shadow-2xl animate-ui">
        <header class="flex justify-between items-center mb-8">
            <div>
                <h1 class="text-white text-2xl font-bold tracking-tight">Relay<span class="text-sky-400">Hub</span></h1>
                <p class="text-slate-400 text-xs">SMTP Active & Encrypted</p>
            </div>
            <div class="text-right">
                <span class="text-[10px] text-slate-500 uppercase font-bold">Status</span>
                <div class="flex items-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                    <span class="text-emerald-400 text-sm font-medium"><?php echo $status; ?></span>
                </div>
            </div>
        </header>

        <div class="mb-8">
            <div class="flex justify-between items-end mb-2">
                <span class="text-slate-300 text-xs font-semibold uppercase">Daily Usage</span>
                <span class="text-slate-400 text-xs"><?php echo $data['count']; ?> / 2000</span>
            </div>
            <div class="w-full h-2 bg-slate-800 rounded-full overflow-hidden">
                <div class="h-full bg-gradient-to-r from-sky-500 to-indigo-500 transition-all duration-1000" style="width: <?php echo ($data['count']/2000)*100; ?>%"></div>
            </div>
        </div>

        <form method="POST" class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
                <div>
                    <label class="text-slate-400 text-[10px] uppercase font-bold ml-1 mb-1 block">Sender Name</label>
                    <input name="name" required class="input-style w-full rounded-xl px-4 py-3 text-white text-sm" placeholder="e.g. Admin">
                </div>
                <div>
                    <label class="text-slate-400 text-[10px] uppercase font-bold ml-1 mb-1 block">Recipient</label>
                    <input name="to" type="email" required class="input-style w-full rounded-xl px-4 py-3 text-white text-sm" placeholder="target@mail.com">
                </div>
            </div>
            
            <div>
                <label class="text-slate-400 text-[10px] uppercase font-bold ml-1 mb-1 block">Subject</label>
                <input name="sub" required class="input-style w-full rounded-xl px-4 py-3 text-white text-sm" placeholder="Security Update">
            </div>

            <div>
                <label class="text-slate-400 text-[10px] uppercase font-bold ml-1 mb-1 block">Content (HTML)</label>
                <textarea name="msg" class="input-style w-full rounded-xl px-4 py-3 text-white text-sm h-32 resize-none" placeholder="Write your message..."></textarea>
            </div>

            <button type="submit" class="w-full bg-white hover:bg-sky-400 text-slate-900 font-bold py-4 rounded-2xl transition-all active:scale-95 shadow-lg shadow-sky-500/10">
                Send Message
            </button>
        </form>
    </div>
</body>
</html>
EOF

# 4. Set Permissions
RUN chown -R nginx:nginx /var/www/localhost/htdocs

EXPOSE 80
# 5. Fast Launch
CMD php-fpm82 && nginx -g "daemon off;"
