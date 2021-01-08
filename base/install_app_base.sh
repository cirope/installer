#!/bin/bash
set -eu

#URLS
repo_nginx=http://nginx.org/packages/centos/7/x86_64/RPMS
repo_redis_ib01=https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/j
repo_redis=https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/r
repo_node=https://rpm.nodesource.com/pub_14.x/el/7/x86_64

dir=$(cd "$(dirname "$0")" && pwd)
dir_conf=$dir/config_files
dir_services=$dir/services
dir_nginx=/etc/nginx

echo "Instalación Paquete NGINX"
rpm -ivh $repo_nginx/nginx-1.18.0-1.el7.ngx.x86_64.rpm

echo creamos directorios sites
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

echo "Arrancamos y habilitamos nginx"
systemctl start nginx
systemctl enable nginx


echo "Copiamos archivo de configuración Nginx"
/bin/cat $dir_conf/nginx.conf > $dir_nginx/nginx.conf
cp $dir_conf/mawidabp.com $dir_nginx/sites-available/

echo "Creamos enlace simbolico"
ln -s $dir_nginx/sites-available/mawidabp.com $dir_nginx/sites-enabled/mawidabp.com

echo "Recargamos nginx"
systemctl restart nginx

echo "Instalamos Redis"
rpm -ivh $repo_redis_ib01/jemalloc-3.6.0-1.el7.x86_64.rpm
rpm -ivh $repo_redis_ib01/jemalloc-devel-3.6.0-1.el7.x86_64.rpm
rpm -ivh $repo_redis/redis-3.2.12-2.el7.x86_64.rpm

systemctl start redis
systemctl enable redis

echo "Instalamos nodejs"
rpm -ivh $repo_node/nodejs-14.15.1-1nodesource.x86_64.rpm

echo "Instalamos ImageMagick"
yum -y install ImageMagick

echo "Instalamos libyaml"
yum -y install libyaml

echo "Crear usuario deployer"
adduser deployer -G nginx
passwd deployer

echo "Copiamos archivos de sudoers"
cp $dir_conf/sudoers_deployer /etc/sudoers.d/deployer

echo "Creamos directorios"
mkdir -p /var/www/mawidabp.com/
chown -R deployer: /var/www/

echo "Exportamos RBENV"
su deployer -c 'echo export PATH="$HOME/.rbenv/bin:$PATH" >> ~/.bashrc'
#su deployer -c 'echo eval "$(rbenv init -)"'


echo "Copiamos servicios"
cp $dir_services/*.service /usr/lib/systemd/system/

echo "Reemplazamos archivo de configuración selinux"
/bin/cat $dir_services/selinux_config > /etc/selinux/config

echo "Finalizado por favor reinicie S.O."
