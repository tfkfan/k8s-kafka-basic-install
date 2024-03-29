#!/bin/bash

/bin/bash generate-ssl.sh ./ca kafka
/bin/bash generate-secrets.sh kafka kafka kafka

/bin/bash generate-ssl.sh ./ca zookeeper
/bin/bash generate-secrets.sh zookeeper kafka zookeeper

/bin/bash generate-ssl.sh ./ca kafka-client
/bin/bash generate-secrets.sh kafka-client kafka kafka