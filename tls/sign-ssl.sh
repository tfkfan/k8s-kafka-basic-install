#!/bin/bash

validity_days=1200
ca_path=$1
keypair_name=$2
conf_path=$3
keystore_password=changeit
truststore_password=changeit

echo "Signing cert.."

openssl x509 \
  -req \
  -days ${validity_days} \
  -in ${keypair_name}.csr \
  -CA ${ca_path}.crt \
  -CAkey ${ca_path}.key \
  -CAcreateserial \
  -extensions v3_req \
  -extfile $conf_path \
  -out ${keypair_name}.crt

rm -f ./${keypair_name}.csr

echo "Cert validation.."

openssl x509 -in  ${keypair_name}.crt -noout -text

openssl pkcs12 -export -in ${keypair_name}.crt -passout pass:"${keystore_password}" -inkey ${keypair_name}.key -out ${keypair_name}.keystore.p12

keytool -keystore ${keypair_name}.truststore.jks -alias caroot -import -file ${ca_path}.crt -storepass "${truststore_password}" -noprompt
keytool -keystore ${keypair_name}.truststore.jks -alias 1 -import -file ${keypair_name}.crt -storepass "${truststore_password}" -noprompt

keytool -importkeystore -srckeystore ${keypair_name}.keystore.p12 -srcstoretype PKCS12 -srcstorepass "${keystore_password}" \
          -deststorepass "${keystore_password}" -destkeystore ${keypair_name}.keystore.jks -noprompt

rm -f ${keypair_name}.keystore.p12