"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createMintCertificateTransaction = createMintCertificateTransaction;
exports.createMintCertificateNoGradeTransaction = createMintCertificateNoGradeTransaction;
// TypeScript test for certificate minting
var transactions_1 = require("@mysten/sui/transactions");
// Contract configuration
var PACKAGE_ID = "0xf1cb82954194f281b4bcddee3b8922b81322cd742d2ab23d169dfaf11883c736";
var REGISTRY_ID = "0x6c0bab54d2c4ba3caba62063cb7e972370e60deb9dbbe2fd46f825897bde0bdd";
var ADMIN_ADDRESS = "0x83b3e15b0f43aacdbd39ede604391ef9720df83b33420fb72deef7f8e795cbe9";
// Test function to mint certificate
function createMintCertificateTransaction() {
    var tx = new transactions_1.Transaction();
    // Convert strings to byte arrays
    var credentialType = Array.from(Buffer.from("Bachelor of Computer Science", 'utf8'));
    var grade = Array.from(Buffer.from("First Class", 'utf8'));
    tx.moveCall({
        target: "".concat(PACKAGE_ID, "::certificate_registry::mint_certificate"),
        arguments: [
            tx.object(REGISTRY_ID), // registry
            tx.pure.address(ADMIN_ADDRESS), // student_address
            tx.pure.vector('u8', credentialType), // credential_type: vector<u8>
            tx.pure.option('vector<u8>', grade), // grade: Option<vector<u8>> - Some case
            tx.object('0x6') // clock
        ]
    });
    return tx;
}
// Test function for certificate without grade
function createMintCertificateNoGradeTransaction() {
    var tx = new transactions_1.Transaction();
    var credentialType = Array.from(Buffer.from("Bachelor of Computer Science", 'utf8'));
    tx.moveCall({
        target: "".concat(PACKAGE_ID, "::certificate_registry::mint_certificate"),
        arguments: [
            tx.object(REGISTRY_ID), // registry
            tx.pure.address(ADMIN_ADDRESS), // student_address  
            tx.pure.vector('u8', credentialType), // credential_type: vector<u8>
            tx.pure.option('vector<u8>', null), // grade: Option<vector<u8>> - None case
            tx.object('0x6') // clock
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
