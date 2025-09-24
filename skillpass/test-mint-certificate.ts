// TypeScript test for certificate minting
import { TransactionBlock } from '@mysten/sui.js/transactions';

// Contract configuration
const PACKAGE_ID = "0xf1cb82954194f281b4bcddee3b8922b81322cd742d2ab23d169dfaf11883c736";
const REGISTRY_ID = "0x6c0bab54d2c4ba3caba62063cb7e972370e60deb9dbbe2fd46f825897bde0bdd";
const ADMIN_ADDRESS = "0x83b3e15b0f43aacdbd39ede604391ef9720df83b33420fb72deef7f8e795cbe9";

// Test function to mint certificate
export function createMintCertificateTransaction() {
  const tx = new TransactionBlock();
  
  // Convert strings to byte arrays
  const credentialType = Array.from(Buffer.from("Bachelor of Computer Science", 'utf8'));
  const grade = Array.from(Buffer.from("First Class", 'utf8'));
  
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::mint_certificate`,
    arguments: [
      tx.object(REGISTRY_ID),                    // registry
      tx.pure(ADMIN_ADDRESS),                    // student_address
      tx.pure(credentialType),                   // credential_type: vector<u8>
      tx.pure([grade]),                          // grade: Option<vector<u8>> - Some case
      tx.object('0x6')                           // clock
    ]
  });
  
  return tx;
}

// Test function for certificate without grade
export function createMintCertificateNoGradeTransaction() {
  const tx = new TransactionBlock();
  
  const credentialType = Array.from(Buffer.from("Bachelor of Computer Science", 'utf8'));
  
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::mint_certificate`,
    arguments: [
      tx.object(REGISTRY_ID),                    // registry
      tx.pure(ADMIN_ADDRESS),                    // student_address  
      tx.pure(credentialType),                   // credential_type: vector<u8>
      tx.pure([]),                               // grade: Option<vector<u8>> - None case
      tx.object('0x6')                           // clock
    ]
  });
  
  return tx;
}

// Usage instructions:
console.log("To use this transaction:");
console.log("1. Import this file in your frontend");
console.log("2. Call createMintCertificateTransaction()");
console.log("3. Sign and execute with your wallet");
console.log("");
console.log("Contract Details:");
console.log("Package ID:", PACKAGE_ID);
console.log("Registry ID:", REGISTRY_ID);
console.log("Admin Address:", ADMIN_ADDRESS);