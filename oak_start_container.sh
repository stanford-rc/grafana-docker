#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
fi

group=$1
port=$2

secret=$(openssl rand -base64 32)

docker run \
    -d \
    -v /var/lib/grafana \
    --name grafana-data-oak-$group \
    busybox:latest

docker run \
    -d \
    --name=grafana-oak-$1 \
    -p $port:3000 \
    --net=dockernet \
    --volumes-from grafana-data-oak-$group \
    -e "OAK_GROUP=oak_$group" \
    -e "GF_SERVER_ROOT_URL=https://srcc-lookout.stanford.edu/oak/$group" \
    -e "GF_SECURITY_ADMIN_PASSWORD=$secret" \
    grafana-oak:master
