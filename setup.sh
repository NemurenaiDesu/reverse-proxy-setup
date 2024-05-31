#!/bin/bash

echo ""
echo "Installing nginx HTTP server... "
echo ""
if apt -y install nginx; then
  echo ""
  echo "Nginx installed successfully."
  echo ""
else
  echo ""
  echo "Error installing Nginx HTTP server"
  echo ""
  exit 1
fi

read -p "Enter the destination IP address: " serverip

echo -n "Creating backup of nginx.conf... "
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak && echo "OK. Backup file: /etc/nginx/nginx.conf.bak"

echo -n "Writing new nginx configuration... "
if cat << EOF > /etc/nginx/nginx.conf

user www-data;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

worker_processes 1;
worker_rlimit_nofile 512;

events {
	worker_connections 8192;
	multi_accept       on;
	use                epoll;
}

http {
	server_names_hash_bucket_size 128;
	server_names_hash_max_size 8192;

	client_max_body_size 2048M;

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	server_tokens off;

	keepalive_timeout 15;
	keepalive_requests 1000;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	log_not_found off;
	access_log off;
	error_log on;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	gzip off;

	server {
		listen 80 default_server;
		listen [::]:80 default_server;

		server_name _;

		location / {
			proxy_pass http://$serverip;
			proxy_redirect off;
			proxy_buffering off;

			proxy_set_header Host \$http_host;
			proxy_set_header X-Real-IP \$proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Proto \$scheme;

			proxy_read_timeout 5;
			proxy_connect_timeout 5;
		}
	}
}
EOF

then
    echo " OK"
else
    echo ""
    echo "Something went wrong"
    exit 1
fi


echo -n "Restarting nginx..."
if systemctl restart nginx; then
    echo " OK"
    echo ""
    echo "ReverseProxy configured successfully"
else
    echo ""
    echo "Something went wrong"
    echo ""
    systemctl status nginx
    exit 1
fi
