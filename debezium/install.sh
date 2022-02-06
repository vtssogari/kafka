export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)
export NODE_IP=$(kubectl get nodes --namespace postgres -o jsonpath="{.items[0].status.addresses[0].address}")
export NODE_PORT=$(kubectl get --namespace postgres -o jsonpath="{.spec.ports[0].nodePort}" services postgres-postgresql)

envsubst < debezium-connector.json > connector.json

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://my-confluent-
oss-cp-kafka-connect.default.svc.cluster.local:8083/connectors --data "@connector.json"
