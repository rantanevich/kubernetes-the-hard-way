#!/bin/bash
tf_output() {
  terraform -chdir=$BASEDIR/../terraform output -json $1 | jq -r "$2"
}


BASEDIR=$(dirname "$0")

export ETCD_VERSION=${ETCD_VERSION:-3.5.6}
export ETCD_NODES=$(\
  tf_output '' '[.masters_hostname.value, .masters_ipv4.value]
                | transpose
                | map([(.[0]), "https://"+.[1]+":2380"]
                | join("="))
                | join(",")')
envsubst '$ETCD_VERSION,$ETCD_NODES' > $BASEDIR/../etcd-install.sh < $BASEDIR/etcd-install.tmpl

export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
envsubst '$ENCRYPTION_KEY' > $BASEDIR/../encryption-config.yml < $BASEDIR/encryption-config.tmpl
