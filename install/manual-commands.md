# Manual Installation Commands

If you prefer to run the installation commands manually instead of using the PowerShell script:

## Prerequisites

```powershell
# Verify kubectl context
kubectl config use-context docker-desktop

# Verify required tools
flux version --client
helm version --short
```

## Step 1: Install Flux Operator

```powershell
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator `
  --namespace flux-system `
  --create-namespace `
  --wait
```

## Step 2: Generate SSH Key

```powershell
# Generate SSH key pair
ssh-keygen -t ecdsa -b 521 -C "flux-docker-desktop" -f flux-key -q -N '""'

# Create Kubernetes secret
kubectl create secret generic flux-system `
  --namespace=flux-system `
  --from-file=identity=flux-key `
  --from-file=identity.pub=flux-key.pub `
  --from-literal=known_hosts="github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="

# Display public key for GitHub
Get-Content flux-key.pub
```

## Step 3: Add Deploy Key to GitHub

1. Copy the public key from the previous step
2. Go to: https://github.com/pjmagee/fleet-infra/settings/keys
3. Click "Add deploy key"
4. Paste the key and enable "Allow write access"

## Step 4: Apply FluxInstance

```powershell
kubectl apply -f flux-instance.yaml
```

## Step 5: Verify Installation

```powershell
# Check Flux Operator
kubectl get pods -n flux-system

# Check FluxInstance
kubectl get fluxinstance -n flux-system

# Check Flux controllers (after FluxInstance is applied)
kubectl get all -n flux-system
```

## Troubleshooting

```powershell
# Check FluxInstance status
kubectl describe fluxinstance flux -n flux-system

# Check logs
kubectl logs -n flux-system -l app.kubernetes.io/name=flux-operator

# Check GitRepository sync
kubectl get gitrepository -n flux-system
kubectl describe gitrepository -n flux-system
```
