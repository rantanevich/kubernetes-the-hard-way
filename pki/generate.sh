#!/bin/sh

tf_output() {
  terraform -chdir=$BASEDIR/../terraform output -json $1 | jq -r "$2"
}

gencert() {
  name="$1"
  hostname="$2"

  cfssl gencert \
    -ca=$BASEDIR/ca.pem \
    -ca-key=$BASEDIR/ca-key.pem \
    -config=$BASEDIR/ca-config.json \
    -profile=kubernetes \
    -hostname=$hostname \
    $BASEDIR/$name-csr.json \
  | cfssljson -bare $BASEDIR/$name
}


BASEDIR=$(dirname "$0")

API_IPV4=$(tf_output api_ipv4 '.')
MASTER_NODES=$(tf_output masters_ipv4 '. | length')
WORKER_NODES=$(tf_output workers_ipv4 '. | length')

cfssl gencert -initca $BASEDIR/ca-csr.json | cfssljson -bare $BASEDIR/ca

gencert admin
gencert kube-controller-manager
gencert kube-proxy
gencert kube-scheduler
gencert service-account
gencert kubernetes 10.32.0.1,$(tf_output masters_ipv4 '. | join(",")'),$API_IPV4,127.0.0.1,$(tf_output masters_hostname '. | join(",")')

for i in $(seq 0 $((WORKER_NODES-1))); do
  gencert $(tf_output workers_hostname ".[$i]") $(tf_output "" "[.masters_hostname.value[$i], .masters_ipv4.value[$i]] | join(\",\")")
done
