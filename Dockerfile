FROM alpine:latest

# 1. Install System Stack (Nginx, PHP 8.3, Postfix, SASL)
RUN apk add --no-cache \
    postfix \
    cyrus-sasl \
    ca-certificates \
    tzdata \
    nginx \
    php83 \
    php83-fpm \
    && update-ca-certificates

# 2. Advanced Postfix Engine Setup
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "maillog_file = /dev/stdout" \
    && /usr/bin/newaliases

# 3. Nginx Gateway Optimization
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

# 4. The Advanced "Apex" UI (Integrated Terminal + Relay)
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
error_reporting(0);
$status = ""; $log = "[SYS] Online - Waiting for instruction..."; $cmd_out = "Type a command above to begin...";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST["to"])) {
        // Advanced SMTP Logic
        $to = filter_var($_POST["to"], FILTER_SANITIZE_EMAIL);
        $sub = htmlspecialchars($_POST["subject"]);
        $msg = $_POST["message"];
        $h = "From: verified@elite.qzz.io\r\nContent-Type: text/html; charset=UTF-8";
        if (mail($to, $sub, $msg, $h)) { 
            $status = "success"; 
            $log = "[RELAY] Transmission Accepted by Google SMTP Gate."; 
        } else { 
            $status = "error"; 
            $log = "[FATAL] Relay injection failed. Check Postfix logs."; 
        }
    } elseif (isset($_POST["cmd"])) {
        // Web SSH / Terminal Logic
        $command = $_POST["cmd"];
        if ($command == "clear") { $cmd_out = "Console cleared."; }
        else { $cmd_out = shell_exec($command . " 2>&1"); }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <title>ELITE APEX | SYSTEM CONTROL</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: #020617; color: #e2e8f0; font-family: "JetBrains Mono", monospace; }
        .tab-btn { transition: all 0.2s; border-bottom: 2px solid transparent; }
        .tab-btn.active { color: #3b82f6; border-bottom: 2px solid #3b82f6; background: rgba(59, 130, 246, 0.05); }
        .glass { background: rgba(15, 23, 42, 0.8); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.05); }
        .terminal-bg { background: #000000; border: 1px solid #1e293b; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: #334155; border-radius: 10px; }
    </style>
</head>
<body class="p-2 md:p-8">
    <div class="max-w-6xl mx-auto">
        <div class="flex items-center justify-between mb-8 px-4">
            <div class="flex items-center space-x-3">
                <div class="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
                <h1 class="text-xl font-black italic tracking-tighter uppercase text-white">Apex<span class="text-blue-500">.Relay</span></h1>
            </div>
            <div class="text-[10px] text-slate-500 font-bold uppercase tracking-widest">Master Level System v3.0</div>
        </div>

        <div class="flex space-x-1 mb-0 px-4">
            <button onclick="st('deploy', this)" class="tab-btn active px-6 py-4 text-xs font-black tracking-widest">DEPLOY</button>
            <button onclick="st('terminal', this)" class="tab-btn px-6 py-4 text-xs font-black tracking-widest text-slate-500">TERMINAL</button>
            <button onclick="st('logs', this)" class="tab-btn px-6 py-4 text-xs font-black tracking-widest text-slate-500">LOGS</button>
        </div>

        <div class="glass rounded-[2rem] p-6 md:p-10 shadow-2xl min-h-[600px]">
            
            <div id="deploy" class="tab-content block animate-in fade-in duration-300">
                <form method="POST" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-4">
                        <div class="group">
                            <label class="text-[10px] text-blue-500 font-bold ml-2 mb-1 block">TARGET_GATEWAY</label>
                            <input name="to" required class="w-full bg-black/40 border border-slate-800 rounded-2xl px-5 py-4 focus:border-blue-500 outline-none transition-all" placeholder="email@example.com">
                        </div>
                        <div class="group">
                            <label class="text-[10px] text-blue-500 font-bold ml-2 mb-1 block">HEADER_SUBJECT</label>
                            <input name="subject" required class="w-full bg-black/40 border border-slate-800 rounded-2xl px-5 py-4 focus:border-blue-500 outline-none transition-all" placeholder="System Alert">
                        </div>
                    </div>
                    <div class="flex flex-col">
                        <label class="text-[10px] text-blue-500 font-bold ml-2 mb-1 block">PAYLOAD_DATA</label>
                        <textarea name="message" required class="flex-grow bg-black/40 border border-slate-800 rounded-3xl px-5 py-4 focus:border-blue-500 outline-none transition-all resize-none mb-4" placeholder="Enter message body..."></textarea>
                        <button type="submit" class="bg-blue-600 hover:bg-blue-500 text-white font-black py-5 rounded-2xl shadow-xl shadow-blue-600/20 transition-all uppercase tracking-[0.3em] text-xs">Execute Transmission</button>
                    </div>
                </form>
            </div>

            <div id="terminal" class="tab-content hidden animate-in fade-in duration-300">
                <div class="terminal-bg rounded-3xl p-6 h-[500px] flex flex-col">
                    <div class="flex-grow overflow-y-auto mb-4 text-sm text-blue-400">
                        <pre class="whitespace-pre-wrap"><?php echo htmlspecialchars($cmd_out); ?></pre>
                    </div>
                    <form method="POST" class="flex items-center space-x-3 border-t border-slate-800 pt-4">
                        <span class="text-green-500 font-bold">root@apex:~#</span>
                        <input name="cmd" autofocus autocomplete="off" class="flex-grow bg-transparent outline-none text-white text-sm" placeholder="ls -la /var/log">
                    </form>
                </div>
            </div>

            <div id="logs" class="tab-content hidden animate-in fade-in duration-300">
                <div class="space-y-3">
                    <div class="p-4 bg-black/40 border border-slate-800 rounded-2xl flex items-center justify-between">
                        <span class="text-xs font-bold">Current Status:</span>
                        <span class="text-[10px] px-3 py-1 bg-green-500/10 text-green-500 rounded-full font-bold uppercase tracking-widest"><?php echo $status ?: "WAITING"; ?></span>
                    </div>
                    <div class="p-6 bg-black/80 rounded-3xl border border-slate-800 text-[11px] text-slate-400 leading-relaxed">
                        <div class="text-blue-500 font-bold mb-2 uppercase">[System Activity]</div>
                        <div><?php echo $log; ?></div>
                        <div class="mt-4 text-white opacity-40 uppercase tracking-tighter">Queue Inspection:</div>
                        <pre class="mt-2 text-green-600"><?php system("postqueue -p | head -n 5"); ?></pre>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <script>
        function st(id, btn) {
            document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
            document.querySelectorAll('.tab-btn').forEach(b => {
                b.classList.remove('active');
                b.classList.add('text-slate-500');
            });
            document.getElementById(id).classList.remove('hidden');
            btn.classList.add('active');
            btn.classList.remove('text-slate-500');
        }
    </script>
</body>
</html>
EOF

# 5. Runtime Permissions & Multi-Service Entrypoint
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && sleep 2 && nginx && postfix start-fg
