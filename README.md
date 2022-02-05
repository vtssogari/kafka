NAME: my-confluent-oss
LAST DEPLOYED: Tue Feb  1 20:21:34 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
## ------------------------------------------------------
## Zookeeper
## ------------------------------------------------------
Connection string for Confluent Kafka:
  my-confluent-oss-cp-zookeeper-0.my-confluent-oss-cp-zookeeper-headless:2181,my-confluent-oss-cp-zookeeper-1.my-confluent-oss-cp-zookeeper-headless:2181,...

To connect from a client pod:

1. Deploy a zookeeper client pod with configuration:
cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: zookeeper-client
      namespace: default
    spec:
      containers:
      - name: zookeeper-client
        image: confluentinc/cp-zookeeper:6.1.0
        command:
          - sh
          - -c
          - "exec tail -f /dev/null"
EOF

2. Log into the Pod

  kubectl exec -it zookeeper-client -- /bin/bash

3. Use zookeeper-shell to connect in the zookeeper-client Pod:

  zookeeper-shell my-confluent-oss-cp-zookeeper:2181

4. Explore with zookeeper commands, for example:

  # Gives the list of active brokers
  ls /brokers/ids

  # Gives the list of topics
  ls /brokers/topics

  # Gives more detailed information of the broker id '0'
  get /brokers/ids/0
  
## ------------------------------------------------------
## Kafka
## ------------------------------------------------------
To connect from a client pod:

1. Deploy a kafka client pod with configuration:
cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: kafka-client
      namespace: default
    spec:
      containers:
      - name: kafka-client
        image: confluentinc/cp-enterprise-kafka:6.1.0
        command:
          - sh
          - -c
          - "exec tail -f /dev/null"
EOF

2. Log into the Pod

  kubectl exec -it kafka-client -- /bin/bash

3. Explore with kafka commands:

  # Create the topic
  kafka-topics --zookeeper my-confluent-oss-cp-zookeeper-headless:2181 --topic my-confluent-oss-topic --create --partitions 1 --replication-factor 1 --if-not-exists

  # Create a message
  MESSAGE="`date -u`"

  # Produce a test message to the topic
  echo "$MESSAGE" | kafka-console-producer --broker-list my-confluent-oss-cp-kafka-headless:9092 --topic my-confluent-oss-topic

  # Consume a test message from the topic
  kafka-console-consumer --bootstrap-server my-confluent-oss-cp-kafka-headless:9092 --topic my-confluent-oss-topic --from-beginning --timeout-ms 2000 --max-messages 1 | grep "$MESSAGE"

 # Registry url
 my-confluent-oss-cp-schema-registry:8081 
 
  # ----------------------------------------

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
EOF

❯ helm upgrade --cleanup-on-fail \
  --install jupyterhub jupyterhub/jupyterhub \
  --namespace default \
  --values config.yaml
Error: Kubernetes cluster unreachable: unable to load root certificates: unable to parse bytes as PEM block
❯ microk8s helm3 upgrade --cleanup-on-fail \
  --install jupyterhub jupyterhub/jupyterhub \
  --namespace default \
  --values config.yaml
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /var/snap/microk8s/2948/credentials/client.config
Release "jupyterhub" does not exist. Installing it now.
NAME: jupyterhub
LAST DEPLOYED: Tue Feb  1 22:37:15 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing JupyterHub!
and watching for both those pods to be in status 'Running'.

You can find the public (load-balancer) IP of JupyterHub by running:

  kubectl -n default get svc proxy-public -o jsonpath='{.status.loadBalancer.ingresYou can find the public (load-balancer) IP of JupyterHub by running:

  kubectl -n default get svc proxy-public -o jsonpath='{.status.loadBalan

If you have questions, please:

  1. Read the guide at https://z2jh.jupyter.org
  2. Ask for help or chat to us on https://discourse.jupyter.org/
  3. If you find a bug please report it at https://github.com/jupyterhub/zero-to-jupyterhub-k8s/issues
❯ kubectl --namespace=default get svc proxy-public
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
proxy-public   LoadBalancer   10.152.183.50   <pending>     80:32627/TCP   41s
❯ kubectl --namespace=default get svc proxy-public
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
proxy-public   LoadBalancer   10.152.183.50   <pending>     80:32627/TCP   50s