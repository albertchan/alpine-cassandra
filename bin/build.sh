#! /bin/bash

test -z $1 && echo Usage: 'ops/build.sh <tagging_version>' && exit 1

VERSION=$1

echo "Building alpine-cassandra:$VERSION..."

docker build --build-arg VERSION=$VERSION -t albertc/alpine-cassandra:$VERSION .
docker tag albertc/alpine-cassandra:$VERSION albertc/alpine-cassandra:$VERSION
