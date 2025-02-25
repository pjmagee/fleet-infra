# 1Password Kubernetes Integration

This directory sets up the 1Password Connect server and Operator for Kubernetes secret management.

## Prerequisites

1. A 1Password account with the ability to create 1Password Connect credentials
2. Access to create secrets in your Kubernetes cluster

## Setup Instructions

### 1. Generate 1Password Connect Credentials

1. In your 1Password account, go to Integrations > Connect Server > New Connect Server
2. Name your server (e.g., "Kubernetes Cluster")
3. Generate credentials and download the `1password-credentials.json` file

### 2. Create the Credentials Secret in Kubernetes

Apply the credentials file as a Kubernetes secret:

```bash
kubectl create namespace 1password
kubectl create secret generic op-credentials \
  --namespace=1password \
  --from-file=1password-credentials.json=/path/to/1password-credentials.json
```

### 3. Create the Operator Token Secret

1. Create a token for the operator in 1Password:
   - Go to your Connect Server in 1Password Integrations
   - Create a new Access Token with an appropriate name
   - Copy the token value

2. Create a Kubernetes secret with the token:

```bash
kubectl create secret generic op-operator-token \
  --namespace=1password \
  --from-literal=token=<your-access-token>
```

## Troubleshooting

If you encounter issues:

Check the 1Password Connect server logs

```bash
kubectl logs -n 1password -l app.kubernetes.io/name=connect
```

Check the Operator logs

```bash
kubectl logs -n 1password -l app.kubernetes.io/name=operator
```

Verify the secrets exist

```bash
kubectl get secrets -n <namespace>
```