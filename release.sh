#!/usr/bin/env bash

set -eu

while getopts ":b:i:" opt; do
  case $opt in
    b)  branch="$OPTARG"                                           ;;
    i)  image="$OPTARG"                                            ;;
    :)  echo "Option -$OPTARG requires an argument." >&2 && exit 1 ;;
    \?) echo "Invalid option -$OPTARG"               >&2 && exit 1 ;;
  esac
done

dir=$(cd "$(dirname "$0")" && pwd)
branch=${branch:-master}
image=${image:-centos7}
workdir=/root

rm -rf dist/*

docker build . -f images/Dockerfile.$image -t mawidabp/builder
docker run -it --rm --volume $dir/dist:$workdir/dist mawidabp/builder $workdir/build/build.sh $branch
