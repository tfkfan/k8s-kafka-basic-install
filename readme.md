# Инструкция по эксплуатации

Внимание!Все команды по умолчанию выполняются из корня проекта

Примечание! По умолчанию префикс во всех командах кафки - kafka-dev, это наименование релиза helm upgrade.

https://github.com/bitnami/charts/tree/main/bitnami/kafka

## Основные upgrade команды:

```
 helm upgrade kafka-dev ./kafka-cluster -n kafka -f ./kafka-cluster/values-v1.yaml --wait --install
```

## Доступ внутри кластера:

Доступ к брокерам:
```
kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092
kafka-dev-broker-1.kafka-dev-broker-headless.kafka.svc.cluster.local:9092
...
kafka-dev-broker-n.kafka-dev-broker-headless.kafka.svc.cluster.local:9092
```

Доступ к kafdrop:
http://kafdrop-dev.k8s.local.ru/

## Доступ извне кластера
Доступ извне требует дополнительной настройки

Необходимо развернуть кластер со следующими дополнительными настройками:

```
externalAccess:
  enabled: true
  broker:
    service:
      type: ClusterIP
      domain: 1.1.1.1
```
Где "1.1.1.1" - IP ингресса балансировщика

Также необходимо настроить доступ к сервисам из балансировщика:
```
tcp:
    9094: "kafka/kafka-dev-broker-0-external:9094"
    9095: "kafka/kafka-dev-broker-1-external:9094"
```

Где kafka - наименование неймспейса, kafka-dev-broker-0-external:9094 - имя сервиса внешнего доступа и его порт

Проверить адрес внешнего доступа можно командами:

```
kubectl exec -it kafka-dev-broker-0 -n kafka -- cat /opt/bitnami/kafka/config/server.properties | grep advertised.listeners
kubectl exec -it kafka-dev-broker-1 -n kafka -- cat /opt/bitnami/kafka/config/server.properties | grep advertised.listeners

```

Замечание! Адрес и порт EXTERNAL слушателя должен полностью совпадать с внешним адресом и портом настроенным на балансировщике 1к1. В зависимости от кол-ва реплик, при старте кластера внешний порт в advertised.listeners брокеров меняется от 9094 и далее по возрастанию. Именно по этому внешние порты брокеров на балансировщике всегда начинаются с 9094 в том числе (см. код выше), изменить их не получится.

Затем обновить балансировщик:

```
helm upgrade ingress-nginx-internal ingress-nginx/ingress-nginx -f ./ingress-controllers/private/values.yaml -n kube-system

```

Также нужно добавить актуальные обработчики с внешним портом и сгенерированным целевым портом ингресса (см. в самом кластере yandex,google,aws)


## Основные команды обращения к кафке

```
kubectl exec -it kafka-dev-broker-0 -n kafka -c kafka -- kafka-topics.sh --list --bootstrap-server kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092,kafka-dev-broker-1.kafka-dev-broker-headless.kafka.svc.cluster.local:9092

kubectl exec -it kafka-dev-broker-0 -n kafka -c kafka -- kafka-topics.sh --create --partitions 1 --topic mytopic --bootstrap-server kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092,kafka-dev-broker-1.kafka-dev-broker-headless.kafka.svc.cluster.local:9092

kubectl exec -it kafka-dev-broker-0 -n kafka -c kafka -- kafka-console-producer.sh --bootstrap-server kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092 --topic mytopic  < ./kafka-cluster/test/topic-input.txt

kubectl exec -it kafka-dev-broker-0 -n kafka -c kafka -- kafka-console-consumer.sh --bootstrap-server kafka-dev-broker-0.kafka-dev-broker-headless.kafka.svc.cluster.local:9092 --topic mytopic --partition 0 --from-beginning
```

## Защита соединения

Обратите внимание! Все хосты в сертификатах привязаны к имени релиза kafka-dev.

### Генерация корневого доверенного сертификата 


Если отсутствует корневой сертификат, то в тестовом режиме можно создать свой:

```
sh ./tls/generate-ca.sh
```

### Генерация ключей сервиса

Далее для самой кафки генерируется пара сервисных ключей, подписанные вышесгенерированным CA:

```
sh ./tls/generate-ssl.sh ./ca kafka
```

В качестве вспомогательного файла настроек используется openssl.cnf для описания полей сертификата и его расширений(одно из необходимых - SAN). В SAN должны присутствовать все хосты и IP, используемые брокерами.

### Создание секрета в кластере

Далее необходимо создать секрет в кластере с помощью команды:

```
sh ./tls/generate-secrets.sh kafka kafka
```

или 

```
kubectl create secret generic ${secret_name}-jks -n $namespace --from-file=kafka.truststore.jks=./${secret_name}.truststore.jks --from-file=kafka.keystore.jks=./${secret_name}.keystore.jks
```

### Настройка SSL на кластере и апгрейд

В values-v*.yaml необходимо прописать имя секрета, уже созданного в кластере, и пароли к сервисным keystore/truststore

```
kafka:
  tls:
    type: JKS
    existingSecret: kafka-jks
    keystorePassword: 123456
    truststorePassword: 123456
```

Затем необходимо обновить релиз.


### Валидация соединения

Для проверки защищенного соединения необходимо создать config.properties с указанием truststore и keystore, необходимых для соединения:

```
ssl.truststore.location=/.../kafka.truststore.jks
ssl.truststore.password=123456
ssl.keystore.location=/.../kafka-client-1.keystore.jks
ssl.keystore.password=123456
security.protocol=SSL
```

Затем 

```
kafka/bin/kafka-topics.sh --bootstrap-server <brokers> --command-config ./config.properties --list

kafka/bin/kafka-console-producer.sh --bootstrap-server <brokers> --producer.config ./config.properties --topic test-events  < ./topic-input.txt

kafka/bin/kafka-console-consumer.sh --bootstrap-server <brokers> --consumer.config ./config.properties --topic test-events  --partition 0 --from-beginning
```

### SASL

Опционально есть возможность включить SASL (аутентификация). Самый простой способ - подключение логина и пароля