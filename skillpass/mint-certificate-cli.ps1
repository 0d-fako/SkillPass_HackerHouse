# PowerShell script to mint a certificate with discipline only
# SkillPass Certificate Minting Script

Write-Host "=== SkillPass Certificate Minting ===" -ForegroundColor Green
Write-Host ""

# Contract configuration
$PACKAGE_ID = "0xf1cb82954194f281b4bcddee3b8922b81322cd742d2ab23d169dfaf11883c736"
$REGISTRY_ID = "0x6c0bab54d2c4ba3caba62063cb7e972370e60deb9dbbe2fd46f825897bde0bdd"
$ADMIN_ADDRESS = "0x83b3e15b0f43aacdbd39ede604391ef9720df83b33420fb72deef7f8e795cbe9"
$DISCIPLINE = "Computer Science"

Write-Host "📦 Package ID: $PACKAGE_ID" -ForegroundColor Cyan
Write-Host "🏛️  Registry ID: $REGISTRY_ID" -ForegroundColor Cyan
Write-Host "👤 Admin Address: $ADMIN_ADDRESS" -ForegroundColor Cyan
Write-Host "📚 Discipline: $DISCIPLINE" -ForegroundColor Cyan
Write-Host ""

# Convert discipline to bytes for the contract
$disciplineBytes = [System.Text.Encoding]::UTF8.GetBytes($DISCIPLINE)
$disciplineHex = ($disciplineBytes | ForEach-Object { "{0:x2}" -f $_ }) -join ""

Write-Host "🔄 Converting discipline to bytes..." -ForegroundColor Yellow
Write-Host "Discipline bytes: $disciplineHex" -ForegroundColor Gray
Write-Host ""

# Create basic SEAL parameters
$encryptionParams = [System.Text.Encoding]::UTF8.GetBytes("basic_seal_params")
$encryptionParamsHex = ($encryptionParams | ForEach-Object { "{0:x2}" -f $_ }) -join ""

$publicKeyHash = [System.Text.Encoding]::UTF8.GetBytes("test_key_hash_123456")
$publicKeyHashHex = ($publicKeyHash | ForEach-Object { "{0:x2}" -f $_ }) -join ""

$accessPolicy = [System.Text.Encoding]::UTF8.GetBytes('["admin"]')
$accessPolicyHex = ($accessPolicy | ForEach-Object { "{0:x2}" -f $_ }) -join ""

Write-Host "🔐 SEAL Parameters prepared:" -ForegroundColor Yellow
Write-Host "Encryption params: $encryptionParamsHex" -ForegroundColor Gray
Write-Host "Public key hash: $publicKeyHashHex" -ForegroundColor Gray
Write-Host "Access policy: $accessPolicyHex" -ForegroundColor Gray
Write-Host ""

# Construct the Sui CLI command
$command = @"
sui client call `
--package $PACKAGE_ID `
--module certificate_registry `
--function mint_encrypted_certificate `
--args $REGISTRY_ID $ADMIN_ADDRESS "[$($disciplineBytes -join ',')]" "[]" "[$($encryptionParams -join ',')]" "[$($publicKeyHash -join ',')]" "[$($accessPolicy -join ',')]" 0x6 `
--gas-budget 100000000
"@

Write-Host "🚀 Executing certificate minting command..." -ForegroundColor Green
Write-Host ""
Write-Host "Command:" -ForegroundColor Yellow
Write-Host $command -ForegroundColor Gray
Write-Host ""

# Execute the command
try {
    Write-Host "⏳ Minting certificate..." -ForegroundColor Yellow
    $result = Invoke-Expression $command
    
    Write-Host "✅ Certificate minting completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Result:" -ForegroundColor Cyan
    Write-Host $result
    
    Write-Host ""
    Write-Host "🎉 Success! Certificate with discipline '$DISCIPLINE' has been minted and assigned to admin." -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error during certificate minting:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Make sure you have an active Sui wallet configured" -ForegroundColor Gray
    Write-Host "2. Ensure you have sufficient SUI for gas fees" -ForegroundColor Gray
    Write-Host "3. Verify you're connected to Sui testnet" -ForegroundColor Gray
    Write-Host "4. Check that the contract is still deployed at the specified address" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Minting Process Complete ===" -ForegroundColor Green