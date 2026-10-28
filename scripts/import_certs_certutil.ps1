$ErrorActionPreference = "Stop"
$certsDir = Join-Path $PSScriptRoot "..\certs"

$devCaCert = Join-Path $certsDir "ca\ca.crt"
$prodS3Cert = Join-Path $certsDir "prod-s3-internal.crt"

if (Test-Path $devCaCert) {
    Write-Host "Importing Dev Root CA ($devCaCert)..." -ForegroundColor Cyan
    certutil.exe -addstore -f root $devCaCert
} else {
    Write-Warning "Dev Root CA not found at $devCaCert. Run ./scripts/generate_certs.sh first."
}

if (Test-Path $prodS3Cert) {
    Write-Host "Importing Prod Internal S3 CA ($prodS3Cert)..." -ForegroundColor Cyan
    certutil.exe -addstore -f root $prodS3Cert
}

Write-Host "`nCertificates successfully imported into Windows Root store!" -ForegroundColor Green
