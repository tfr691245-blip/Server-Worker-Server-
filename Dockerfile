FROM alpine:3.19

# 1. CORE INSTALL
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    php82-session php82-curl \
    tzdata supervisor && mkdir -p /run/nginx /var/www/localhost/htdocs /var/log/supervisor

# 2. CONFIGS
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

# 3. APP (Used/99 Logic + HTML Preview)
RUN cat > /var/www/localhost/htdocs/index.php <<'EOF'
<?php
$log = '/tmp/registry.json';
$limit = 99;
if(!file_exists($log)) { file_put_contents($log, json_encode(['used'=>0,'ts'=>time()])); }
$reg = json_decode(file_get_contents($log), true);
if(time() - $reg['ts'] > 86400) { $reg = ['used'=>0,'ts'=>time()]; }

function get_auth() {
    $ctx = stream_context_create(['ssl'=>['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://smtp.gmail.com:465', $e, $s, 4, STREAM_CLIENT_CONNECT, $ctx);
    if(!$sock) return 'OFFLINE';
    fgets($sock, 512); fwrite($sock, "EHLO gmail.com\r\n");
    while($line = fgets($sock, 512)) { if(substr($line,3,1) == ' ') break; }
    fwrite($sock, "AUTH LOGIN\r\n"); fgets($sock, 512);
    fwrite($sock, base64_encode('pyypl2005@gmail.com')."\r\n"); fgets($sock, 512);
    fwrite($sock, base64_encode('gnrbyxyyjxyoaljv')."\r\n");
    $res = fgets($sock, 512);
    fwrite($sock, "QUIT\r\n"); fclose($sock);
    return (strpos($res, '235') !== false) ? 'READY' : 'AUTH_FAIL';
}

if(isset($_GET['status'])) {
    header('Content-Type: application/json');
    echo json_encode(['status'=>get_auth(), 'used'=>$reg['used'], 'limit'=>$limit]); exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_GET['ajax'])) {
    header('Content-Type: application/json');
    $to=$_POST['to']; $name=$_POST['name']; $sub=$_POST['sub']; $msg=$_POST['msg'];
    $ctx = stream_context_create(['ssl'=>['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://smtp.gmail.com:465', $e, $s, 5, STREAM_CLIENT_CONNECT, $ctx);
    if($sock) {
        fgets($sock, 512); fwrite($sock, "EHLO gmail.com\r\n");
        while($line = fgets($sock, 512)) { if(substr($line,3,1) == ' ') break; }
        fwrite($sock, "AUTH LOGIN\r\n"); fgets($sock, 512);
        fwrite($sock, base64_encode('pyypl2005@gmail.com')."\r\n"); fgets($sock, 512);
        fwrite($sock, base64_encode('gnrbyxyyjxyoaljv')."\r\n");
        if(strpos(fgets($sock, 512), '235') !== false) {
            fwrite($sock, "MAIL FROM: <pyypl2005@gmail.com>\r\n"); fgets($sock, 512);
            fwrite($sock, "RCPT TO: <$to>\r\n"); fgets($sock, 512);
            fwrite($sock, "DATA\r\n"); fgets($sock, 512);
            $h = "From: $name <v@q.io>\r\nTo: $to\r\nSubject: $sub\r\nMIME-Version: 1.0\r\nContent-Type: text/html\r\n\r\n";
            fwrite($sock, $h . $msg . "\r\n.\r\nQUIT\r\n");
            $reg['used']++; file_put_contents($log, json_encode($reg));
            echo json_encode(['status'=>'success']);
        } else { echo json_encode(['status'=>'error','msg'=>'DENIED']); }
        fclose($sock);
    } exit;
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
        .card { width: 90%; max-width: 420px; background: #080808; padding: 25px; border-radius: 20px; border: 1px solid #1a1a1a; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .badge { font-size: 11px; padding: 6px 14px; border-radius: 8px; font-weight: 900; border: 1px solid #38bdf8; color: #38bdf8; }
        input, textarea { width: 100%; padding: 14px; margin-bottom: 12px; background: #111; border: 1px solid #222; border-radius: 12px; color: #fff; font-size: 15px; outline: none; box-sizing: border-box; }
        button { width: 100%; padding: 16px; background: #fff; color: #000; border: none; border-radius: 12px; font-weight: 900; cursor: pointer; }
        #preview { background: #111; border-radius: 12px; padding: 10px; margin-bottom: 12px; min-height: 50px; font-size: 12px; border: 1px dashed #333; overflow: hidden; }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <h3 style="margin:0;letter-spacing:1px;">MASTERSYNC</h3>
            <div class="badge" id="stat">0/99</div>
        </div>
        <form id="f">
            <input type="text" name="name" placeholder="SENDER NAME" required>
            <input type="email" name="to" placeholder="RECIPIENT EMAIL" required>
            <input type="text" name="sub" placeholder="SUBJECT" required>
            <textarea id="m" name="msg" placeholder="HTML PAYLOAD" rows="5" required></textarea>
            <div id="preview">PREVIEW: (Empty)</div>
            <button type="submit" id="b">EXECUTE SEND</button>
        </form>
    </div>
    <script>
        const f=document.getElementById('f'), b=document.getElementById('b'), s=document.getElementById('stat'), m=document.getElementById('m'), p=document.getElementById('preview');
        async function check() {
            try {
                const res = await fetch('?status=1');
                const d = await res.json();
                s.innerText = d.used + '/' + d.limit;
                s.style.color = s.style.borderColor = (d.status==='READY') ? '#38bdf8' : '#ef4444';
            } catch(e) { s.innerText = 'OFFLINE'; }
        }
        m.oninput = () => { p.innerHTML = m.value || 'PREVIEW: (Empty)'; };
        f.onsubmit = async (e) => {
            e.preventDefault(); b.disabled = true; b.innerText = 'WAIT...';
            const res = await fetch('?ajax=1', { method: 'POST', body: new FormData(f) });
            const d = await res.json();
            alert(d.status === 'success' ? 'SENT' : d.msg);
            if(d.status === 'success') f.reset();
            b.disabled = false; b.innerText = 'EXECUTE SEND';
            check();
        };
        check();
    </script>
</body>
</html>
EOF

RUN chmod -R 777 /tmp
EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
