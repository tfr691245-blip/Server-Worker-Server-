# Master Stealth Relay - AIO Build (April 2026)
FROM alpine:3.23

# 1. Install high-performance stack
RUN apk add --no-cache \
    nginx php83 php83-fpm php83-openssl php83-mbstring php83-json \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs /var/lib/mail-logs \
    && chown -R nginx:nginx /var/lib/mail-logs

# 2. Optimized Nginx Config
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

# 3. Create the Master HUD Index file directly
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
$limit_file = '/var/lib/mail-logs/limit.json';
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['action'])) {
    header('Content-Type: application/json');
    $config = json_decode($_POST['config'], true);
    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://'.$config['host'].':465', $errno, $errstr, 5, STREAM_CLIENT_CONNECT, $ctx);
    if ($sock) {
        $logs = [];
        $cmd = function($s) use ($sock, &$logs) { 
            fwrite($sock, $s); $logs[] = "OUT: " . trim($s);
            $r = fread($sock, 512); $logs[] = "IN: " . trim($r);
        };
        fread($sock, 512);
        $cmd("EHLO elite.relay\r\n");
        $cmd("AUTH LOGIN\r\n");
        $cmd(base64_encode($config['user'])."\r\n");
        $cmd(base64_encode($config['pass'])."\r\n");
        $cmd("MAIL FROM: <".$config['user'].">\r\n");
        $cmd("RCPT TO: <".$_POST['to'].">\r\n");
        $cmd("DATA\r\n");
        $headers = "From: ".$_POST['name']." <".$config['alias'].">\r\nTo: <".$_POST['to'].">\r\nSubject: ".$_POST['sub']."\r\nMIME-Version: 1.0\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n";
        $cmd($headers . $_POST['msg'] . "\r\n.\r\n");
        $cmd("QUIT\r\n"); fclose($sock);
        $data = file_exists($limit_file) ? json_decode(file_get_contents($limit_file), true) : ['d'=>date('Y-m-d'), 'c'=>0];
        if($data['d'] !== date('Y-m-d')) $data = ['d'=>date('Y-m-d'), 'c'=>0];
        $data['c']++; file_put_contents($limit_file, json_encode($data));
        echo json_encode(['status'=>'SUCCESS', 'logs'=>$logs, 'count'=>$data['c']]);
    } else { echo json_encode(['status'=>'ERROR', 'error'=>$errstr]); }
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>APEX CONSOLE</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: #020406; color: #00ff41; font-family: monospace; }
        .hud { border: 1px solid rgba(0,255,65,0.3); background: rgba(5,7,10,0.9); }
        input, textarea { background: #000; border: 1px solid #333; color: #fff; padding: 8px; outline: none; font-size: 12px; }
        input:focus { border-color: #00ff41; }
    </style>
</head>
<body class="p-4 md:p-10">
    <div class="max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div class="lg:col-span-4 hud p-6">
            <h3 class="text-xs font-bold mb-4 border-b border-[#00ff41] pb-2 text-white">SMTP AUTH</h3>
            <div class="flex flex-col gap-3">
                <input id="host" placeholder="Host (142.251.10.108)">
                <input id="user" placeholder="Gmail User">
                <input id="pass" type="password" placeholder="App Password">
                <input id="alias" placeholder="Sender Alias">
            </div>
            <div class="mt-6">
                <div class="flex justify-between text-[10px] mb-1"><span>CAPACITY</span><span id="cl">0/2000</span></div>
                <div class="w-full bg-[#111] h-1"><div id="bar" class="h-full bg-[#00ff41]" style="width:0%"></div></div>
            </div>
        </div>
        <div class="lg:col-span-8 hud p-6">
            <h3 class="text-xs font-bold mb-4 border-b border-[#00ff41] pb-2 text-white">INJECTION ENGINE</h3>
            <div class="grid grid-cols-2 gap-4 mb-4">
                <input id="name" placeholder="From Name">
                <input id="to" placeholder="Target Email">
            </div>
            <input id="sub" placeholder="Subject" class="w-full mb-4">
            <textarea id="msg" placeholder="HTML Body" class="w-full h-32 mb-4"></textarea>
            <button onclick="fire()" class="w-full bg-[#00ff41] text-black font-bold py-3 hover:bg-white transition-all uppercase">Execute Fire</button>
            <div id="term" class="mt-4 bg-black p-3 h-32 overflow-y-auto text-[10px] border border-[#222]"></div>
        </div>
    </div>
    <script>
        const keys = ['host','user','pass','alias'];
        keys.forEach(k => document.getElementById(k).value = localStorage.getItem('ax_'+k) || '');
        async function fire(){
            const cfg = {}; keys.forEach(k => { cfg[k] = document.getElementById(k).value; localStorage.setItem('ax_'+k, cfg[k]); });
            const fd = new FormData(); fd.append('action','send'); fd.append('config', JSON.stringify(cfg));
            ['name','to','sub','msg'].forEach(f => fd.append(f, document.getElementById(f).value));
            const res = await fetch('', {method:'POST', body:fd}).then(r => r.json());
            const term = document.getElementById('term');
            if(res.logs) res.logs.forEach(l => term.innerHTML += `<div>${l}</div>`);
            if(res.status === 'SUCCESS'){
                document.getElementById('cl').innerText = res.count + '/2000';
                document.getElementById('bar').style.width = (res.count/2000*100) + '%';
            }
            term.scrollTop = term.scrollHeight;
        }
    </script>
</body>
</html>
EOF

# 4. Final settings
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && nginx -g "daemon off;"
