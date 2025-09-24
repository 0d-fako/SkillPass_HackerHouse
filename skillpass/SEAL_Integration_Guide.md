# SkillPass SEAL Integration Guide

## Overview
This guide demonstrates how to integrate Microsoft SEAL homomorphic encryption with the SkillPass smart contract for privacy-preserving certificate management.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │  Smart Contract  │    │   SEAL Engine   │
│   (React/TS)    │────│   (Move/Sui)     │────│   (Off-chain)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
   User Interface          Encrypted Storage         Homomorphic Ops
```

## SEAL Setup

### 1. Install SEAL Dependencies

```bash
# For Node.js/TypeScript frontend
npm install node-seal
npm install @types/node-seal

# For Python backend (if using)
pip install microsoft-seal
```

### 2. SEAL Context Configuration

```typescript
// seal-config.ts
import SEAL from 'node-seal';

export interface SEALConfig {
  polyModulusDegree: number;
  bitSizes: number[];
  scheme: 'BFV' | 'CKKS';
}

export const DEFAULT_SEAL_CONFIG: SEALConfig = {
  polyModulusDegree: 4096,
  bitSizes: [40, 40, 40],
  scheme: 'BFV' // For integer operations (certificate data)
};

export async function initializeSEAL(config: SEALConfig = DEFAULT_SEAL_CONFIG) {
  const seal = await SEAL();
  
  const schemeType = seal.SchemeType.bfv;
  const securityLevel = seal.SecurityLevel.tc128;
  
  const parms = seal.EncryptionParameters(schemeType);
  parms.setPolyModulusDegree(config.polyModulusDegree);
  parms.setCoeffModulus(seal.CoeffModulus.BFVDefault(config.polyModulusDegree));
  parms.setPlainModulus(seal.PlainModulus.Batching(config.polyModulusDegree, 20));
  
  const context = seal.Context(parms, true, securityLevel);
  
  const keyGenerator = seal.KeyGenerator(context);
  const publicKey = keyGenerator.createPublicKey();
  const secretKey = keyGenerator.secretKey();
  
  const encryptor = seal.Encryptor(context, publicKey);
  const decryptor = seal.Decryptor(context, secretKey);
  const encoder = seal.BatchEncoder(context);
  
  return {
    seal,
    context,
    publicKey,
    secretKey,
    encryptor,
    decryptor,
    encoder,
    keyGenerator
  };
}
```

### 3. Certificate Encryption Service

```typescript
// certificate-encryption.service.ts
import { initializeSEAL, SEALConfig } from './seal-config';
import crypto from 'crypto';

export class CertificateEncryption {
  private sealComponents: any;
  private initialized: boolean = false;

  async initialize(config?: SEALConfig) {
    this.sealComponents = await initializeSEAL(config);
    this.initialized = true;
  }

  // Encrypt certificate data
  async encryptCertificateData(data: {
    credentialType: string;
    grade?: string;
  }): Promise<{
    encryptedCredentialType: Uint8Array;
    encryptedGrade?: Uint8Array;
    encryptionParams: Uint8Array;
    publicKeyHash: Uint8Array;
  }> {
    if (!this.initialized) throw new Error('SEAL not initialized');

    const { encryptor, encoder, context, publicKey } = this.sealComponents;

    // Convert strings to integer arrays for BFV encryption
    const credentialTypeBytes = Buffer.from(data.credentialType, 'utf8');
    const credentialTypeInts = Array.from(credentialTypeBytes);

    // Encrypt credential type
    const credentialTypePlain = encoder.encode(Int32Array.from(credentialTypeInts));
    const encryptedCredentialType = encryptor.encrypt(credentialTypePlain);

    let encryptedGrade: any = null;
    if (data.grade) {
      const gradeBytes = Buffer.from(data.grade, 'utf8');
      const gradeInts = Array.from(gradeBytes);
      const gradePlain = encoder.encode(Int32Array.from(gradeInts));
      encryptedGrade = encryptor.encrypt(gradePlain);
    }

    // Serialize encryption parameters
    const paramsBuffer = Buffer.from(context.parametersString());
    
    // Create public key hash
    const publicKeyBuffer = Buffer.from(publicKey.save());
    const publicKeyHash = crypto.createHash('sha256').update(publicKeyBuffer).digest();

    return {
      encryptedCredentialType: encryptedCredentialType.save(),
      encryptedGrade: encryptedGrade ? encryptedGrade.save() : undefined,
      encryptionParams: paramsBuffer,
      publicKeyHash: publicKeyHash
    };
  }

  // Decrypt certificate data
  async decryptCertificateData(encryptedData: {
    encryptedCredentialType: Uint8Array;
    encryptedGrade?: Uint8Array;
    encryptionParams: Uint8Array;
    publicKeyHash: Uint8Array;
  }): Promise<{
    credentialType: string;
    grade?: string;
  }> {
    if (!this.initialized) throw new Error('SEAL not initialized');

    const { decryptor, encoder, seal } = this.sealComponents;

    // Load and decrypt credential type
    const credentialTypeCipher = seal.CipherText();
    credentialTypeCipher.load(encryptedData.encryptedCredentialType);
    
    const credentialTypePlain = decryptor.decrypt(credentialTypeCipher);
    const credentialTypeInts = encoder.decode(credentialTypePlain);
    const credentialType = Buffer.from(credentialTypeInts).toString('utf8');

    let grade: string | undefined;
    if (encryptedData.encryptedGrade) {
      const gradeCipher = seal.CipherText();
      gradeCipher.load(encryptedData.encryptedGrade);
      
      const gradePlain = decryptor.decrypt(gradeCipher);
      const gradeInts = encoder.decode(gradePlain);
      grade = Buffer.from(gradeInts).toString('utf8');
    }

    return { credentialType, grade };
  }

  // Get public key for sharing (allows others to encrypt for this instance)
  getPublicKey(): Uint8Array {
    if (!this.initialized) throw new Error('SEAL not initialized');
    return this.sealComponents.publicKey.save();
  }

  // Get encryption parameters for verification
  getEncryptionParams(): Uint8Array {
    if (!this.initialized) throw new Error('SEAL not initialized');
    return Buffer.from(this.sealComponents.context.parametersString());
  }
}
```

### 4. Smart Contract Integration

```typescript
// skillpass-seal.service.ts
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { CertificateEncryption } from './certificate-encryption.service';

export class SkillPassSEAL {
  private encryption: CertificateEncryption;
  private packageId: string;
  private registryId: string;

  constructor(packageId: string, registryId: string) {
    this.packageId = packageId;
    this.registryId = registryId;
    this.encryption = new CertificateEncryption();
  }

  async initialize() {
    await this.encryption.initialize();
  }

  // Mint encrypted certificate
  async mintEncryptedCertificate(params: {
    studentAddress: string;
    credentialType: string;
    grade?: string;
    accessPolicy?: string[];
  }) {
    // 1. Encrypt the sensitive data using SEAL
    const encryptedData = await this.encryption.encryptCertificateData({
      credentialType: params.credentialType,
      grade: params.grade
    });

    // 2. Create access policy (addresses that can decrypt)
    const accessPolicy = JSON.stringify(params.accessPolicy || []);

    // 3. Build transaction
    const tx = new TransactionBlock();
    
    tx.moveCall({
      target: `${this.packageId}::certificate_registry::mint_encrypted_certificate`,
      arguments: [
        tx.object(this.registryId),
        tx.pure(params.studentAddress),
        tx.pure(Array.from(encryptedData.encryptedCredentialType)),
        tx.pure(encryptedData.encryptedGrade ? [Array.from(encryptedData.encryptedGrade)] : []),
        tx.pure(Array.from(encryptedData.encryptionParams)),
        tx.pure(Array.from(encryptedData.publicKeyHash)),
        tx.pure(accessPolicy),
        tx.object('0x6') // Clock
      ]
    });

    return tx;
  }

  // Get and decrypt certificate
  async getCertificateDecrypted(certificateId: string) {
    // 1. Get encrypted certificate data from blockchain
    const response = await suiClient.getObject({
      id: certificateId,
      options: { showContent: true }
    });

    if (response.data?.content?.dataType !== 'moveObject') {
      throw new Error('Certificate not found');
    }

    const fields = response.data.content.fields;

    // 2. Extract encrypted data
    const encryptedData = {
      encryptedCredentialType: new Uint8Array(fields.encrypted_credential_type),
      encryptedGrade: fields.encrypted_grade?.[0] ? new Uint8Array(fields.encrypted_grade[0]) : undefined,
      encryptionParams: new Uint8Array(fields.encryption_params),
      publicKeyHash: new Uint8Array(fields.public_key_hash)
    };

    // 3. Decrypt using SEAL
    const decryptedData = await this.encryption.decryptCertificateData(encryptedData);

    // 4. Return combined data
    return {
      id: certificateId,
      studentAddress: fields.student_address,
      university: fields.university,
      issueDate: new Date(parseInt(fields.issue_date)),
      isValid: fields.is_valid,
      // Decrypted sensitive data
      credentialType: decryptedData.credentialType,
      grade: decryptedData.grade,
      // Metadata
      accessPolicy: JSON.parse(fields.access_policy)
    };
  }

  // Verify access without decrypting
  async verifyDecryptionAccess(certificateId: string, accessor: string) {
    const tx = new TransactionBlock();
    
    tx.moveCall({
      target: `${this.packageId}::certificate_registry::verify_decryption_access`,
      arguments: [
        tx.object(certificateId),
        tx.pure(accessor),
        tx.pure([]) // Access proof (placeholder)
      ]
    });

    return tx;
  }
}
```

### 5. Usage Example

```typescript
// app.ts - Example usage
import { SkillPassSEAL } from './skillpass-seal.service';

async function main() {
  const skillPassSeal = new SkillPassSEAL(
    '0x86d3de7d2236b8158edee702a9e4cde816242c57b25e4e4e9a759dadd6ac9e00',
    '0xfda14bfe14d6bfc474eaa2245c3cb75b4cb62b579d837091af4b32984e635d6d'
  );

  await skillPassSeal.initialize();

  // University mints encrypted certificate
  const mintTx = await skillPassSeal.mintEncryptedCertificate({
    studentAddress: '0x...',
    credentialType: 'Master of Computer Science',
    grade: 'First Class Honours',
    accessPolicy: ['0x...student', '0x...university', '0x...verifier']
  });

  // Student or authorized party decrypts certificate
  const certificateData = await skillPassSeal.getCertificateDecrypted('0x...certificateId');
  console.log('Decrypted Certificate:', certificateData);
}
```

## Security Considerations

### 1. Key Management
- **Private Keys**: Store securely, never expose in frontend
- **Public Keys**: Can be shared for encryption
- **Key Rotation**: Implement periodic key updates

### 2. Access Control
- **On-Chain Verification**: Use smart contract access control
- **Off-Chain Validation**: Additional checks in application layer
- **Audit Trail**: Log all access attempts

### 3. Performance
- **Encryption Overhead**: SEAL operations are computationally intensive
- **Data Size**: Encrypted data is larger than plaintext
- **Batch Operations**: Process multiple certificates together when possible

## Benefits of SEAL Integration

1. **Privacy**: Sensitive certificate data encrypted at rest
2. **Verification**: Can verify certificates without decrypting
3. **Compliance**: Meets data protection requirements
4. **Trust**: Cryptographic proof of authenticity
5. **Flexibility**: Support for homomorphic operations on encrypted data

## Next Steps

1. **Test Integration**: Deploy updated contract to testnet
2. **Performance Testing**: Measure encryption/decryption times
3. **Key Management**: Implement secure key storage
4. **UI Integration**: Add encryption controls to frontend
5. **Documentation**: Update API docs with SEAL functions