#!/usr/bin/env pwsh

# Flux Uninstall Script for Docker Desktop
# This script removes Flux Operator and cleans up resources

Write-Host "🗑️  Uninstalling Flux from Docker Desktop..." -ForegroundColor Yellow

# Check if kubectl is available and context is correct
$currentContext = kubectl config current-context
if ($currentContext -ne "docker-desktop") {
    Write-Host "❌ Current kubectl context is '$currentContext'. Please switch to 'docker-desktop'" -ForegroundColor Red
    Write-Host "Run: kubectl config use-context docker-desktop" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Using context: $currentContext" -ForegroundColor Green

# Remove FluxInstance
Write-Host "🔧 Removing FluxInstance..." -ForegroundColor Yellow
try {
    kubectl delete fluxinstance flux -n flux-system --ignore-not-found=true
    Write-Host "✅ FluxInstance removed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Failed to remove FluxInstance (may not exist)" -ForegroundColor Yellow
}

# Wait for Flux controllers to be removed
Write-Host "⏳ Waiting for Flux controllers to be removed..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Remove Flux Operator
Write-Host "🔧 Removing Flux Operator..." -ForegroundColor Yellow
try {
    helm uninstall flux-operator -n flux-system
    Write-Host "✅ Flux Operator removed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Failed to remove Flux Operator (may not exist)" -ForegroundColor Yellow
}

# Remove flux-system namespace
Write-Host "🔧 Removing flux-system namespace..." -ForegroundColor Yellow
try {
    kubectl delete namespace flux-system --ignore-not-found=true
    Write-Host "✅ flux-system namespace removed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Failed to remove flux-system namespace" -ForegroundColor Yellow
}

# Remove any remaining CRDs
Write-Host "🔧 Removing Flux CRDs..." -ForegroundColor Yellow
try {
    kubectl get crd | Where-Object { $_ -match "fluxcd" -or $_ -match "toolkit.fluxcd" -or $_ -match "controlplane.io" } | ForEach-Object {
        $crd = ($_ -split '\s+')[0]
        kubectl delete crd $crd --ignore-not-found=true
    }
    Write-Host "✅ Flux CRDs removed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Failed to remove some CRDs" -ForegroundColor Yellow
}

Write-Host "`n✅ Flux uninstallation completed!" -ForegroundColor Green
Write-Host "🗑️  All Flux components have been removed from the cluster." -ForegroundColor White
