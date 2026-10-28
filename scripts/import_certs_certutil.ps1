$ErrorActionPreference = "Stop"

# Ensure script is running with Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevating process to Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    exit 0
}

$certsDir = Join-Path $PSScriptRoot "..\certs"

$devCaCert = Join-Path $certsDir "ca\ca.crt"
$prodS3Cert = Join-Path $certsDir "prod-s3-internal.crt"

# 1. Clean up old/stale dev certificates from Root store
Write-Host "Checking for old dev certificates to clean up..." -ForegroundColor Cyan

# Known old self-signed cert fingerprints (MinIO and Backend CN=localhost)
$knownOldThumbprints = @(
    "DDA57D070FD8A80001AD70DEDAE3919B27D23E5D", # old dev-minio-ca
    "2B8C3D99B8C4B72BF24AF9C301B9400579FFB5C8"  # old dev-backend-ca
)

foreach ($tp in $knownOldThumbprints) {
    $existing = Get-Item "Cert:\LocalMachine\Root\$tp" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Removing legacy dev cert ($tp - $($existing.Subject))..." -ForegroundColor Yellow
        certutil.exe -delstore root $tp | Out-Null
    }
}

# Also remove previous Accelerator-Dev-Root-CA (if re-generating new keys)
$existingDevCas = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -eq "CN=Accelerator-Dev-Root-CA" }
foreach ($cert in $existingDevCas) {
    if (Test-Path $devCaCert) {
        $newCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($devCaCert)
        if ($cert.Thumbprint -ne $newCert.Thumbprint) {
            Write-Host "Removing outdated Accelerator-Dev-Root-CA ($($cert.Thumbprint))..." -ForegroundColor Yellow
            certutil.exe -delstore root $cert.Thumbprint | Out-Null
        }
    }
}

# 2. Import current Dev Root CA
if (Test-Path $devCaCert) {
    Write-Host "Importing Dev Root CA ($devCaCert)..." -ForegroundColor Cyan
    certutil.exe -addstore -f root $devCaCert
} else {
    Write-Warning "Dev Root CA not found at $devCaCert. Run ./scripts/generate_certs.sh first."
}

# 3. Import Prod Internal S3 CA
if (Test-Path $prodS3Cert) {
    Write-Host "Importing Prod Internal S3 CA ($prodS3Cert)..." -ForegroundColor Cyan
    certutil.exe -addstore -f root $prodS3Cert
}

Write-Host "`nCertificates successfully updated in Windows Root store!" -ForegroundColor Green
