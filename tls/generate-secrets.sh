#!/bin/bash

secret_name=$1
namespace=$2
file_name=$3

kubectl create secret generic ${secret_name}-jks -n $namespace --from-file=${file_name}.truststore.jks=./${secret_name}.truststore.jks --from-file=${file_name}.keystore.jks=./${secret_name}.keystore.jks