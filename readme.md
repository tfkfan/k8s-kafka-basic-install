This is basic kafka+zookeeper+kafdrop k8s helm install demo


helm upgrade zookeeper-dev bitnami/zookeeper -n kafka -f ./kafka/zookeeper-values.yaml --wait --install

helm upgrade kafka-dev bitnami/kafka -n kafka -f ./kafka/kafka-values.yaml --wait --install

helm  upgrade kafdrop-dev -n kafka -f kafka/kafdrop-values.yaml ./kafka/kafdrop/chart/ --wait --install

Kafka can be accessed by consumers via port 9092 on the following DNS name from within your cluster:

    kafka-dev.kafka.svc.cluster.local

Each Kafka broker can be accessed by producers via port 9092 on the following DNS name(s) from within your cluster:

    kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092

kubectl exec --tty -i kafka-dev-broker-0 -n kafka -- bash

kubectl exec -it kafka-dev-broker-0 -n kafka -- kafka-topics.sh --list --bootstrap-server kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092

kubectl exec -it kafka-dev-broker-0 -n kafka -- kafka-topics.sh --create --partitions 1 --topic mytopic --bootstrap-server kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092

kubectl exec -it kafka-dev-broker-0 -n kafka -- kafka-console-producer.sh --bootstrap-server kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092 --topic mytopic  < ./kafka/test/topic-input.txt

kubectl exec -it kafka-dev-broker-0 -n kafka -- kafka-console-consumer.sh --bootstrap-server kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092 --topic mytopic --partition 0 --from-beginning
