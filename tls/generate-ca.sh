#!/bin/bash

#selfsigned CA generation
openssl req -x509 -sha256 -newkey rsa:4096 -nodes -days 3500 -keyout ca.key -out ca.crt \
-subj "/C=RU/ST=Moscow/L=Moscow/O=ORG/OU=ORG Moscow/CN=CA" \
-addext "keyUsage=digitalSignature, keyEncipherment, dataEncipherment, cRLSign, keyCertSign"
