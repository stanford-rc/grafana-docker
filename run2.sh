#!/bin/bash

: "${GF_SECURITY_ADMIN_PASSWORD:=admin}"

echo 'Starting Grafana...'
/run.sh "$@" &
ConfigureGrafana() {
  curl "http://admin:${GF_SECURITY_ADMIN_PASSWORD}@localhost:3000/api/orgs/1" \
    -X PUT \
    -H 'Content-Type: application/json;charset=UTF-8' \
    --data-binary \
    '{"name":"Stanford"}'
  curl "http://admin:${GF_SECURITY_ADMIN_PASSWORD}@localhost:3000/api/datasources" \
    -X POST \
    -H 'Content-Type: application/json;charset=UTF-8' \
    --data-binary \
    '{"name":"SRCC-Graphite","type":"graphite","url":"http://192.168.4.1:3300","access":"proxy","isDefault":true}'
}
until ConfigureGrafana; do
  echo 'Configuring Grafana...'
  sleep 1
done
echo 'Done!'
wait
