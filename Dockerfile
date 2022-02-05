FROM confluentinc/cp-kafka-connect-base:6.1.0
RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:1.7.1
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:11.1.8
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.3.1
RUN confluent-hub install --no-prompt blueapron/kafka-connect-protobuf-converter:3.1.0
