#!/usr/bin/env pwsh

# Flux Installation Script for Docker Desktop
# This script installs the Flux Operator and sets up the necessary secrets

Write-Host "🚀 Installing Flux with Flux Operator for Docker Desktop..." -ForegroundColor Green

# Check if kubectl is available and context is correct
Write-Host "📋 Checking kubectl context..." -ForegroundColor Yellow
$currentContext = kubectl config current-context
if ($currentContext -ne "docker-desktop") {
    Write-Host "❌ Current kubectl context is '$currentContext'. Please switch to 'docker-desktop'" -ForegroundColor Red
    Write-Host "Run: kubectl config use-context docker-desktop" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Using context: $currentContext" -ForegroundColor Green

# Check if flux CLI is available
Write-Host "📋 Checking Flux CLI..." -ForegroundColor Yellow
try {
    $fluxVersion = flux version --client
    Write-Host "✅ Flux CLI found: $($fluxVersion -split "`n" | Select-Object -First 1)" -ForegroundColor Green
} catch {
    Write-Host "❌ Flux CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "   choco install flux" -ForegroundColor Yellow
    Write-Host "   or download from: https://github.com/fluxcd/flux2/releases" -ForegroundColor Yellow
    exit 1
}

# Check if helm is available
Write-Host "📋 Checking Helm..." -ForegroundColor Yellow
try {
    $helmVersion = helm version --short
    Write-Host "✅ Helm found: $helmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Helm not found. Please install it first:" -ForegroundColor Red
    Write-Host "   choco install kubernetes-helm" -ForegroundColor Yellow
    exit 1
}

# Install Flux Operator
Write-Host "🔧 Installing Flux Operator..." -ForegroundColor Yellow
try {
    helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator `
        --namespace flux-system `
        --create-namespace `
        --wait
    Write-Host "✅ Flux Operator installed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install Flux Operator" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Generate SSH key pair for GitHub
Write-Host "🔑 Generating SSH key pair for GitHub..." -ForegroundColor Yellow
$keyPath = "flux-key"
if (Test-Path $keyPath) {
    Write-Host "⚠️  SSH key already exists. Removing old key..." -ForegroundColor Yellow
    Remove-Item $keyPath, "$keyPath.pub" -ErrorAction SilentlyContinue
}

try {
    ssh-keygen -t ecdsa -b 521 -C "flux-docker-desktop" -f $keyPath -q -N '""'
    Write-Host "✅ SSH key pair generated" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to generate SSH key pair" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Create the flux-system secret
Write-Host "🔐 Creating flux-system secret..." -ForegroundColor Yellow
try {
    kubectl create secret generic flux-system `
        --namespace=flux-system `
        --from-file=identity=$keyPath `
        --from-file=identity.pub=$keyPath.pub `
        --from-literal=known_hosts="github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" `
        --dry-run=client -o yaml | kubectl apply -f -
    Write-Host "✅ flux-system secret created" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create flux-system secret" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Display the public key for GitHub
Write-Host "`n🔑 DEPLOY KEY FOR GITHUB:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Get-Content "$keyPath.pub"
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Green
Write-Host "1. Copy the deploy key above" -ForegroundColor White
Write-Host "2. Go to: https://github.com/pjmagee/fleet-infra/settings/keys" -ForegroundColor White
Write-Host "3. Click 'Add deploy key'" -ForegroundColor White
Write-Host "4. Paste the key and enable 'Allow write access'" -ForegroundColor White
Write-Host "5. Run: kubectl apply -f flux-instance.yaml" -ForegroundColor White
Write-Host "6. Verify: kubectl get pods -n flux-system" -ForegroundColor White

Write-Host "`n✅ Flux Operator installation completed!" -ForegroundColor Green

# Clean up SSH keys from current directory
Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item $keyPath, "$keyPath.pub" -ErrorAction SilentlyContinue
