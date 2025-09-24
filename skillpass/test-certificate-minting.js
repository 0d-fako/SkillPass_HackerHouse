// Test certificate minting functionality - SIMPLIFIED VERSION
// This demonstrates how to mint a basic certificate with just discipline info

const PACKAGE_ID = "0xf1cb82954194f281b4bcddee3b8922b81322cd742d2ab23d169dfaf11883c736";
const REGISTRY_ID = "0x6c0bab54d2c4ba3caba62063cb7e972370e60deb9dbbe2fd46f825897bde0bdd";
const ADMIN_ADDRESS = "0x83b3e15b0f43aacdbd39ede604391ef9720df83b33420fb72deef7f8e795cbe9";

// Function to create a simple certificate mint transaction (discipline only)
function createSimpleCertificateTransaction() {
  // Using @mysten/sui.js
  const { TransactionBlock } = require('@mysten/sui.js/transactions');
  
  const tx = new TransactionBlock();
  
  // Simple certificate data - just the discipline
  const discipline = "Computer Science";
  const credentialType = Array.from(Buffer.from(discipline, 'utf8'));
  
  // SEAL encryption parameters (simplified for testing)
  const encryptionParams = Array.from(Buffer.from("basic_seal_params", 'utf8'));
  const publicKeyHash = Array.from(Buffer.from("test_key_hash_123456", 'utf8'));
  const accessPolicy = Array.from(Buffer.from('["admin"]', 'utf8'));
  
  // Call the mint_encrypted_certificate function
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::mint_encrypted_certificate`,
    arguments: [
      tx.object(REGISTRY_ID),                    // registry
      tx.pure(ADMIN_ADDRESS),                    // student_address (admin in this test)
      tx.pure(credentialType),                   // encrypted_credential_type (discipline)
      tx.pure([]),                               // encrypted_grade (Option::None - no grade)
      tx.pure(encryptionParams),                 // encryption_params
      tx.pure(publicKeyHash),                    // public_key_hash
      tx.pure(accessPolicy),                     // access_policy
      tx.object('0x6')                           // clock
    ]
  });
  
  return tx;
}

// Function for multiple disciplines
function createMultipleCertificatesTransaction() {
  const disciplines = [
    "Mathematics",
    "Physics", 
    "Chemistry",
    "Biology"
  ];
  
  const { TransactionBlock } = require('@mysten/sui.js/transactions');
  const tx = new TransactionBlock();
  
  disciplines.forEach((discipline, index) => {
    const credentialType = Array.from(Buffer.from(discipline, 'utf8'));
    const encryptionParams = Array.from(Buffer.from(`seal_params_${index}`, 'utf8'));
    const publicKeyHash = Array.from(Buffer.from(`key_hash_${index}_${Date.now()}`, 'utf8'));
    const accessPolicy = Array.from(Buffer.from(`["admin","${discipline.toLowerCase()}"]`, 'utf8'));
    
    tx.moveCall({
      target: `${PACKAGE_ID}::certificate_registry::mint_encrypted_certificate`,
      arguments: [
        tx.object(REGISTRY_ID),
        tx.pure(ADMIN_ADDRESS),
        tx.pure(credentialType),
        tx.pure([]),                             // No grade
        tx.pure(encryptionParams),
        tx.pure(publicKeyHash),
        tx.pure(accessPolicy),
        tx.object('0x6')
      ]
    });
  });
  
  return tx;
}

// Usage instructions
console.log("=== SkillPass Certificate Minting Test ===");
console.log("");
console.log("Contract Details:");
console.log("📦 Package ID:", PACKAGE_ID);
console.log("🏛️  Registry ID:", REGISTRY_ID);
console.log("👤 Admin Address:", ADMIN_ADDRESS);
console.log("");
console.log("🔐 SEAL Enhancement: ACTIVE");
console.log("✅ Deployment Status: LIVE ON TESTNET");
console.log("");
console.log("To test certificate minting:");
console.log("1. Install dependencies: npm install @mysten/sui.js");
console.log("2. Import this file in your frontend");
console.log("3. Call createMintTransaction() or createMintTransactionNoGrade()");
console.log("4. Sign and execute with your Sui wallet");
console.log("");
console.log("Expected Result:");
console.log("✅ Certificate minted successfully");
console.log("✅ Certificate transferred to admin address");
console.log("✅ CertificateIssued event emitted");
console.log("✅ Registry total_certificates incremented");

// Export functions for use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    createSimpleCertificateTransaction,
    createMultipleCertificatesTransaction,
    PACKAGE_ID,
    REGISTRY_ID,
    ADMIN_ADDRESS
  };
}