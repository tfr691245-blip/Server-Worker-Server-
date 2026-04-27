FROM alpine:3.19

# 1. Install Performance Stack
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs /var/lib/mail-tracker \
    && chown -R nginx:nginx /var/lib/mail-tracker

# 2. Optimized Nginx Config (Instant Pass-through)
RUN echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_keep_conn on; \
    } \
}' > /etc/nginx/http.d/default.conf

# 3. Create the AIO Web UI + Direct Engine Script
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
// --- CORE CONFIG ---
$smtp_host = 'ssl://142.251.10.108'; // Fast Direct IP
$smtp_port = 465;
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$alias = 'verified@elite.qzz.io';
$limit_file = '/var/lib/mail-tracker/count.json';
$daily_max = 2000;

// Load Tracker
$data = file_exists($limit_file) ? json_decode(file_get_contents($limit_file), true) : ['date' => date('Y-m-d'), 'count' => 0];
if ($data['date'] !== date('Y-m-d')) { $data = ['date' => date('Y-m-d'), 'count' => 0]; }

$status = "SYSTEM ONLINE";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST['to'];
    $name = $_POST['name'];
    $sub = $_POST['sub'];
    $msg = $_POST['msg'];

    $headers = [
        "From: $name <$alias>",
        "To: $to",
        "Subject: $sub",
        "MIME-Version: 1.0",
        "Content-Type: text/html; charset=UTF-8"
    ];

    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client($smtp_host.':'.$smtp_port, $errno, $errstr, 5, STREAM_CLIENT_CONNECT, $ctx);

    if ($sock) {
        fread($sock, 512);
        fwrite($sock, "EHLO elite.qzz.io\r\n"); fread($sock, 512);
        fwrite($sock, "AUTH LOGIN\r\n"); fread($sock, 512);
        fwrite($sock, base64_encode($user)."\r\n"); fread($sock, 512);
        fwrite($sock, base64_encode($pass)."\r\n"); fread($sock, 512);
        fwrite($sock, "MAIL FROM: <$user>\r\n"); fread($sock, 512);
        fwrite($sock, "RCPT TO: <$to>\r\n"); fread($sock, 512);
        fwrite($sock, "DATA\r\n"); fread($sock, 512);
        fwrite($sock, implode("\r\n", $headers) . "\r\n\r\n" . $msg . "\r\n.\r\n");
        fwrite($sock, "QUIT\r\n");
        fclose($sock);
        
        $data['count']++;
        file_put_contents($limit_file, json_encode($data));
        $status = "SENT SUCCESS";
    } else { $status = "CONNECTION TIMEOUT"; }
}
?>
<!DOCTYPE html><html><body style="background:#05070a;color:#00ff41;font-family:monospace;padding:20px;display:flex;justify-content:center;">
    <div style="border:1px solid #00ff41;padding:20px;width:100%;max-width:400px;background:#0a0c10;">
        <h3 style="margin:0 0 10px 0;text-align:center;">APEX STEALTH RELAY</h3>
        
        <div style="background:#000;border:1px solid #333;padding:10px;margin-bottom:20px;font-size:12px;">
            LIMIT: <?php echo $data['count']; ?> / <?php echo $daily_max; ?> [<?php echo round(($data['count']/$daily_max)*100, 1); ?>%]
            <div style="width:100%;height:3px;background:#222;margin-top:5px;"><div style="width:<?php echo ($data['count']/$daily_max)*100; ?>%;height:100%;background:#00ff41;"></div></div>
        </div>

        <form method="POST">
            <input name="name" placeholder="Sender Name" required style="width:100%;background:#000;border:1px solid #333;color:#fff;padding:10px;margin-bottom:10px;box-sizing:border-box;">
            <input name="to" placeholder="Recipient Email" required style="width:100%;background:#000;border:1px solid #333;color:#fff;padding:10px;margin-bottom:10px;box-sizing:border-box;">
            <input name="sub" placeholder="Subject" required style="width:100%;background:#000;border:1px solid #333;color:#fff;padding:10px;margin-bottom:10px;box-sizing:border-box;">
            <textarea name="msg" placeholder="HTML Message" style="width:100%;background:#000;border:1px solid #333;color:#fff;padding:10px;height:100px;margin-bottom:10px;box-sizing:border-box;"></textarea>
            <button style="width:100%;padding:12px;background:#00ff41;color:#000;font-weight:bold;border:none;cursor:pointer;text-transform:uppercase;">Fire Engine</button>
        </form>
        <div style="margin-top:15px;font-size:11px;text-align:center;color:#888;">STATUS: <span style="color:#fff"><?php echo $status; ?></span></div>
    </div>
</body></html>
EOF

# 4. Set Permissions
RUN chown -R nginx:nginx /var/www/localhost/htdocs

EXPOSE 80
# 5. Fast Launch
CMD php-fpm82 && nginx -g "daemon off;"
