#!/bin/sh
set -xe

tf_output() {
  terraform -chdir=$BASEDIR/../terraform output -json $1 | jq -r "$2"
}


BASEDIR=$(dirname "$0")
PKI_DIR=$BASEDIR/../pki

GOOGLE_PROJECT=$1

MASTER_INSTANCES=$(tf_output masters_hostname '. | join(" ")')
WORKER_INSTANCES=$(tf_output workers_hostname '. | join(" ")')

for instance in "$MASTER_INSTANCES"; do
  gcloud compute scp \
    --project=$GOOGLE_PROJECT \
    $PKI_DIR/ca.pem \
    $PKI_DIR/ca-key.pem \
    $PKI_DIR/kubernetes.pem \
    $PKI_DIR/kubernetes-key.pem \
    $PKI_DIR/service-account.pem \
    $PKI_DIR/service-account-key.pem \
    $instance:~/
done

for instance in "$WORKER_INSTANCES"; do
  gcloud compute scp \
    --project=$GOOGLE_PROJECT \
    $PKI_DIR/ca.pem \
    $PKI_DIR/$instance.pem \
    $PKI_DIR/$instance-key.pem \
    $instance:~/
done
