#!/bin/bash
set -eu

usage() {
  echo "Usage: $0 [ -u USERNAME ] [ -p PATH DIRECTORY MAWIDABP ] [-g GROUP]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

while getopts u:p:g: option; do
  case ${option} in
    u) user=${OPTARG};;
    p) mawidabp_path=${OPTARG};;
    p) group=${OPTARG};;
    :) echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    *)
      exit_abnormal;;
    esac
  done

user=${user-deployer}
mawidabp_path=${mawidabp_path-/var/www/mawidabp.com}
group=${group-nginx}
dir=$(cd "$(dirname "$0")" && pwd)
dir_conf=$dir/config_files
dir_templates=$dir/templates
dir_services=$dir/services
dir_nginx=/etc/nginx

#Create config files
eval "echo \"$(cat $dir_templates/nginx.conf)\" > $dir_conf/nginx.conf"
eval "echo \"$(cat $dir_templates/mawidabp.com)\" > $dir_conf/mawidabp.com"
eval "echo \"$(cat $dir_templates/sudoers)\" > $dir_conf/sudoers"
eval "echo \"$(cat $dir_templates/sidekiq.service)\" > $dir_services/sidekiq.service"
eval "echo \"$(cat $dir_templates/unicorn.service)\" > $dir_services/unicorn.service"

#URLS
repo_nginx=http://nginx.org/packages/centos/7/x86_64/RPMS
repo_redis_ib01=https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/j
repo_redis=https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/r
repo_node=https://rpm.nodesource.com/pub_14.x/el/7/x86_64

#Install NGINX
rpm -iUvh --replacepkgs $repo_nginx/nginx-1.18.0-1.el7.ngx.x86_64.rpm

#Create sites folders
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

#Start and enable NGINX
systemctl start nginx
systemctl enable nginx

#Copy config files to NGINX
/bin/cat $dir_conf/nginx.conf > $dir_nginx/nginx.conf
cp $dir_conf/mawidabp.com $dir_nginx/sites-available/

#Create symbolic link
if [ ! "$(ls -A /etc/nginx/sites-enabled/mawidabp.com)" ]
then
  ln -s $dir_nginx/sites-available/mawidabp.com $dir_nginx/sites-enabled/mawidabp.com
fi

#Restart NGINX
systemctl restart nginx

#Install REDIS
rpm -iUvh --replacepkgs $repo_redis_ib01/jemalloc-3.6.0-1.el7.x86_64.rpm
rpm -iUvh --replacepkgs $repo_redis_ib01/jemalloc-devel-3.6.0-1.el7.x86_64.rpm
rpm -iUvh --replacepkgs $repo_redis/redis-3.2.12-2.el7.x86_64.rpm

#Copy config file to REDIS
/bin/cat $dir_conf/redis.conf > /etc/redis.conf

#Enable REDIS
systemctl enable redis
systemctl start redis

#Install NODEJS
rpm -iUvh --replacepkgs $repo_node/nodejs-14.15.1-1nodesource.x86_64.rpm

#Install IMAGEMAGICK
yum -y install ImageMagick

#Install LIBYAML
yum -y install libyaml

#Crearte user
if ! id -u $user >/dev/null 2>&1;
then
  adduser $user -G $group
  passwd $user
fi

#Copy sudores files to sudores
cp $dir_conf/sudoers /etc/sudoers.d/$user

#Create folders
mkdir -p $mawidabp_path
chown -R $user: $mawidabp_path

#Export RBENV
su $user -c 'echo export PATH="$HOME/.rbenv/bin:$PATH" >> ~/.bashrc'

#Copy services files to system
cp $dir_services/*.service /usr/lib/systemd/system/

#Replace selinux file
/bin/cat $dir_services/selinux_config > /etc/selinux/config

echo "Finalizado por favor reinicie S.O."
