#!/bin/sh

tf_output() {
  terraform -chdir=$BASEDIR/../terraform output -json $1 | jq -r "$2"
}


export BASEDIR=$(dirname "$0")
export GOOGLE_PROJECT=$1
export KUBECONFIG=$BASEDIR/../kubeconfig/remote.kubeconfig
export KUBERNETES_API_IPV4=$(tf_output 'api_ipv4' '.')


echo
echo '##### ETCD #####'
for server in $(tf_output 'masters_hostname' '.[]'); do
  echo $server
  gcloud compute ssh $server \
    --tunnel-through-iap \
    --project=$GOOGLE_PROJECT \
    --command='
      sudo ETCDCTL_API=3 etcdctl member list \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/etcd/ca.pem \
        --cert=/etc/etcd/kubernetes.pem \
        --key=/etc/etcd/kubernetes-key.pem'
done

echo
echo
echo '##### Cluster Info #####'
kubectl cluster-info

echo
echo
echo '##### Kubernetes Version #####'
curl \
  --include \
  --cacert $BASEDIR/../pki/ca.pem \
  "https://$KUBERNETES_API_IPV4:6443/version"

echo
echo
echo
echo '##### Nodes #####'
kubectl get nodes

echo
echo
echo '##### DNS #####'
kubectl run busybox --image=busybox:latest --command -- sleep 3600
until [ $(kubectl get pods busybox -o jsonpath='{.status.phase}') == 'Running' ]; do
  echo "waiting for busybox is running ..."
  sleep 1
done
kubectl exec -ti busybox -- nslookup kubernetes

echo
echo
echo '##### Data Encryption #####'
kubectl create secret generic kubernetes-the-hard-way --from-literal "timestamp=$(date +%s)"
gcloud compute ssh $(tf_output 'masters_hostname' '.[0]') \
  --tunnel-through-iap \
  --project=$GOOGLE_PROJECT \
  --command='
    sudo ETCDCTL_API=3 etcdctl get \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/etcd/ca.pem \
      --cert=/etc/etcd/kubernetes.pem \
      --key=/etc/etcd/kubernetes-key.pem \
      /registry/secrets/default/kubernetes-the-hard-way \
    | hexdump -C'

echo
echo
echo '##### Deployment #####'
kubectl create deployment nginx --image=nginx
kubectl get pods -l app=nginx

echo
echo
echo '##### Port Forwarding #####'
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
until [ $(kubectl get pods $POD_NAME -o jsonpath='{.status.phase}') == 'Running' ]; do
  echo "waiting for $POD_NAME is running ..."
  sleep 1
done
kubectl port-forward $POD_NAME 8080:80 &
until bash -c 'echo > /dev/tcp/127.0.0.1/8080'; do
  echo 'waiting forwarding from 8080 -> 80 ...'
  sleep 1
done
curl -I http://127.0.0.1:8080
kill $!

echo
echo '##### Logs #####'
kubectl logs $POD_NAME

echo
echo
echo '##### Exec #####'
kubectl exec -ti $POD_NAME -- nginx -v

echo
echo
echo '##### Services #####'
kubectl expose deployment nginx --port 80 --type NodePort
NODE_PORT=$(kubectl get services nginx -o jsonpath='{.spec.ports[0].nodePort}')
for server in $(tf_output 'workers_public_ipv4' '.[]'); do
  echo $server
  curl -I "http://$server:$NODE_PORT"
done

echo
echo '##### Clean Up #####'
kubectl delete pods --force busybox 2>/dev/null
kubectl delete deployments.apps --force nginx 2>/dev/null
kubectl delete secrets --force kubernetes-the-hard-way 2>/dev/null
kubectl delete services --force nginx 2>/dev/null
