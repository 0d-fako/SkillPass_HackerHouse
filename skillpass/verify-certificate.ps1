# Certificate Verification Script
# Verify the newly minted certificate

$CERTIFICATE_ID = "0xab8e0b4d885407d184b1754fa9ed2ac532bc743b915294a66f058f50fe076762"
$REGISTRY_ID = "0x6c0bab54d2c4ba3caba62063cb7e972370e60deb9dbbe2fd46f825897bde0bdd"

Write-Host "=== Certificate Verification ===" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Certificate ID: $CERTIFICATE_ID" -ForegroundColor Cyan
Write-Host "🏛️  Registry ID: $REGISTRY_ID" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 Fetching certificate details..." -ForegroundColor Yellow

# Get certificate object details
sui client object $CERTIFICATE_ID

Write-Host ""
Write-Host "🔍 Fetching registry details..." -ForegroundColor Yellow

# Get registry object details
sui client object $REGISTRY_ID

Write-Host ""
Write-Host "✅ Verification Complete!" -ForegroundColor Green