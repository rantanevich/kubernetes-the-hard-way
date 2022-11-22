#!/bin/sh

tf_output() {
  terraform -chdir=$BASEDIR/../terraform output -json $1 | jq -r "$2"
}

genconfig() {
  hostname="$1"
  client="$2"
  user="$3"

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=$BASEDIR/../pki/ca.pem \
    --embed-certs=true \
    --server=https://$hostname:6443 \
    --kubeconfig=$BASEDIR/$client.kubeconfig

  kubectl config set-credentials $user \
    --client-certificate=$BASEDIR/../pki/$client.pem \
    --client-key=$BASEDIR/../pki/$client-key.pem \
    --embed-certs=true \
    --kubeconfig=$BASEDIR/$client.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=$user \
    --kubeconfig=$BASEDIR/$client.kubeconfig

  kubectl config use-context default --kubeconfig=$BASEDIR/$client.kubeconfig
}


BASEDIR=$(dirname "$0")

API_IPV4=$(tf_output api_ipv4 '.')
WORKER_INSTANCES=$(tf_output workers_hostname '. | join(" ")')

genconfig $API_IPV4 kube-proxy system:kube-proxy
genconfig 127.0.0.1 kube-controller-manager system:kube-controller-manager
genconfig 127.0.0.1 kube-scheduler system:kube-scheduler
genconfig 127.0.0.1 admin admin

for instance in $WORKER_INSTANCES; do
  genconfig $API_IPV4 $instance system:node:$instance
done
