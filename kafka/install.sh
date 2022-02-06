
# build Custom Kafka Connect image 
docker build -t confluentinc/cp-kafka-connect-debezium-es:6.1.0 .

# download helm 
#wget https://github.com/confluentinc/cp-helm-charts/archive/refs/heads/master.zip
#unzip master.zip 
#mv cp-helm-charts-master cp-helm-charts

helm repo add confluentinc https://confluentinc.github.io/cp-helm-charts/
helm repo update

helm install my-confluent-oss \
--set cp-kafka-connect.image="confluentinc/cp-kafka-connect-debezium-es" \
confluentinc/cp-helm-charts