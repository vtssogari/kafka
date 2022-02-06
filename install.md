# Kafka Deployment 

https://docs.confluent.io/operator/current/co-deploy-cfk.html#co-download-bundle

## Kubernetes:  install local dynamic provisioner  
```
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
kubectl patch storageclass hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### test dynamic pvc
```
kubectl apply -f pvctest.yaml

# check volume assigned
kubectl get pvc

kubectl apply -f pvctest.yaml
```

## Kubernetes: helm install

```
helm repo add bitnami https://charts.bitnami.com/bitnami
```

## Postgres Database  

### configure Postgresql
1. create extended.conf
```
rm extended.conf
cat <<EOF >>extended.conf
wal_level = logical
max_wal_senders = 20
max_replication_slots = 4
EOF

kubectl create namespace postgres
kubectl create configmap postgresql-config --namespace postgres --from-file=extended.conf

k get -n postgres configmap
```

3. Install PostgreSQL using the Stable Helm Chart with the following command:
```
helm install postgres --namespace postgres --set primary.existingExtendedConfigmap=postgresql-config --set primary.service.type=NodePort --set primary.service.ports.postgresql=30600 --set global.postgresql.auth.postgresPassword=passw0rd bitnami/postgresql
```

uninstall
```
# helm uninstall postgres
```

Test
```
** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 30600 on the following DNS names from within your cluster:

    postgres-postgresql.postgres.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)

To connect to your database run the following command

    kubectl run postgres-postgresql-client --rm --tty -i --restart='Never' --namespace postgres --image docker.io/bitnami/postgresql:14.1.0-debian-10-r80 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host postgres-postgresql -U postgres -d postgres -p 30600

To connect to your database from outside the cluster execute the following commands:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)
    export NODE_IP=$(kubectl get nodes --namespace postgres -o jsonpath="{.items[0].status.addresses[0].address}")
    export NODE_PORT=$(kubectl get --namespace postgres -o jsonpath="{.spec.ports[0].nodePort}" services postgres-postgresql)
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host $NODE_IP --port $NODE_PORT -U postgres -d postgres


```

### Restore dump
```
export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)
export NODE_IP=$(kubectl get nodes --namespace postgres -o jsonpath="{.items[0].status.addresses[0].address}")
export NODE_PORT=$(kubectl get --namespace postgres -o jsonpath="{.spec.ports[0].nodePort}" services postgres-postgresql)
PGPASSWORD="$POSTGRES_PASSWORD" psql --host $NODE_IP --port $NODE_PORT -U postgres -d postgres

CREATE DATABASE dvdrental;

PGPASSWORD="$POSTGRES_PASSWORD" pg_restore --host $NODE_IP --port $NODE_PORT -U postgres -d dvdrental dvdrental.tar

```
### install confluent helm charts

#### build custom Kafka connect docker image and register

### Create kafka-connect custom plugin image 
```
cat <<EOF >>Dockerfile
FROM confluentinc/cp-kafka-connect-base:6.1.0
RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:1.7.1
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:11.1.8
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.3.1
EOF 

docker build -t confluentinc/cp-kafka-connect-debezium-es:6.1.0 .
```

### install Kafka confluent 

```
wget https://github.com/confluentinc/cp-helm-charts/archive/refs/heads/master.zip
unzip master.zip 
mv cp-helm-charts-master cp-helm-charts
helm install my-confluent-oss ./cp-helm-charts
```

### uninstall
```
helm uninstall my-confluent-oss
```

### Installing Jupyter Hub 
```
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

helm upgrade --cleanup-on-fail \
  --install jupyterhub jupyterhub/jupyterhub \
  --namespace default \
  --values config.yaml

kubectl --namespace=default get svc proxy-public
```

# Debezium installation

```
helm uninstall my-confluent-oss
helm install my-confluent-oss --set kafka.bootstrapServers="my-confluent-oss-cp-kafka-headless:9092",cp-schema-registry.url="my-confluent-oss-cp-schema-registry:8081",image="confluentinc/cp-kafka-connect-debezium-es",imagePullPolicy="Never" cp-helm-charts/charts/cp-kafka-connect
```

```
cat <<EOF >>connector.json
{
  "name": "marketplace-connector",
  "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "tasks.max": "1",
      "plugin.name": "pgoutput",
      "database.hostname": "postgres-postgresql-hl.postgre.svc.cluster.local",
      "database.port": "30600",
      "database.user": "postgres",
      "database.password": "passw0rd",
      "database.dbname": "marketplace",
      "database.server.name": "postgres-postgresql-hl.postgre.svc.cluster.local",
      "table.whitelist": "dvdrental.customer"
  }
}
EOF

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://my-confluent-
oss-cp-kafka-connect.default.svc.cluster.local:8083/connectors --data "@connector.json"
```

# Kafka UI Manager

KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS my-confluent-oss-cp-kafka-headless:9092
KAFKA_CLUSTERS_0_ZOOKEEPER        my-confluent-oss-cp-zookeeper-headless:2181
KAFKA_CLUSTERS_0_KSQLDBSERVER     my-confluent-oss-cp-ksql-server:8088
KAFKA_CLUSTERS_0_SCHEMAREGISTRY   my-confluent-oss-cp-schema-registry:8081

```
helm repo add kafka-ui https://provectus.github.io/kafka-ui
helm install kafka-ui kafka-ui/kafka-ui \
--set envs.config.KAFKA_CLUSTERS_0_NAME=local \
--set envs.config.KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=my-confluent-oss-cp-kafka-headless:9092 \
--set envs.config.KAFKA_CLUSTERS_0_ZOOKEEPER=my-confluent-oss-cp-zookeeper-headless:2181 \
--set envs.config.KAFKA_CLUSTERS_0_KSQLDBSERVER=my-confluent-oss-cp-ksql-server:8088 \
--set envs.config.KAFKA_CLUSTERS_0_SCHEMAREGISTRY=my-confluent-oss-cp-schema-registry:8081
```

### trouble shooting
```
curl -s "http://localhost:8083/connectors/source-debezium-orders-00/status" | jq '.tasks[0].trace'
```
