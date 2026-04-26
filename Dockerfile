FROM alpine:latest

# 1. Install System Stack
RUN apk add --no-cache \
    postfix cyrus-sasl ca-certificates tzdata \
    nginx php83 php83-fpm \
    && update-ca-certificates

# 2. Permanent SMTP Configuration (Using DNS instead of raw IP)
RUN postconf -e "relayhost = [smtp.gmail.com]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && postconf -e "maillog_file = /dev/stdout" \
    && /usr/bin/newaliases

# 3. Nginx HTTPS & Performance Gateway
RUN mkdir -p /run/nginx && \
    echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    set_real_ip_from 0.0.0.0/0; \
    real_ip_header X-Forwarded-For; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_read_timeout 600; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. The Apex UI (Self-Correcting PHP Logic)
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
error_reporting(E_ALL);
$status = ""; $log = "[SYS] Node Ready."; $cmd_out = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST["to"])) {
        $to = filter_var($_POST["to"], FILTER_SANITIZE_EMAIL);
        $sub = htmlspecialchars($_POST["subject"]);
        $msg = $_POST["message"];
        $h = "From: verified@elite.qzz.io\r\nContent-Type: text/html; charset=UTF-8";
        if (mail($to, $sub, $msg, $h)) { 
            $status = "success"; $log = "[RELAY] Accepted. Check LOGS tab for queue status."; 
        } else { 
            $status = "error"; $log = "[FATAL] PHP mail() failed. Check terminal."; 
        }
    } elseif (isset($_POST["cmd"])) {
        $cmd_out = shell_exec($_POST["cmd"] . " 2>&1");
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>APEX CONTROL</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: #010409; color: #c9d1d9; font-family: monospace; }
        .apex-card { background: #0d1117; border: 1px solid #30363d; border-radius: 12px; }
        .active-tab { color: #58a6ff; border-bottom: 2px solid #58a6ff; }
        input, textarea { background: #161b22 !important; border: 1px solid #30363d !important; color: #ecf2f8 !important; }
    </style>
</head>
<body class="p-4 md:p-10">
    <div class="max-w-5xl mx-auto">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-xl font-bold tracking-widest">APEX_V4_ULTRA</h1>
            <div class="flex space-x-4">
                <button onclick="st('r', this)" class="pb-2 text-sm font-bold active-tab">RELAY</button>
                <button onclick="st('t', this)" class="pb-2 text-sm font-bold text-gray-500">TERMINAL</button>
                <button onclick="st('l', this)" class="pb-2 text-sm font-bold text-gray-500">LOGS</button>
            </div>
        </div>

        <div id="r" class="tab-content block">
            <div class="apex-card p-6">
                <form method="POST" class="space-y-4">
                    <input name="to" required class="w-full p-4 rounded-lg" placeholder="Recipient">
                    <input name="subject" required class="w-full p-4 rounded-lg" placeholder="Subject">
                    <textarea name="message" rows="6" required class="w-full p-4 rounded-lg" placeholder="HTML Payload..."></textarea>
                    <button class="w-full bg-blue-600 hover:bg-blue-500 text-white font-bold py-4 rounded-lg transition-all">EXECUTE TRANS</button>
                </form>
            </div>
        </div>

        <div id="t" class="tab-content hidden">
            <div class="apex-card p-4 bg-black">
                <pre class="h-80 overflow-y-auto text-[10px] text-green-400 p-2"><?php echo htmlspecialchars($cmd_out); ?></pre>
                <form method="POST" class="flex items-center space-x-2 border-t border-[#30363d] pt-4">
                    <span class="text-blue-500 font-bold">$</span>
                    <input name="cmd" autofocus class="flex-grow bg-transparent border-none p-1 text-sm outline-none" placeholder="Enter command...">
                </form>
            </div>
        </div>

        <div id="l" class="tab-content hidden">
            <div class="apex-card p-6">
                <div class="text-xs text-blue-500 font-bold mb-2 uppercase">Status: <?php echo $log; ?></div>
                <div class="text-xs text-gray-500 mt-4 uppercase">Postfix Queue Status:</div>
                <pre class="bg-black p-4 mt-2 text-[10px] text-gray-400"><?php system("postqueue -p"); ?></pre>
            </div>
        </div>
    </div>
    <script>
        function st(id, btn) {
            document.querySelectorAll('.tab-content').forEach(c => c.classList.replace('block', 'hidden'));
            document.querySelectorAll('button').forEach(b => b.classList.remove('active-tab', 'text-gray-500'));
            document.querySelectorAll('button').forEach(b => b.classList.add('text-gray-500'));
            document.getElementById(id).classList.replace('hidden', 'block');
            btn.classList.add('active-tab'); btn.classList.remove('text-gray-500');
        }
    </script>
</body>
</html>
EOF

# 5. Master Permissions & Startup
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && sleep 2 && nginx && postfix start-fg
