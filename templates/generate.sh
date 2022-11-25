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

export ETCD_SERVERS=$(tf_output 'masters_ipv4' '. | map("https://"+.+":2379") | join(",")')
export KUBERNETES_API_IPV4=$(tf_output 'api_ipv4' '.')
export API_SERVER_COUNT=$(tf_output 'masters_ipv4' '. | length')
export KUBERNETES_VERSION=${KUBERNETES_VERSION:-1.21.14}
envsubst '$KUBERNETES_VERSION,$KUBERNETES_API_IPV4,$ETCD_SERVERS,$API_SERVER_COUNT' > $BASEDIR/../control-plane-install.sh < $BASEDIR/control-plane-install.tmpl

export RUNC_VERSION=${RUNC_VERSION:-1.1.4}
export CONTAINERD_VERSION=${CONTAINERD_VERSION:-1.6.10}
export CNI_PLUGINS_VERSION=${CNI_PLUGINS_VERSION:-1.1.1}
export CRI_TOOLS_VERSION=${CRI_TOOLS_VERSION:-1.25.0}
envsubst '$RUNC_VERSION,$CONTAINERD_VERSION,$CNI_PLUGINS_VERSION,$CRI_TOOLS_VERSION,$KUBERNETES_VERSION' > $BASEDIR/../worker-install.sh < $BASEDIR/worker-install.tmpl
