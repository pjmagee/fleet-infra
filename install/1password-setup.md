# 1Password Setup for Kubernetes (Helm-based)

This directory contains scripts to set up 1Password integration using your existing Helm release in `infrastructure/docker-desktop/1password/release.yaml`.

## Error: "illegal base64 data at input byte 0"

This error indicates that the 1Password credentials file is not properly formatted or corrupted. Follow the troubleshooting steps below.

## Prerequisites

1. **1Password CLI** installed and configured
2. **1Password Connect** credentials file from 1Password.com
3. **Connect token** from your 1Password account
4. **Existing Helm release** in your infrastructure directory

## Quick Setup

```powershell
.\setup-1password.ps1
```

This script will:

- Create the required secrets (`op-credentials` and `op-operator-token`)
- Automatically reconcile your existing Helm release to use the new secrets
- Verify the deployment status

## Manual Setup

### Step 1: Obtain Credentials

1. Go to [1Password.com](https://1password.com) → Integrations → 1Password Connect
2. Create a new Connect server
3. Download the `1password-credentials.json` file
4. Generate a Connect token

### Step 2: Verify Credentials File

```powershell
# Check if the file is valid JSON
Get-Content "path\to\1password-credentials.json" | ConvertFrom-Json

# Check file encoding (should be UTF-8)
Get-Content "path\to\1password-credentials.json" -Raw | Out-File -Encoding UTF8 "1password-credentials-utf8.json"
```

### Step 3: Create Kubernetes Resources

```powershell
# Create namespace
kubectl create namespace 1password

# Create credentials secret
kubectl create secret generic op-credentials --namespace 1password \
  --from-file=1password-credentials.json=path\to\1password-credentials.json

# Create token secret
kubectl create secret generic op-operator-token --namespace 1password \
  --from-literal=token=your-connect-token-here
```

## Troubleshooting

### Issue: "illegal base64 data"

**Cause**: The credentials file is corrupted, has wrong encoding, or contains invalid characters.

**Solutions**:

1. **Re-download** the credentials file from 1Password.com
2. **Check file encoding**:

   ```powershell
   # Ensure UTF-8 encoding
   Get-Content "1password-credentials.json" -Raw | Out-File -Encoding UTF8 "1password-credentials-fixed.json"
   ```

3. **Validate JSON**:

   ```powershell
   # Test if file is valid JSON
   try { Get-Content "1password-credentials.json" | ConvertFrom-Json; Write-Host "✅ Valid JSON" } 
   catch { Write-Host "❌ Invalid JSON: $_" }
   ```

4. **Check for hidden characters**:

   ```powershell
   # Remove potential BOM or hidden characters
   (Get-Content "1password-credentials.json" -Raw).Trim() | Out-File -Encoding UTF8 -NoNewline "1password-credentials-clean.json"
   ```

### Issue: Connect server not responding

**Solutions**:

1. Verify the Connect token is correct
2. Check if 1Password Connect is properly deployed
3. Ensure network connectivity to 1Password services

## Verification

```powershell
# Check if secrets exist
kubectl get secrets -n 1password

# Check 1Password Connect logs (if deployed)
kubectl logs -n 1password -l app=onepassword-connect

# Test connection
kubectl exec -n 1password deployment/onepassword-connect -- /usr/local/bin/op --version
```
