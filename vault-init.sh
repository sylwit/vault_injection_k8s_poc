#!/bin/sh

vault login root
vault kv put secret/my-awesome-app/config username='my_user' password='my_pwd'
vault auth enable kubernetes

echo $KUBE_CA_CERT_B64 > .cert.pem
base64 -d .cert.pem > cert.pem
rm .cert.pem

vault write auth/kubernetes/config \
        token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
        kubernetes_host="$KUBE_HOST" \
        kubernetes_ca_cert=@cert.pem

vault policy write my-awesome-app - <<EOF
path "secret/data/my-awesome-app/config" {
  capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/awesome-app \
        bound_service_account_names=sa-awesome-app \
        bound_service_account_namespaces=demo \
        policies=my-awesome-app \
        ttl=24h

