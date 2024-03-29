#!/bin/bash

validity_days=1200
ca_path=$1
keypair_name=$2
csr_path=$3

echo "Signing cert.."

openssl x509 \
  -req \
  -days ${validity_days} \
  -in ${csr_path} \
  -CA ${ca_path}.crt \
  -CAkey ${ca_path}.key \
  -CAcreateserial \
  -copy_extensions copyall \
  -out ${keypair_name}.crt

echo "Cert validation.."

openssl x509 -in  ${keypair_name}.crt -noout -text
