// Test script to validate the TypeScript certificate minting functions
import { createMintCertificateTransaction, createMintCertificateNoGradeTransaction } from './test-mint-certificate';

console.log('🧪 Testing TypeScript certificate minting functions...\n');

try {
  // Test certificate with grade
  console.log('📋 Testing certificate WITH grade...');
  const txWithGrade = createMintCertificateTransaction();
  console.log('✅ Transaction with grade created successfully');
  console.log(`   Transaction type: ${txWithGrade.constructor.name}`);
  
  // Test certificate without grade  
  console.log('\n📋 Testing certificate WITHOUT grade...');
  const txNoGrade = createMintCertificateNoGradeTransaction();
  console.log('✅ Transaction without grade created successfully');
  console.log(`   Transaction type: ${txNoGrade.constructor.name}`);
  
  console.log('\n🎉 All TypeScript tests passed!');
  console.log('\n📝 Next steps:');
  console.log('   1. These transactions can now be signed with a Sui wallet');
  console.log('   2. Execute them on the Sui testnet');
  console.log('   3. Verify certificate creation in the registry');
  
} catch (error) {
  console.error('❌ Test failed:', error);
  process.exit(1);
}