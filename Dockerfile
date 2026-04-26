FROM alpine:latest

# 1. Install Core Services
RUN apk add --no-cache \
    postfix \
    cyrus-sasl \
    ca-certificates \
    tzdata \
    nginx \
    php83 \
    php83-fpm \
    && update-ca-certificates

# 2. SMTP Engine Configuration
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "header_size_limit = 4096000" \
    && /usr/bin/newaliases

# 3. Nginx Config for HTTPS & Timeout Fix
RUN mkdir -p /run/nginx && \
    echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_read_timeout 600; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Use CAT to write the UI (Fixes the syntax error)
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
$status = ""; $log = "[SYS] Ready.";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST["to"]; $sub = $_POST["subject"]; $msg = $_POST["message"];
    $h = "From: verified@elite.qzz.io\r\nContent-Type: text/html; charset=UTF-8";
    if (mail($to, $sub, $msg, $h)) { $status = "success"; $log = "[SEND] OK to $to"; }
    else { $status = "error"; $log = "[ERR] Failed to inject."; }
}
?>
<!DOCTYPE html><html><head><title>ELITE RELAY</title><script src="https://cdn.tailwindcss.com"></script><style>body{background:#020617;color:#fff;font-family:monospace;}.tab{display:none;}.active{display:block;}</style></head>
<body class="p-4 flex flex-col items-center">
    <div class="w-full max-w-2xl mt-10">
        <div class="flex space-x-1">
            <button onclick="st('d')" class="p-4 bg-blue-600 rounded-t-xl text-[10px] font-bold tracking-widest">DEPLOY CONSOLE</button>
            <button onclick="st('l')" class="p-4 bg-slate-800 rounded-t-xl text-[10px] font-bold tracking-widest">SYSTEM LOGS</button>
        </div>
        <div id="d" class="tab active bg-slate-900/50 backdrop-blur-md p-8 rounded-b-2xl rounded-tr-2xl border border-white/10 shadow-2xl">
            <form method="POST" class="space-y-4">
                <input name="to" required class="w-full bg-black/50 p-4 rounded-xl border border-slate-700 outline-none focus:border-blue-500" placeholder="Destination Email">
                <input name="subject" required class="w-full bg-black/50 p-4 rounded-xl border border-slate-700 outline-none focus:border-blue-500" placeholder="Subject">
                <textarea name="message" rows="6" required class="w-full bg-black/50 p-4 rounded-xl border border-slate-700 outline-none focus:border-blue-500 resize-none" placeholder="Payload Message..."></textarea>
                <button type="submit" class="w-full bg-blue-600 py-5 rounded-xl font-black text-xs tracking-[0.3em] hover:bg-blue-500 transition-all">EXECUTE DEPLOY</button>
            </form>
        </div>
        <div id="l" class="tab bg-black/80 p-8 rounded-b-2xl rounded-tr-2xl border border-white/10 text-green-400 text-[11px] leading-loose">
            <div class="mb-4 opacity-50 uppercase tracking-widest">[Live Relay Feedback]</div>
            <div><?php echo $log; ?></div>
            <div>[SYS] Listening on Port 80</div>
            <div>[NET] HTTPS via Northflank Proxy Detected</div>
            <?php if ($status == "success"): ?>
                <div class="text-white mt-4 font-bold border-t border-white/10 pt-4">TRANSMISSION DATA:</div>
                <div class="text-blue-400">Target: <?php echo $to; ?></div>
                <div class="text-blue-400">Result: 250 OK (Queued)</div>
            <?php endif; ?>
        </div>
    </div>
    <script>function st(i){document.querySelectorAll(".tab").forEach(t=>t.classList.remove("active"));document.getElementById(i).classList.add("active");}</script>
</body></html>
EOF

# 5. Permissions and Startup
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && nginx && postfix start-fg
