# begin _app_stream
upstream app_stream {
  server 127.0.0.1:3000 fail_timeout=10s;
}
# end _app_stream

# begin _map
map \$http_upgrade \$connection_upgrade {
  default upgrade;
  ''      close;
}
# end _map


server {
  listen      80 deferred;
  listen      [::]:80 deferred;
  server_name mawidabp.com *.mawidabp.com;
  return      301 https://\$host\$request_uri;

}


server {
  #listen 443 deferred ssl http2;
  #listen [::]:443 deferred ssl http2;

  # begin _rackserver
  server_name mawidabp.com *.mawidabp.com;

  client_body_in_file_only clean;
  client_body_buffer_size 32K;
  client_max_body_size 4G;

  keepalive_timeout 5;

  server_tokens off;

  root $mawidabp_path/current/public;
  # end _rackserver

  # begin _ssl
  # TL;DR: Go to https://wiki.mozilla.org/Security/Server_Side_TLS often =)
  #ssl_certificate         /etc/ssl/certs/mawidabp.com.bundle-crt;
  #ssl_certificate_key     /etc/ssl/private/mawidabp.com.key;
  #ssl_trusted_certificate /etc/ssl/certs/mawidabp.com.bundle-crt;

  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;
  ssl_ciphers \"ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS\";
  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:50m;
  ssl_session_tickets off;
  ssl_stapling on;
  ssl_stapling_verify on;
  ssl_ecdh_curve prime256v1:secp384r1:secp521r1;
  #ssl_dhparam /etc/nginx/dhparams.pem;

  resolver 1.1.1.1 1.0.0.1 [2606:4700:4700::1111] [2606:4700:4700::1001] valid=300s;
  resolver_timeout 10s;

  add_header X-Content-Type-Options nosniff always;
  add_header X-Frame-Options SAMEORIGIN always;
  # end _ssl

  # begin _rackapp
  try_files \$uri/index.html \$uri.html \$uri @app;

  location /private_files/ {
    alias $mawidabp_path/current/private/;
    internal;
  }

  location /cable {
    proxy_http_version 1.1;

    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Host \$http_host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;

    proxy_pass http://app_stream/cable;
  }

  location @app {
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    #cambiar esta linea
    proxy_set_header X-Accel-Mapping \"$mawidabp_path/current/private/=/private_files/\";
    proxy_set_header Host \$http_host;
    proxy_redirect off;
    # Extra app directives


    proxy_pass http://app_stream;
  }

  location ~ /\.well-known/acme-challenge {
    root /var/www;
  }

  location ~ /\. {
    access_log off;
    log_not_found off;
    deny all;
  }

  error_page 500 502 503 504 /500.html;
  location = /500.html {
    root $mawidabp_path/current/public;
  }
  # end _rackapp
}
