#!/bin/bash

set -eu
echo "Instalación de paquetes"
rpm -ivh --replacepkgs http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-5.16.3-297.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-libs-5.16.3-297.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Carp-1.26-244.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Exporter-5.68-3.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-PathTools-3.40-5.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-File-Path-2.09-2.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-File-Temp-0.23.01-3.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Filter-1.49-3.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Getopt-Long-2.40-3.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Pod-Simple-3.28-4.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Scalar-List-Utils-1.27-248.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Socket-2.010-5.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Storable-2.45-3.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Time-HiRes-1.9725-3.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Time-Local-1.2300-2.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-constant-1.27-2.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-threads-1.87-4.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-macros-5.16.3-297.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-threads-shared-1.43-6.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Pod-Usage-1.63-3.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Text-ParseWords-3.29-4.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Encode-2.51-7.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Pod-Escapes-1.04-297.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-podlators-2.5.1-3.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-Pod-Perldoc-3.20-4.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-HTTP-Tiny-0.033-3.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/perl-parent-0.225-244.el7.noarch.rpm 
rpm -ivh --replacepkgs http://mirror.centos.org/centos/7/os/x86_64/Packages/libicu-50.2-4.el7_7.x86_64.rpm 
rpm -iUvh --replacepkgs https://yum.postgresql.org/13/redhat/rhel-7-x86_64/postgresql13-libs-13.1-1PGDG.rhel7.x86_64.rpm
rpm -iUvh --replacepkgs https://yum.postgresql.org/13/redhat/rhel-7-x86_64/postgresql13-13.1-1PGDG.rhel7.x86_64.rpm
rpm -iUvh --replacepkgs https://yum.postgresql.org/13/redhat/rhel-7-x86_64/postgresql13-server-13.1-1PGDG.rhel7.x86_64.rpm
rpm -iUvh --replacepkgs http://mirror.centos.org/centos/7/os/x86_64/Packages/libxslt-1.1.28-6.el7.x86_64.rpm 
yum -y install postgresql-devel 
rpm -ivh --replacepkgs http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libpqxx-4.0.1-1.el7.x86_64.rpm 
rpm -ivh --replacepkgs http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libpqxx-devel-4.0.1-1.el7.x86_64.rpm 
rpm -iUvh --replacepkgs https://yum.postgresql.org/13/redhat/rhel-7-x86_64/postgresql13-contrib-13.1-1PGDG.rhel7.x86_64.rpm

echo "initdb"

/usr/pgsql-13/bin/postgresql-13-setup initdb 


echo "Copiamos archivos de configuración"
dir=$(cd "$(dirname "$0")" && pwd)
dir_conf=$dir/config_files
/bin/cat $dir_conf/postgresql.conf > /var/lib/pgsql/13/data/postgresql.conf
/bin/cat $dir_conf/pg_hba.conf > /var/lib/pgsql/13/data/pg_hba.conf

echo "Arrancamos y habilitamos Postgresql"
systemctl start postgresql-13 
systemctl enable postgresql-13 

echo "Creamos role y base de datos"
su postgres -c "psql -c \"CREATE user mawidabp with PASSWORD 'mawidabp'\""
su postgres -c "psql -c \"ALTER user mawidabp with LOGIN SUPERUSER\""
su postgres -c "psql -c \"CREATE DATABASE mawidabp_production --owner mawidabp\""


echo "OK"
