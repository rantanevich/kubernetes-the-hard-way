#!/bin/sh
tf_output() {
  terraform -chdir=$BASEDIR/../terraform output -json $1 | jq -r "$2"
}


BASEDIR=$(dirname "$0")
PKI_DIR=$BASEDIR/../pki
KUBECONFIG_DIR=$BASEDIR/../kubeconfig

GOOGLE_PROJECT=$1

MASTER_INSTANCES=$(tf_output masters_hostname '. | join(" ")')
WORKER_INSTANCES=$(tf_output workers_hostname '. | join(" ")')

for instance in $MASTER_INSTANCES; do
  gcloud compute scp \
    --project=$GOOGLE_PROJECT \
    $PKI_DIR/ca.pem \
    $PKI_DIR/ca-key.pem \
    $PKI_DIR/kubernetes.pem \
    $PKI_DIR/kubernetes-key.pem \
    $PKI_DIR/service-account.pem \
    $PKI_DIR/service-account-key.pem \
    $KUBECONFIG_DIR/admin.kubeconfig \
    $KUBECONFIG_DIR/kube-controller-manager.kubeconfig \
    $KUBECONFIG_DIR/kube-scheduler.kubeconfig \
    $BASEDIR/../encryption-config.yml \
    $BASEDIR/../etcd-install.sh \
    $BASEDIR/../control-plane-install.sh \
    $BASEDIR/rbac-kubelet.sh \
    $instance:~/

  gcloud compute ssh \
    --project=$GOOGLE_PROJECT \
    --command 'chmod +x ~/*.sh' \
    $instance
done

for instance in $WORKER_INSTANCES; do
  gcloud compute scp \
    --project=$GOOGLE_PROJECT \
    $PKI_DIR/ca.pem \
    $PKI_DIR/$instance.pem \
    $PKI_DIR/$instance-key.pem \
    $KUBECONFIG_DIR/$instance.kubeconfig \
    $KUBECONFIG_DIR/kube-proxy.kubeconfig \
    $BASEDIR/../worker-install.sh \
    $instance:~/

  gcloud compute ssh \
    --project=$GOOGLE_PROJECT \
    --command 'chmod +x ~/*.sh' \
    $instance
done
