
export RAILS_ENV=production

file=mawidabp_bundle.tar.gz
dest=/var/www/mawidabp.com
user=deployer

echo $logo | base64 -di | cat

echo 'Iniciando instalación, por favor espere...'

echo $build | base64 -di > $file

tar xfz $file
rm $file

mkdir -p $dest/shared/{config,log,private,tmp/pids}

rm -rf $dest/current_bak

if [ -d $dest/current ]; then
  mv $dest/current $dest/current_bak
fi

mv mawidabp $dest/current

for dir in log private tmp/pids; do
  rm -rf $dest/current/$dir
  ln -s $dest/shared/$dir $dest/current/$dir
done

if [ ! -f $dest/shared/config/application.yml ]; then
  echo $config | base64 -di > $dest/shared/config/application.yml
fi

ln -s $dest/shared/config/application.yml $dest/current/config/application.yml

chown -R $user: $dest

cd $dest/current

bin/rails db:migrate -q
bin/rails db:seed -q
bin/rails db:update -q

sudo systemctl reload-or-restart unicorn
sudo systemctl restart sidekiq

cd ~

echo 'Instalación finalizada'