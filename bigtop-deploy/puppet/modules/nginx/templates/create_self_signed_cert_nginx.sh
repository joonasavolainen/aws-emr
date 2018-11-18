sudo openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/certs/nginx.key -out /etc/ssl/certs/nginx.crt -config /etc/nginx/self_signed_cert_nginx.conf
