
export RAILS_ENV=production


while getopts ":u:p:" opt; do
  case $opt in
    p)  path="$OPTARG"                                             ;;
    u)  user="$OPTARG"                                             ;;
    :)  echo "Option -$OPTARG requires an argument." >&2 && exit 1 ;;
    \?) echo "Invalid option -$OPTARG"               >&2 && exit 1 ;;
  esac
done

file=mawidabp_bundle.tar.gz
dest=${path-/var/www/mawidabp.com}
user=${user-deployer}

echo $logo | base64 -di | cat

echo 'Iniciando instalación, por favor espere...'

cd $HOME
rm -rf .rbenv
echo $rbenv | base64 -di | tar xz
eval "$($HOME/.rbenv/bin/rbenv init -)"
rbenv global $(rbenv versions --bare)

echo $build | base64 -di | tar xz

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
