#!/bin/sh

mkdir -p volumes/storage/vault
chmod -R 0777 volumes && chmod -R +t volumes

# Start a local Kubernetes cluster 
k3d cluster create --config k3d-config.yaml

# Install flux components into cluster
flux install

# Apply infrastructure manifests
kubectl apply --kustomize infrastructure

# Wait for ingress-nginx to be ready
kubectl wait \
  --for=condition=Available=true \
  --timeout=4m \
  --namespace ingress-nginx \
  deployment/ingress-nginx-controller

# Apply ClusterSecretStore, the gateway to the secret backend
kubectl wait \
  --for=condition=Available=true \
  --timeout=4m \
  --namespace external-secrets \
  deployment/external-secrets-webhook
kubectl apply --kustomize infrastructure/external-secrets/crs

# Create secrets
kubectl wait \
  --for=condition=Ready=true \
  --timeout=4m \
  --namespace vault \
  pod/vault-0
VAULT_TOKEN=$(cat volumes/storage/vault/cluster-keys.json | tr -d '[:space:]' | grep -Eo '"root_token"[^}]*' | grep -Eo '[^:]*$' | sed 's/^"\(.*\)"$/\1/')
for SECRET in $(find apps -type f -name ".secret.example.json")
do
  SECRET_NAME=$(basename $(dirname $SECRET))
  curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --header "Content-Type: application/merge-patch+json" \
    --request POST \
    --data @$SECRET \
    http://vault.127.0.0.1.nip.io:8080/v1/secret/data/$SECRET_NAME
done

kubectl apply --kustomize apps
