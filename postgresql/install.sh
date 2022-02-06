kubectl delete namespace postgres
kubectl create namespace postgres
kubectl create configmap postgresql-config \
--namespace postgres --from-file=extended.conf

helm install postgres --namespace postgres \
--set primary.existingExtendedConfigmap=postgresql-config \
--set primary.service.type=NodePort \
--set primary.service.ports.postgresql=30600 \
--set global.postgresql.auth.postgresPassword=passw0rd \
bitnami/postgresql

export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)
export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)
export NODE_IP=$(kubectl get nodes --namespace postgres -o jsonpath="{.items[0].status.addresses[0].address}")
export NODE_PORT=$(kubectl get --namespace postgres -o jsonpath="{.spec.ports[0].nodePort}" services postgres-postgresql)

# create sample database dvdrental
PGPASSWORD="$POSTGRES_PASSWORD" psql --host $NODE_IP --port $NODE_PORT -U postgres -d postgres -c 'CREATE DATABASE dvdrental;'
PGPASSWORD="$POSTGRES_PASSWORD" pg_restore --host $NODE_IP --port $NODE_PORT -U postgres -d dvdrental dvdrental.tar
