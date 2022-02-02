### documentation 
# https://docs.confluent.io/operator/current/co-deploy-cfk.html#co-download-bundle

### install local dynamic provisioner  
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml

kubectl patch storageclass hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

### install confluent helm charts
wget https://github.com/confluentinc/cp-helm-charts/archive/refs/heads/master.zip
unzip master.zip 
mv cp-helm-charts-master cp-helm-charts

helm install my-confluent-oss ./cp-helm-charts


helm uninstall my-confluent-oss

### Debezium installation

helm install --name kafka --namespace $namespace incubator/kafka --set external.enabled=true
