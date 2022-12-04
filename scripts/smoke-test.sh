#!/bin/sh

tf_output() {
  terraform -chdir=$BASEDIR/../terraform output -json $1 | jq -r "$2"
}


export BASEDIR=$(dirname "$0")
export GOOGLE_PROJECT=$1
export KUBECONFIG=$BASEDIR/../kubeconfig/remote.kubeconfig

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
    | hexdump -C' 2>/dev/null

echo
echo '##### Deployment #####'
kubectl create deployment nginx --image=nginx
kubectl get pods -l app=nginx

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
echo '##### Exec #####'
kubectl exec -ti $POD_NAME -- nginx -v

echo
echo '##### Services #####'
kubectl expose deployment nginx --port 80 --type NodePort
NODE_PORT=$(kubectl get services nginx -o jsonpath='{.spec.ports[0].nodePort}')
curl -I http://$(tf_output 'workers_public_ipv4' '.[0]'):$NODE_PORT

echo
echo '##### Clean Up #####'
kubectl delete deployments.apps --force nginx 2>/dev/null
kubectl delete secrets --force kubernetes-the-hard-way 2>/dev/null
kubectl delete services --force nginx 2>/dev/null
