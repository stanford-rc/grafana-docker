#!/bin/bash

_grafana_version=$1

if [ "$_grafana_version" != "" ]; then
	echo "Building version ${_grafana_version}"
	docker build \
		--build-arg DOWNLOAD_URL=https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_${_grafana_version}_amd64.deb \
		--tag "grafana-oak:${_grafana_version}" \
		--no-cache=true .
	docker tag grafana/grafana:${_grafana_version} grafana/grafana:latest

else
	echo "Building latest for master"
	docker build \
		--build-arg DOWNLOAD_URL=https://s3-us-west-2.amazonaws.com/grafana-releases/master/grafana_latest_amd64.deb \
		--tag "grafana-oak:master" \
		--no-cache=true .
fi
