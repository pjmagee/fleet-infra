#!/usr/bin/env pwsh

# 1Password Setup Script for Kubernetes (Helm-based)
# This script creates the required secrets for your existing 1Password Helm release

param(
    [Parameter(Mandatory=$false)]
    [string]$CredentialsFile,
    
    [Parameter(Mandatory=$false)]
    [string]$ConnectToken
)

Write-Host "🔐 Setting up 1Password secrets for Helm release..." -ForegroundColor Green

# Check if kubectl is available and context is correct
Write-Host "📋 Checking kubectl context..." -ForegroundColor Yellow
$currentContext = kubectl config current-context
if ($currentContext -ne "docker-desktop") {
    Write-Host "❌ Current kubectl context is '$currentContext'. Please switch to 'docker-desktop'" -ForegroundColor Red
    Write-Host "Run: kubectl config use-context docker-desktop" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Using context: $currentContext" -ForegroundColor Green

# Prompt for credentials file if not provided
if (-not $CredentialsFile) {
    $CredentialsFile = Read-Host "Enter path to 1password-credentials.json file"
}

# Check if credentials file exists
if (-not (Test-Path $CredentialsFile)) {
    Write-Host "❌ Credentials file not found: $CredentialsFile" -ForegroundColor Red
    Write-Host "Please download the credentials file from 1Password.com → Integrations → 1Password Connect" -ForegroundColor Yellow
    exit 1
}

# Validate credentials file
Write-Host "🔍 Validating credentials file..." -ForegroundColor Yellow
try {
    $credentials = Get-Content $CredentialsFile -Raw | ConvertFrom-Json
    Write-Host "✅ Credentials file is valid JSON" -ForegroundColor Green
    
    # Check for required fields in credentials
    if (-not $credentials.verifier -or -not $credentials.encCredentials) {
        Write-Host "⚠️  Warning: Credentials file may be missing required fields (verifier, encCredentials)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Invalid JSON in credentials file: $_" -ForegroundColor Red
    
    # Try to fix common issues
    Write-Host "🔧 Attempting to fix encoding issues..." -ForegroundColor Yellow
    try {
        # Remove BOM and ensure UTF-8
        $fixedContent = (Get-Content $CredentialsFile -Raw).Trim()
        $fixedFile = $CredentialsFile.Replace(".json", "-fixed.json")
        $fixedContent | Out-File -Encoding UTF8 -NoNewline $fixedFile
        
        # Test the fixed file
        $testCredentials = Get-Content $fixedFile -Raw | ConvertFrom-Json
        Write-Host "✅ Fixed encoding issues. Using: $fixedFile" -ForegroundColor Green
        $CredentialsFile = $fixedFile
        
        # Check for required fields in fixed credentials
        if (-not $testCredentials.verifier -or -not $testCredentials.encCredentials) {
            Write-Host "⚠️  Warning: Fixed credentials file may be missing required fields" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Could not fix credentials file. Please re-download from 1Password.com" -ForegroundColor Red
        exit 1
    }
}

# Prompt for Connect token if not provided
if (-not $ConnectToken) {
    Write-Host "`n🔑 1Password Connect Token Required" -ForegroundColor Cyan
    Write-Host "You need a 1Password Connect token for the operator to authenticate." -ForegroundColor White
    Write-Host "This should be generated from your 1Password Connect server." -ForegroundColor White
    $ConnectToken = Read-Host "Enter your 1Password Connect token" -MaskInput
}

if (-not $ConnectToken) {
    Write-Host "❌ Connect token is required" -ForegroundColor Red
    exit 1
}

# Clean up the token (remove any trailing whitespace/newlines)
$ConnectToken = $ConnectToken.Trim()

# Create namespace
Write-Host "🔧 Creating 1password namespace..." -ForegroundColor Yellow
try {
    kubectl create namespace 1password --dry-run=client -o yaml | kubectl apply -f -
    Write-Host "✅ 1password namespace created/updated" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create namespace: $_" -ForegroundColor Red
    exit 1
}

# Create credentials secret
Write-Host "🔐 Setting up 1Password credentials..." -ForegroundColor Yellow
try {
    # Base64 encode the credentials file (chart will encode again, so this is correct)
    $credentialsJson = Get-Content $CredentialsFile -Raw
    $encodedCredentials = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($credentialsJson))
    
    Write-Host "✅ Credentials encoded for Helm chart" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to encode credentials: $_" -ForegroundColor Red
    exit 1
}

# Set up token
Write-Host "🔐 Setting up Connect token..." -ForegroundColor Yellow
try {
    # Token is used directly as plain text
    Write-Host "✅ Connect token ready" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to process token: $_" -ForegroundColor Red
    exit 1
}

# Update HelmRelease with credentials and token
Write-Host "🔧 Updating HelmRelease with credentials and token..." -ForegroundColor Yellow
try {
    # Create a temporary patch file
    $patchFile = [System.IO.Path]::GetTempFileName()
    
    $patchData = @{
        spec = @{
            values = @{
                connect = @{
                    create = $true
                    credentials_base64 = $encodedCredentials
                    serviceType = "ClusterIP"
                }
                operator = @{
                    create = $true
                    token = @{
                        value = $ConnectToken
                    }
                    watchAllNamespaces = $true
                }
            }
        }
    } | ConvertTo-Json -Depth 10
    
    # Write patch data to temp file
    $patchData | Out-File -FilePath $patchFile -Encoding UTF8
    
    # Apply the patch
    kubectl patch helmrelease 1password -n 1password --type=merge --patch-file $patchFile
    
    # Clean up temp file
    Remove-Item $patchFile -Force
    
    Write-Host "✅ HelmRelease updated with credentials and token" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update HelmRelease: $_" -ForegroundColor Red
    exit 1
}

# Verify HelmRelease configuration
Write-Host "🔍 Verifying HelmRelease configuration..." -ForegroundColor Yellow
try {
    $helmReleaseValues = kubectl get helmrelease 1password -n 1password -o jsonpath='{.spec.values}' | ConvertFrom-Json
    if ($helmReleaseValues.connect.credentials_base64 -and $helmReleaseValues.operator.token.value) {
        Write-Host "✅ HelmRelease configured with credentials and token" -ForegroundColor Green
    } else {
        Write-Host "⚠️  HelmRelease may be missing credentials or token" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not verify HelmRelease configuration: $_" -ForegroundColor Yellow
}

# Check if 1Password Helm release exists
Write-Host "🔍 Checking for existing 1Password Helm release..." -ForegroundColor Yellow

$helmRelease = kubectl get helmrelease 1password -n 1password --ignore-not-found=true -o name
if ($helmRelease) {
    Write-Host "📦 Found existing 1Password Helm release" -ForegroundColor Green
    
    # Reconcile the release to pick up new secrets
    Write-Host "🔄 Reconciling Helm release to use updated secrets..." -ForegroundColor Yellow
    try {
        # Check if flux CLI is available
        flux version --client | Out-Null
        flux reconcile helmrelease 1password -n 1password
        Write-Host "✅ Helm release reconciled" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Flux CLI not found. Please manually reconcile:" -ForegroundColor Yellow
        Write-Host "   flux reconcile helmrelease 1password -n 1password" -ForegroundColor White
    }
    
    # Wait a moment for pods to come up
    Write-Host "⏳ Waiting for 1Password components to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    # Check final status
    Write-Host "📋 Checking 1Password component status..." -ForegroundColor Cyan
    kubectl get pods -n 1password
} else {
    Write-Host "⚠️  No 1Password Helm release found." -ForegroundColor Yellow
    Write-Host "📋 Your infrastructure should contain:" -ForegroundColor White
    Write-Host "   infrastructure/docker-desktop/1password/release.yaml" -ForegroundColor White
    Write-Host "📋 Make sure Flux is managing your infrastructure directory" -ForegroundColor White
}

Write-Host "`n✅ 1Password secrets setup completed!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor White
Write-Host "1. Verify all components: kubectl get pods -n 1password" -ForegroundColor White
Write-Host "2. Check Connect server: kubectl logs -n 1password -l app.kubernetes.io/component=connect" -ForegroundColor White
Write-Host "3. Check operator logs: kubectl logs -n 1password -l app.kubernetes.io/component=operator" -ForegroundColor White
Write-Host "4. Test with a OnePasswordItem resource" -ForegroundColor White

if ($helmRelease) {
    Write-Host "`n📝 Component Status:" -ForegroundColor Cyan
    kubectl get all -n 1password
}

Write-Host "`n📝 Important Notes:" -ForegroundColor Cyan
Write-Host "• Using direct values in Helm chart (no secrets required)" -ForegroundColor White
Write-Host "• The Helm chart handles Connect server and operator deployment" -ForegroundColor White
Write-Host "• Credentials are base64 encoded and embedded in HelmRelease" -ForegroundColor White
Write-Host "• Connect token is embedded directly in HelmRelease" -ForegroundColor White
Write-Host "• Use 'kubectl describe onepassworditem <name>' to debug item issues" -ForegroundColor White

# Clean up any temporary fixed files
$fixedFile = $CredentialsFile.Replace(".json", "-fixed.json")
if ((Test-Path $fixedFile) -and ($fixedFile -ne $CredentialsFile)) {
    Remove-Item $fixedFile -Force
    Write-Host "🧹 Cleaned up temporary files" -ForegroundColor Gray
}