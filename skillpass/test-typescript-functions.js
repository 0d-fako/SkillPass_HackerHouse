"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// Test script to validate the TypeScript certificate minting functions
var test_mint_certificate_1 = require("./test-mint-certificate");
console.log('🧪 Testing TypeScript certificate minting functions...\n');
try {
    // Test certificate with grade
    console.log('📋 Testing certificate WITH grade...');
    var txWithGrade = (0, test_mint_certificate_1.createMintCertificateTransaction)();
    console.log('✅ Transaction with grade created successfully');
    console.log("   Transaction type: ".concat(txWithGrade.constructor.name));
    // Test certificate without grade  
    console.log('\n📋 Testing certificate WITHOUT grade...');
    var txNoGrade = (0, test_mint_certificate_1.createMintCertificateNoGradeTransaction)();
    console.log('✅ Transaction without grade created successfully');
    console.log("   Transaction type: ".concat(txNoGrade.constructor.name));
    console.log('\n🎉 All TypeScript tests passed!');
    console.log('\n📝 Next steps:');
    console.log('   1. These transactions can now be signed with a Sui wallet');
    console.log('   2. Execute them on the Sui testnet');
    console.log('   3. Verify certificate creation in the registry');
}
catch (error) {
    console.error('❌ Test failed:', error);
    process.exit(1);
}
