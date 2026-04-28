FROM alpine:3.19

# 1. INSTALL
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    php82-session php82-curl \
    tzdata supervisor && mkdir -p /run/nginx /var/www/localhost/htdocs /var/log/supervisor

# 2. CONFIGS (No-Rotation)
RUN sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/g' /etc/php82/php-fpm.d/www.conf
RUN cat > /etc/nginx/http.d/default.conf <<'EOF'
server {
    listen 80;
    root /var/www/localhost/htdocs;
    index index.php;
    location / { try_files $uri $uri/ /index.php?$args; }
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
EOF

RUN cat > /etc/supervisord.conf <<'EOF'
[supervisord]
user=root
nodaemon=true
logfile=/dev/stdout
logfile_maxbytes=0
[program:php-fpm]
command=php-fpm82 -F
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
[program:nginx]
command=nginx -g "daemon off;"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
EOF

# 3. APP (REAL GOOGLE TELEMETRY)
RUN cat > /var/www/localhost/htdocs/index.php <<'EOF'
<?php
session_start();
$log = 'registry.json';
$max = 99;
if(!file_exists($log)) { file_put_contents($log, json_encode(['today'=>0,'date'=>date('Y-m-d'),'blocked'=>false])); }
$reg = json_decode(file_get_contents($log), true);
if($reg['date'] != date('Y-m-d')) { $reg = ['today'=>0,'date'=>date('Y-m-d'),'blocked'=>false]; }

// FUNCTION TO CHECK ACTUAL GOOGLE STATUS
function check_google() {
    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://smtp.gmail.com:465', $e, $s, 3, STREAM_CLIENT_CONNECT, $ctx);
    if(!$sock) return false;
    fwrite($sock, "EHLO relay\r\nAUTH LOGIN\r\n".base64_encode('pyypl2005@gmail.com')."\r\n".base64_encode('gnrbyxyyjxyoaljv')."\r\n");
    $res = fread($sock, 1024);
    fclose($sock);
    // If 454 (Throttled) or 554 (Limit) or 535 (Auth fail due to lock)
    if(strpos($res, '454') !== false || strpos($res, '554') !== false) return 'limited';
    if(strpos($res, '235') !== false) return 'ok';
    return 'error';
}

if(isset($_GET['check'])) {
    header('Content-Type: application/json');
    $status = check_google();
    if($status === 'limited') { $reg['blocked'] = true; file_put_contents($log, json_encode($reg)); }
    echo json_encode(['used'=>$reg['today'], 'blocked'=>$reg['blocked']]); exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_GET['ajax'])) {
    header('Content-Type: application/json');
    if($reg['today'] >= $max || $reg['blocked']) { echo json_encode(['status'=>'error','msg'=>'G-LIMIT REACHED']); exit; }
    
    $to=$_POST['to']; $name=$_POST['name']; $sub=$_POST['sub']; $msg=$_POST['msg'];
    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://smtp.gmail.com:465', $e, $s, 5, STREAM_CLIENT_CONNECT, $ctx);
    
    if($sock) {
        fwrite($sock, "EHLO relay\r\nAUTH LOGIN\r\n".base64_encode('pyypl2005@gmail.com')."\r\n".base64_encode('gnrbyxyyjxyoaljv')."\r\n");
        $r = fread($sock, 1024);
        if(strpos($r, '454') !== false || strpos($r, '554') !== false) {
            $reg['blocked'] = true; file_put_contents($log, json_encode($reg));
            echo json_encode(['status'=>'error','msg'=>'GOOGLE BLOCKED']); exit;
        }
        fwrite($sock, "MAIL FROM: <pyypl2005@gmail.com>\r\nRCPT TO: <$to>\r\nDATA\r\nFrom: $name <v@q.io>\r\nSubject: $sub\r\nContent-Type: text/html\r\n\r\n$msg\r\n.\r\nQUIT\r\n");
        fclose($sock);
        $reg['today']++; file_put_contents($log, json_encode($reg));
        echo json_encode(['status'=>'success','used'=>$reg['today']]);
    } else { echo json_encode(['status'=>'error','msg'=>'OFFLINE']); }
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>MASTERSYNC</title>
    <style>
        body { background: #000; color: #fff; font-family: sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
        .card { width: 92%; max-width: 400px; background: #0a0a0a; padding: 25px; border-radius: 24px; border: 1px solid #1a1a1a; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .badge { font-size: 11px; padding: 4px 10px; border-radius: 6px; font-weight: bold; border: 1px solid #38bdf8; color: #38bdf8; }
        input, textarea { width: 100%; padding: 15px; margin-bottom: 12px; background: #111; border: 1px solid #222; border-radius: 12px; color: #fff; font-size: 16px; outline: none; }
        button { width: 100%; padding: 16px; background: #fff; color: #000; border: none; border-radius: 12px; font-weight: 900; cursor: pointer; }
        #toast { position: fixed; top: 15px; padding: 12px 20px; border-radius: 8px; display: none; z-index: 100; font-weight: bold; }
    </style>
</head>
<body>
    <div id="toast"></div>
    <div class="card">
        <div class="header">
            <h3>MASTERSYNC</h3>
            <div class="badge">OFFICIAL: <span id="rem">--</span>/99</div>
        </div>
        <form id="f">
            <input type="text" name="name" placeholder="FROM NAME" required>
            <input type="email" name="to" placeholder="TO EMAIL" required>
            <input type="text" name="sub" placeholder="SUBJECT" required>
            <textarea name="msg" placeholder="HTML MESSAGE" rows="5" required></textarea>
            <button type="submit" id="b">SEND MAIL</button>
        </form>
    </div>
    <script>
        const f = document.getElementById('f'), b = document.getElementById('b'), r = document.getElementById('rem'), t = document.getElementById('toast');
        async function sync() {
            const res = await fetch('?check=1');
            const d = await res.json();
            r.innerText = d.blocked ? '0' : (99 - d.used);
        }
        f.onsubmit = async (e) => {
            e.preventDefault(); b.disabled = true; b.innerText = 'PROCESING...';
            const res = await fetch('?ajax=1', { method: 'POST', body: new FormData(f) });
            const d = await res.json();
            if(d.status === 'success') { show('SENT', '#22c55e'); f.reset(); sync(); } 
            else { show(d.msg, '#ef4444'); sync(); }
            b.disabled = false; b.innerText = 'SEND MAIL';
        };
        function show(txt, c) { t.innerText = txt; t.style.background = c; t.style.display = 'block'; setTimeout(()=>t.style.display='none', 2500); }
        sync();
    </script>
</body>
</html>
EOF

RUN touch /var/www/localhost/htdocs/registry.json && chmod -R 777 /var/www/localhost/htdocs
EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
