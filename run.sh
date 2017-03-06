#!/bin/bash -e

: "${GF_PATHS_DATA:=/var/lib/grafana}"
: "${GF_PATHS_LOGS:=/var/log/grafana}"
: "${GF_PATHS_PLUGINS:=/var/lib/grafana/plugins}"

chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_LOGS"
chown -R grafana:grafana /etc/grafana

if [ ! -z ${GF_AWS_PROFILES+x} ]; then
    mkdir -p ~grafana/.aws/
    touch ~grafana/.aws/credentials

    for profile in ${GF_AWS_PROFILES}; do
        access_key_varname="GF_AWS_${profile}_ACCESS_KEY_ID"
        secret_key_varname="GF_AWS_${profile}_SECRET_ACCESS_KEY"
        region_varname="GF_AWS_${profile}_REGION"

        if [ ! -z "${!access_key_varname}" -a ! -z "${!secret_key_varname}" ]; then
            echo "[${profile}]" >> ~grafana/.aws/credentials
            echo "aws_access_key_id = ${!access_key_varname}" >> ~grafana/.aws/credentials
            echo "aws_secret_access_key = ${!secret_key_varname}" >> ~grafana/.aws/credentials
            if [ ! -z "${!region_varname}" ]; then
                echo "region = ${!region_varname}" >> ~grafana/.aws/credentials
            fi
        fi
    done

    chown grafana:grafana -R ~grafana/.aws
    chmod 600 ~grafana/.aws/credentials
fi

if [ ! -z "${GF_INSTALL_PLUGINS}" ]; then
  OLDIFS=$IFS
  IFS=','
  for plugin in ${GF_INSTALL_PLUGINS}; do
    IFS=$OLDIFS
    grafana-cli  --pluginsDir "${GF_PATHS_PLUGINS}" plugins install ${plugin}
  done
fi

# Oak config
cat >/etc/grafana/grafana.ini << EOF
[auth.anonymous]
enabled = false
org_name = Stanford

[users]
allow_sign_up = false
allow_org_create = false
auto_assign_org = true
auto_assign_org_role = Viewer

[auth.basic]
enabled = true

[auth.proxy]
enabled = true
header_name = X-WEBAUTH-USER
header_property = username
auto_sign_up = true

[dashboards.json]
enabled = true
path = /var/lib/grafana/dashboards
EOF

# Home dashboard
sed "s/GROUP_PLACEHOLDER/$OAK_GROUP/g" /robinhood.json > /usr/share/grafana/public/dashboards/home.json

# Additional dashboards
mkdir -p /var/lib/grafana/dashboards
cp -f /lustre.json /var/lib/grafana/dashboards/lustre.json
chown -R grafana:grafana /var/lib/grafana/dashboards

exec gosu grafana /usr/sbin/grafana-server      \
  --homepath=/usr/share/grafana                 \
  --config=/etc/grafana/grafana.ini             \
  cfg:default.paths.data="$GF_PATHS_DATA"       \
  cfg:default.paths.logs="$GF_PATHS_LOGS"       \
  cfg:default.paths.plugins="$GF_PATHS_PLUGINS" \
  "$@"
