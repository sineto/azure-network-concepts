#!/bin/bash

## ---------------------------------------------------------------------------
## NOTE:
## 1. This script only runs on Linux
## 2. This script have openssl and strongswan as dependency
## ---------------------------------------------------------------------------

export PASSWORD="password"
export USERNAME="client"

ipsec pki --gen --outform pem >caKey.pem
ipsec pki --self --in caKey.pem --dn "CN=VPN CA" --ca --outform pem >caCert.pem

ipsec pki --gen --outform pem >"${USERNAME}Key.pem"
ipsec pki --pub --in "${USERNAME}Key.pem" | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "CN=${USERNAME}" --san "${USERNAME}" --flag clientAuth --outform pem >"${USERNAME}Cert.pem"

openssl pkcs12 -in "${USERNAME}Cert.pem" -inkey "${USERNAME}Key.pem" -certfile caCert.pem -export -out "${USERNAME}.p12" -password "pass:${PASSWORD}"
mkdir -p files && openssl x509 -in "${USERNAME}Cert.pem" -outform der | base64 -w0 >>files/vpnRootCert.txt
