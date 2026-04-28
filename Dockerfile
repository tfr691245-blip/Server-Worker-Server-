FROM alpine:3.19

# 1. SYSTEM INSTALL
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    php82-session php82-curl \
    tzdata supervisor && mkdir -p /run/nginx /var/www/localhost/htdocs /var/log/supervisor

# 2. SERVER CONFIGS
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

# 3. APP LOGIC (Force Direct SSL Handshake)
RUN cat > /var/www/localhost/htdocs/index.php <<'EOF'
<?php
session_start();
$log = 'registry.json';
$max = 99;
if(!file_exists($log)) { file_put_contents($log, json_encode(['today'=>0,'date'=>date('Y-m-d')])); }
$reg = json_decode(file_get_contents($log), true);
if($reg['date'] != date('Y-m-d')) { $reg = ['today'=>0,'date'=>date('Y-m-d')]; }

function get_google_auth() {
    $ctx = stream_context_create(['ssl'=>['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://smtp.gmail.com:465', $e, $s, 4, STREAM_CLIENT_CONNECT, $ctx);
    if(!$sock) return 'OFFLINE';
    
    fgets($sock, 512); // Banner
    fwrite($sock, "EHLO gmail.com\r\n");
    while($line = fgets($sock, 512)) { if(substr($line,3,1) == ' ') break; }
    
    fwrite($sock, "AUTH LOGIN\r\n");
    fgets($sock, 512);
    fwrite($sock, base64_encode('pyypl2005@gmail.com')."\r\n");
    fgets($sock, 512);
    fwrite($sock, base64_encode('gnrbyxyyjxyoaljv')."\r\n");
    $res = fgets($sock, 512);
    
    fwrite($sock, "QUIT\r\n");
    fclose($sock);
    
    if(strpos($res, '235') !== false) return 'READY';
    if(strpos($res, '454') !== false || strpos($res, '554') !== false) return 'LIMITED';
    return 'AUTH_FAIL';
}

if(isset($_GET['status'])) {
    header('Content-Type: application/json');
    $st = get_google_auth();
    echo json_encode(['status' => $st, 'rem' => ($st == 'READY' ? ($max - $reg['today']) : 0)]); exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_GET['ajax'])) {
    header('Content-Type: application/json');
    $to=$_POST['to']; $name=$_POST['name']; $sub=$_POST['sub']; $msg=$_POST['msg'];
    $ctx = stream_context_create(['ssl'=>['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://smtp.gmail.com:465', $e, $s, 5, STREAM_CLIENT_CONNECT, $ctx);
    
    if($sock) {
        fgets($sock, 512);
        fwrite($sock, "EHLO gmail.com\r\n");
        while($line = fgets($sock, 512)) { if(substr($line,3,1) == ' ') break; }
        fwrite($sock, "AUTH LOGIN\r\n"); fgets($sock, 512);
        fwrite($sock, base64_encode('pyypl2005@gmail.com')."\r\n"); fgets($sock, 512);
        fwrite($sock, base64_encode('gnrbyxyyjxyoaljv')."\r\n");
        $auth = fgets($sock, 512);
        
        if(strpos($auth, '235') !== false) {
            fwrite($sock, "MAIL FROM: <pyypl2005@gmail.com>\r\n"); fgets($sock, 512);
            fwrite($sock, "RCPT TO: <$to>\r\n"); fgets($sock, 512);
            fwrite($sock, "DATA\r\n"); fgets($sock, 512);
            fwrite($sock, "From: $name <v@q.io>\r\nTo: $to\r\nSubject: $sub\r\nContent-Type: text/html\r\n\r\n$msg\r\n.\r\n");
            fgets($sock, 512);
            fwrite($sock, "QUIT\r\n");
            $reg['today']++; file_put_contents($log, json_encode($reg));
            echo json_encode(['status'=>'success']);
        } else { echo json_encode(['status'=>'error', 'msg'=>'GOOGLE_DENIED']); }
        fclose($sock);
    } else { echo json_encode(['status'=>'error', 'msg'=>'CONN_FAIL']); }
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
        .card { width: 90%; max-width: 380px; background: #080808; padding: 25px; border-radius: 20px; border: 1px solid #111; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .badge { font-size: 10px; padding: 5px 12px; border-radius: 6px; font-weight: 800; border: 1px solid #38bdf8; color: #38bdf8; }
        input, textarea { width: 100%; padding: 14px; margin-bottom: 12px; background: #111; border: 1px solid #222; border-radius: 12px; color: #fff; font-size: 15px; outline: none; }
        button { width: 100%; padding: 16px; background: #fff; color: #000; border: none; border-radius: 12px; font-weight: 900; cursor: pointer; }
        #tst { position: fixed; top: 15px; padding: 12px; border-radius: 8px; display: none; font-weight: bold; }
    </style>
</head>
<body>
    <div id="tst"></div>
    <div class="card">
        <div class="header">
            <h3 style="margin:0;font-size:18px;">MASTERSYNC</h3>
            <div class="badge" id="stat">SYNCING...</div>
        </div>
        <form id="f">
            <input type="text" name="name" placeholder="SENDER" required>
            <input type="email" name="to" placeholder="RECIPIENT" required>
            <input type="text" name="sub" placeholder="SUBJECT" required>
            <textarea name="msg" placeholder="HTML PAYLOAD" rows="5" required></textarea>
            <button type="submit" id="b">EXECUTE SEND</button>
        </form>
    </div>
    <script>
        const f=document.getElementById('f'), b=document.getElementById('b'), s=document.getElementById('stat'), t=document.getElementById('tst');
        async function check() {
            try {
                const res = await fetch('?status=1');
                const d = await res.json();
                s.innerText = d.status + ': ' + d.rem;
                s.style.color = s.style.borderColor = (d.status==='READY') ? '#38bdf8' : '#ef4444';
            } catch(e) { s.innerText = 'OFFLINE'; }
        }
        f.onsubmit = async (e) => {
            e.preventDefault(); b.disabled = true; b.innerText = 'WAIT...';
            const res = await fetch('?ajax=1', { method: 'POST', body: new FormData(f) });
            const d = await res.json();
            if(d.status === 'success') { show('SENT', '#22c55e'); f.reset(); check(); } 
            else { show(d.msg, '#ef4444'); check(); }
            b.disabled = false; b.innerText = 'EXECUTE SEND';
        };
        function show(txt, c) { t.innerText = txt; t.style.background = c; t.style.display = 'block'; setTimeout(()=>t.style.display='none', 2500); }
        check();
    </script>
</body>
</html>
EOF

RUN touch /var/www/localhost/htdocs/registry.json && chmod -R 777 /var/www/localhost/htdocs
EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
