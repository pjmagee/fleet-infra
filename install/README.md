# Flux Installation for Docker Desktop

This directory contains scripts and manifests to install Flux using the modern **Flux Operator** approach.

## Quick Start

1. **Run the installation script**:
   ```powershell
   .\install-flux.ps1
   ```

2. **Apply the FluxInstance**:
   ```powershell
   kubectl apply -f flux-instance.yaml
   ```

3. **Add the deploy key to GitHub**:
   - The script will generate SSH keys and display the public key
   - Copy the public key and add it as a deploy key to your GitHub repository
   - Go to: `https://github.com/pjmagee/fleet-infra/settings/keys`
   - Click "Add deploy key", paste the key, and enable "Allow write access"

## What's Included

- `install-flux.ps1` - PowerShell script to install Flux Operator and create secrets
- `flux-instance.yaml` - FluxInstance resource configuration
- `uninstall-flux.ps1` - Script to clean up Flux installation

## Manual Steps

If you prefer to run commands manually, see the individual files in this directory.

## Verification

After installation, verify Flux is running:

```powershell
kubectl get pods -n flux-system
kubectl get fluxinstance -n flux-system
```
