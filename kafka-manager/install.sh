helm repo add kafka-ui https://provectus.github.io/kafka-ui
helm install kafka-ui kafka-ui/kafka-ui \
--set envs.config.KAFKA_CLUSTERS_0_NAME=local \
--set envs.config.KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=my-confluent-oss-cp-kafka-headless:9092 \
--set envs.config.KAFKA_CLUSTERS_0_ZOOKEEPER=my-confluent-oss-cp-zookeeper-headless:2181 \
--set envs.config.KAFKA_CLUSTERS_0_KSQLDBSERVER=my-confluent-oss-cp-ksql-server:8088 \
--set envs.config.KAFKA_CLUSTERS_0_SCHEMAREGISTRY=my-confluent-oss-cp-schema-registry:8081