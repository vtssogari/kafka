### documentation 
# https://docs.confluent.io/operator/current/co-deploy-cfk.html#co-download-bundle

### install local dynamic provisioner  
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml

kubectl patch storageclass hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

###
microk8s helm3 repo add bitnami https://charts.bitnami.com/bitnami

### dashboard 
microk8s dashboard-proxy

### Database instal Postgresql
1. create extended.conf
```
cat <<EOF >>extended.conf
wal_level = logical
max_wal_senders = 1
max_replication_slots = 1
EOF
```

2. Create a ConfigMap from the extended.conf file with the following command:
```
kubectl create namespace postgres
kubectl create configmap postgresql-config --namespace postgres --from-file=extended.conf
```

3. Install PostgreSQL using the Stable Helm Chart with the following command:
```
microk8s helm3 install postgres --namespace postgres --set primary.existingExtendedConfigmap=postgresql-config --set primary.service.type=NodePort --set primary.service.ports.postgresql=30600 --set global.postgresql.auth.postgresPassword=passw0rd bitnami/postgresql
```

uninstall
```
# microk8s helm3 uninstall postgres
```

Test
```
** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 30600 on the following DNS names from within your cluster:

    postgres-postgresql.postgres.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run postgres-postgresql-client --rm --tty -i --restart='Never' --namespace postgres --image docker.io/bitnami/postgresql:14.1.0-debian-10-r80 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host postgres-postgresql -U postgres -d postgres -p 30600

To connect to your database from outside the cluster execute the following commands:

    export NODE_IP=$(kubectl get nodes --namespace postgres -o jsonpath="{.items[0].status.addresses[0].address}")
    export NODE_PORT=$(kubectl get --namespace postgres -o jsonpath="{.spec.ports[0].nodePort}" services postgres-postgresql)
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host $NODE_IP --port $NODE_PORT -U postgres -d postgres
```

### Restore dump
```
psql template1 -c 'drop database database_name;'
psql template1 -c 'create database database_name with owner your_user_name;
psql --host $NODE_IP --port $NODE_PORT -U postgres -d postgres database_name < database_name_20160527.sql
```
### install confluent helm charts
```
wget https://github.com/confluentinc/cp-helm-charts/archive/refs/heads/master.zip
unzip master.zip 
mv cp-helm-charts-master cp-helm-charts
microk8s helm3 install my-confluent-oss ./cp-helm-charts
```
### uninstall
microk8s helm3 uninstall my-confluent-oss

### Installing Jupyter Hub 
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

cat <<EOF >>config.yaml
# This file can update the JupyterHub Helm chart's default configuration values.
#
# For reference see the configuration reference and default values, but make
# sure to refer to the Helm chart version of interest to you!
#
# Introduction to YAML:     https://www.youtube.com/watch?v=cdLNKUoMc6c
# Chart config reference:   https://zero-to-jupyterhub.readthedocs.io/en/stable/resources/reference.html
# Chart default values:     https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/HEAD/jupyterhub/values.yaml
# Available chart versions: https://jupyterhub.github.io/helm-chart/
#
singleuser:
  extraEnv: 
    GRANT_SUDO: "yes"
    NOTEBOOK_ARGS: "--allow-root"
  uid: 0
  cmd: start-singleuser.sh
EOF

microk8s helm3 upgrade --cleanup-on-fail \
  --install jupyterhub jupyterhub/jupyterhub \
  --namespace default \
  --values config.yaml

kubectl --namespace=default get svc proxy-public

### Debezium installation
# Create kafka-connect custom plugin image 

cat <<EOF >>Dockerfile
FROM confluentinc/cp-kafka-connect-base:6.1.0
RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:1.7.1
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:11.1.8
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.3.1
EOF 

docker build -t confluentinc/cp-kafka-connect-debezium-es:6.1.0 .
docker save confluentinc/cp-kafka-connect-debezium-es:6.1.0 > connector.tar
microk8s ctr image import connector.tar


microk8s helm3 uninstall my-confluent-oss
microk8s helm3 install my-confluent-oss --set kafka.bootstrapServers="my-confluent-oss-cp-kafka-headless:9092",cp-schema-registry.url="my-confluent-oss-cp-schema-registry:8081",image="confluentinc/cp-kafka-connect-debezium-es",imagePullPolicy="Never" cp-helm-charts/charts/cp-kafka-connect

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://my-confluent-
oss-cp-kafka-connect.default.svc.cluster.local:8083/connectors --data "@connector.json"

connector.json
{
  "name": "marketplace-connector",
  "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "tasks.max": "1",
      "plugin.name": "pgoutput",
      "database.hostname": "10.0.2.15",
      "database.port": "30474",
      "database.user": "postgres",
      "database.password": "passw0rd",
      "database.dbname": "marketplace",
      "database.server.name": "10.0.2.15",
      "table.whitelist": "marketplacesunuat.property__c"
  }
}


### trouble shooting
curl -s "http://localhost:8083/connectors/source-debezium-orders-00/status" | jq '.tasks[0].trace'



plugin.name