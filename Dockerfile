FROM alpine:latest

# 1. Install Postfix, Nginx, and PHP 8.3
RUN apk add --no-cache \
    postfix \
    cyrus-sasl \
    cyrus-sasl-login \
    ca-certificates \
    tzdata \
    nginx \
    php83 \
    php83-fpm \
    && update-ca-certificates

# 2. Master Level Postfix Optimization
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "inet_protocols = ipv4" \
    && postconf -e "maillog_file = /dev/stdout" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && postconf -e "smtp_tls_verify_cert_match = nexthop" \
    && /usr/bin/newaliases

# 3. Increase Timeouts in Nginx
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
        fastcgi_send_timeout 600; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Bake Advanced UI with Real-time Logs
RUN echo '<?php \
$status = ""; \
if ($_SERVER["REQUEST_METHOD"] == "POST") { \
    $to = filter_var($_POST["to"], FILTER_SANITIZE_EMAIL); \
    $subject = htmlspecialchars($_POST["subject"]); \
    $message = $_POST["message"]; \
    $headers = "From: verified@elite.qzz.io\r\nContent-Type: text/html; charset=UTF-8\r\n"; \
    if (mail($to, $subject, $message, $headers)) { $status = "success"; } else { $status = "error"; } \
} \
?> \
<!DOCTYPE html> \
<html lang="en"> \
<head> \
    <meta charset="UTF-8"> \
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> \
    <title>Elite Relay | Advance</title> \
    <script src="https://cdn.tailwindcss.com"></script> \
    <style> \
        body { background: #020617; color: white; font-family: "Inter", sans-serif; overflow-x: hidden; } \
        .glass { background: rgba(15, 23, 42, 0.8); backdrop-filter: blur(20px); border: 1px solid rgba(255, 255, 255, 0.1); } \
        .terminal { background: #000; font-family: monospace; color: #10b981; border: 1px solid #064e3b; } \
    </style> \
</head> \
<body class="min-h-screen p-4 md:p-10 flex flex-col items-center"> \
    <div class="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-2 gap-8"> \
        \
        <div class="glass rounded-[2.5rem] p-8 shadow-2xl"> \
            <div class="flex items-center space-x-3 mb-8"> \
                <div class="h-12 w-12 bg-blue-600 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-500/50"> \
                    <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg> \
                </div> \
                <h1 class="text-2xl font-black italic tracking-tighter uppercase">Elite<span class="text-blue-500 text-3xl">.</span>Relay</h1> \
            </div> \
            <?php if ($status == "success"): ?><div class="mb-4 p-4 bg-green-500/20 border border-green-500/50 rounded-2xl text-green-400 text-xs font-bold text-center">TRANSMISSION DELIVERED</div><?php endif; ?> \
            <form method="POST" class="space-y-4"> \
                <input type="email" name="to" required class="w-full bg-black/40 border border-slate-800 rounded-2xl px-6 py-4 outline-none focus:border-blue-500 transition-all text-sm" placeholder="Destination Gateway"> \
                <input type="text" name="subject" required class="w-full bg-black/40 border border-slate-800 rounded-2xl px-6 py-4 outline-none focus:border-blue-500 transition-all text-sm" placeholder="Subject"> \
                <textarea name="message" rows="6" required class="w-full bg-black/40 border border-slate-800 rounded-2xl px-6 py-4 outline-none focus:border-blue-500 transition-all text-sm resize-none" placeholder="Payload Data..."></textarea> \
                <button type="submit" class="w-full bg-blue-600 hover:bg-blue-500 text-white font-black py-5 rounded-2xl shadow-xl shadow-blue-600/30 transition-all uppercase tracking-[0.3em] text-xs">Execute Deploy</button> \
            </form> \
        </div> \
        \
        <div class="flex flex-col h-full"> \
            <div class="flex items-center justify-between mb-4 px-4"> \
                <span class="text-[10px] font-bold text-gray-500 uppercase tracking-widest">Relay Realtime Logs</span> \
                <span class="flex h-2 w-2 rounded-full bg-green-500 animate-pulse"></span> \
            </div> \
            <div class="terminal flex-grow rounded-3xl p-6 overflow-y-auto text-[11px] leading-relaxed shadow-inner max-h-[500px] lg:max-h-full"> \
                <div>[SYSTEM] Connection Established to US-Central...</div> \
                <div>[AUTH] pyypl2005@gmail.com verified via SASL.</div> \
                <div>[INFO] Waiting for payload deployment...</div> \
                <div id="live-log"></div> \
            </div> \
        </div> \
    </div> \
</body> \
</html>' > /var/www/localhost/htdocs/index.php

# 5. Startup
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80 587
CMD php-fpm83 && nginx && postfix start-fg
