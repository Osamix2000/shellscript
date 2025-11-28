#/bin/bash

cd ~
yum -y install gcc gcc-c++ make pcre pcre-devel zlib zlib-devel openssl openssl-devel git wget

# 適宜nginxのバージョンを確認
# https://nginx.org/download
wget https://nginx.org/download/nginx-1.28.0.tar.gz
tar -xvf nginx-1.28.0.tar.gz
cd nginx-1.28.0

git clone https://github.com/arut/nginx-rtmp-module.git
./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module --with-http_v2_module --with-stream --with-stream_ssl_module --add-module=./nginx-rtmp-module
make
make install
ln -s /usr/local/nginx/conf /etc/nginx
ln -s /usr/local/nginx/sbin/nginx /bin/nginx
useradd --system --no-create-home --shell /sbin/nologin nginx
mkdir -p /var/log/nginx
chown nginx:nginx /var/log/nginx
cd ~
rm -rf nginx*

cat <<'EOF' | tee /usr/lib/systemd/system/nginx.service > /dev/null
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPost=/bin/sleep 1
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' | tee /usr/local/nginx/conf/nginx.conf > /dev/null
user nginx;
worker_processes  auto;
error_log /var/log/nginx/error.log;

pid        /run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include mime.types;
    include /usr/local/nginx/conf/conf.d/*.conf;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;
}
EOF

systemctl enable nginx
systemctl restart nginx
systemctl status nginx

nginx -V
