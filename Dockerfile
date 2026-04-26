FROM alpine:latest

# 1. Install only the absolute essentials (Fixing the "apk" errors)
RUN apk add --no-cache \
    postfix \
    cyrus-sasl \
    ca-certificates \
    tzdata \
    nginx \
    php83 \
    php83-fpm \
    && update-ca-certificates

# 2. Hardcoded Postfix Fix (No "fucker" timeouts)
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "header_size_limit = 4096000" \
    && /usr/bin/newaliases

# 3. Nginx Config for HTTPS & Logs
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

# 4. The Advanced UI with the Log Tab
RUN echo '<?php \
$status = ""; $log = "[SYS] Ready."; \
if ($_SERVER["REQUEST_METHOD"] == "POST") { \
    $to = $_POST["to"]; $sub = $_POST["subject"]; $msg = $_POST["message"]; \
    $h = "From: verified@elite.qzz.io\r\nContent-Type: text/html;"; \
    if (mail($to, $sub, $msg, $h)) { $status = "success"; $log = "[SEND] OK to $to"; } \
    else { $status = "error"; $log = "[ERR] Failed to inject."; } \
} \
?> \
<!DOCTYPE html><html><head><script src="https://cdn.tailwindcss.com"></script><style>body{background:#020617;color:#fff;font-family:monospace;}.tab{display:none;}.active{display:block;}</style></head> \
<body class="p-4 flex flex-col items-center"> \
    <div class="w-full max-w-2xl"> \
        <div class="flex space-x-1 mb-4"> \
            <button onclick="st(\'d\')" class="p-3 bg-blue-600 rounded-t-xl text-[10px] font-bold">CONSOLE</button> \
            <button onclick="st(\'l\')" class="p-3 bg-slate-800 rounded-t-xl text-[10px] font-bold">LOGS</button> \
        </div> \
        <div id="d" class="tab active bg-slate-900 p-6 rounded-b-xl border border-white/10"> \
            <form method="POST" class="space-y-3"> \
                <input name="to" class="w-full bg-black p-3 rounded-lg border border-slate-700" placeholder="Email"> \
                <input name="subject" class="w-full bg-black p-3 rounded-lg border border-slate-700" placeholder="Subject"> \
                <textarea name="message" rows="5" class="w-full bg-black p-3 rounded-lg border border-slate-700" placeholder="Message"></textarea> \
                <button type="submit" class="w-full bg-blue-600 p-4 font-bold text-xs tracking-widest">DEPLOY</button> \
            </form> \
        </div> \
        <div id="l" class="tab bg-black p-6 rounded-b-xl border border-white/10 text-green-400 text-[10px]"> \
            <div><?php echo $log; ?></div> \
            <div>[SYS] Listening on Port 80 (HTTPS via Proxy)</div> \
        </div> \
    </div> \
    <script>function st(i){document.querySelectorAll(".tab").forEach(t=>t.classList.remove("active"));document.getElementById(i).classList.add("active");}</script> \
</body></html>' > /var/www/localhost/htdocs/index.php

# 5. Cleanup & Start
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && nginx && postfix start-fg
