#!/usr/bin/env bash

set -eu

branch=${1-master}
dir=$(cd "$(dirname "$0")" && pwd)
dest=mawidabp
build=mawidabp.tar.gz
rbenv=rbenv.tar.gz
dist=../dist
installer=mawidabp.sh
repo=https://github.com/cirope/mawidabp

cd $dir

rm -rf $dest
rm -rf $build

git clone --depth=1 --single-branch --branch $branch $repo $dest

cd $dest
rm LICENSE.md README.md Vagrantfile
git rev-parse HEAD > REVISION

rm -rf .git

# On CentOS: bundle config build.pg --with-pg-config=/usr/pgsql-12/bin/pg_config

bundle config set --local deployment 'true' &&
  bundle install                            &&
  bundle exec rake help:install             &&
  bundle exec rake help:generate

cp config/application.yml.example config/application.yml

bundle exec rails assets:precompile DB_ADAPTER=nulldb

rm config/application.yml
rm -rf config/jekyll/.jekyll-cache

cd ..

tar cvfz $build $dest/
cd $HOME && tar cvfz $dir/$rbenv .rbenv && cd $dir

rm -rf $dest

echo '#!/usr/bin/env bash' > $installer
echo 'set -eu' >> $installer

echo "build='$(base64 $build)'"           >> $installer
echo "rbenv='$(base64 $rbenv)'"           >> $installer
echo "config='$(base64 application.yml)'" >> $installer
echo "logo='$(base64 logo.txt)'"          >> $installer

cat template.sh >> $installer

chmod +x $installer
gzip -9 $installer

mv $installer.gz $dist

rm $build
rm $rbenv
