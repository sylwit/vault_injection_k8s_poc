.PHONY: start k8s vault env app

VAULT_INIT=`cat ./vault-init.sh`
GATEWAY_IP=$(shell minikube ssh "grep host.minikube.internal /etc/hosts" | awk '{print $$1}')

start:
	minikube start

k8s:
	kubectl create namespace demo
	kubectl config set-context --current --namespace=demo
	kubectl apply -f k8s.yaml
	helm repo add hashicorp https://helm.releases.hashicorp.com
	helm install vault hashicorp/vault \
		--set "injector.externalVaultAddr=http://${GATEWAY_IP}:8200"

vault: env
	docker-compose up -d vault
	sleep 5
	docker-compose exec vault sh -c "${VAULT_INIT}"

app:
	kubectl apply -f app.yaml
	echo "Once deployed, navigate to http://`minikube ip`:30100?file=credentials.txt"

env:
	echo "TOKEN_REVIEW_JWT=`kubectl get secret sa-vault-auth -o go-template='{{ .data.token }}' | base64 --decode)}`" > .env
	echo "KUBE_CA_CERT_B64=`kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}'`" >> .env
	echo "KUBE_HOST=https://`minikube ip`:8443" >> .env