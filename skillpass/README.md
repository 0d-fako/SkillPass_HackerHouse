# SkillPass Smart Contract API Documentation

## Contract Deployment Information

```typescript
export const CONTRACT_CONFIG = {
  PACKAGE_ID: "0x...", // Update after deployment
  REGISTRY_ID: "0x...", // Update after deployment  
  NETWORK: "https://fullnode.testnet.sui.io:443",
  MODULE_NAME: "skillpass::certificate_registry"
};
```

## Data Structures

### Certificate Object
```move
struct Certificate has key, store {
    id: UID,
    student_address: address,
    university: address,
    credential_type: vector<u8>,
    issue_date: u64,
    walrus_evidence_blob: Option<vector<u8>>,
    is_valid: bool,
    grade: Option<vector<u8>>,
}
```

**Frontend Representation:**
```typescript
interface Certificate {
  id: string;
  studentAddress: string;
  university: string;
  credentialType: string;
  issueDate: number;
  walrusEvidenceBlob?: string;
  isValid: boolean;
  grade?: string;
}
```

### Events Emitted
```typescript
// Listen for these events in your frontend
interface CertificateIssued {
  certificate_id: string;
  student: string;
  university: string;
  credential_type: string;
}

interface CertificateRevoked {
  certificate_id: string;
  university: string;
  reason: string;
}
```

## Contract Functions API

### 1. Initialize Registry (Admin Only - Already Called)
```move
public fun create_registry(ctx: &mut TxContext): CertificateRegistry
```

**Usage:** Already deployed. Registry ID provided above.

---

### 2. Add University (Admin Function)
```move
public fun add_university(
    registry: &mut CertificateRegistry,
    university_address: address,
    ctx: &mut TxContext
)
```

**Frontend Implementation:**
```typescript
const addUniversity = (universityAddress: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::add_university`,
    arguments: [
      tx.object(REGISTRY_ID),
      tx.pure(universityAddress)
    ]
  });
  return tx;
};
```

**Expected Response:**
- Success: Transaction hash
- Error: `ENotAuthorized` if caller is not admin

---

### 3. Mint Certificate (University Function)
```move
public fun mint_certificate(
    registry: &mut CertificateRegistry,
    student_address: address,
    credential_type: vector<u8>,
    grade: Option<vector<u8>>,
    ctx: &mut TxContext
): Certificate
```

**Frontend Implementation:**
```typescript
const mintCertificate = (
  studentAddress: string,
  credentialType: string,
  grade?: string
) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::mint_certificate`,
    arguments: [
      tx.object(REGISTRY_ID),
      tx.pure(studentAddress),
      tx.pure(credentialType),
      tx.pure(grade ? [grade] : []) // Option handling
    ]
  });
  return tx;
};
```

**Expected Response:**
- Success: Certificate object created and transferred to student
- Error: `ENotAuthorizedUniversity` if caller is not registered university
- Event: `CertificateIssued` emitted

---

### 4. Mint with Evidence (On-Demand Minting)
```move
public fun mint_with_evidence(
    registry: &mut CertificateRegistry,
    student_address: address,
    credential_type: vector<u8>,
    evidence_blob_id: vector<u8>,
    grade: Option<vector<u8>>,
    ctx: &mut TxContext
): Certificate
```

**Frontend Implementation:**
```typescript
const mintWithEvidence = (
  studentAddress: string,
  credentialType: string,
  walrusBlobId: string,
  grade?: string
) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::mint_with_evidence`,
    arguments: [
      tx.object(REGISTRY_ID),
      tx.pure(studentAddress),
      tx.pure(credentialType),
      tx.pure(walrusBlobId),
      tx.pure(grade ? [grade] : [])
    ]
  });
  return tx;
};
```

**Expected Response:**
- Success: Certificate with evidence blob reference
- Error: `ENotAuthorizedUniversity` or `EInvalidEvidence`

---

### 5. Revoke Certificate (University Function)
```move
public fun revoke_certificate(
    cert: &mut Certificate,
    reason: vector<u8>,
    ctx: &mut TxContext
)
```

**Frontend Implementation:**
```typescript
const revokeCertificate = (certificateId: string, reason: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::revoke_certificate`,
    arguments: [
      tx.object(certificateId),
      tx.pure(reason)
    ]
  });
  return tx;
};
```

**Expected Response:**
- Success: Certificate `is_valid` set to false
- Error: `ENotAuthorizedUniversity` if caller is not the issuing university
- Event: `CertificateRevoked` emitted

---

### 6. Verify Certificate (Public Read-Only)
```move
public fun get_certificate_info(cert: &Certificate): (
    address, // student
    address, // university  
    vector<u8>, // credential_type
    u64, // issue_date
    bool // is_valid
)
```

**Frontend Implementation:**
```typescript
const verifyCertificate = async (certificateId: string) => {
  try {
    const response = await suiClient.getObject({
      id: certificateId,
      options: { 
        showContent: true,
        showType: true,
        showOwner: true 
      }
    });
    
    if (response.data?.content?.dataType === 'moveObject') {
      const fields = response.data.content.fields;
      return {
        isValid: fields.is_valid,
        student: fields.student_address,
        university: fields.university,
        credentialType: fields.credential_type,
        issueDate: new Date(parseInt(fields.issue_date)),
        grade: fields.grade?.[0] || null
      };
    }
    
    return null;
  } catch (error) {
    console.error('Certificate verification failed:', error);
    return null;
  }
};
```

**Expected Response:**
```typescript
interface VerificationResult {
  isValid: boolean;
  student: string;
  university: string;
  credentialType: string;
  issueDate: Date;
  grade?: string;
}
```

## Query Functions for Frontend

### Get All Certificates for Student
```typescript
const getStudentCertificates = async (studentAddress: string) => {
  const response = await suiClient.getOwnedObjects({
    owner: studentAddress,
    filter: {
      StructType: `${PACKAGE_ID}::certificate_registry::Certificate`
    },
    options: { showContent: true }
  });
  
  return response.data.map(obj => ({
    id: obj.data.objectId,
    ...obj.data.content.fields
  }));
};
```

### Get Certificates Issued by University
```typescript
const getUniversityCertificates = async (universityAddress: string) => {
  // Query using GraphQL or events
  const events = await suiClient.queryEvents({
    query: {
      MoveEventType: `${PACKAGE_ID}::certificate_registry::CertificateIssued`
    },
    limit: 100
  });
  
  return events.data.filter(event => 
    event.parsedJson.university === universityAddress
  );
};
```

## Error Codes

```move
const ENotAuthorized: u64 = 1;
const ENotAuthorizedUniversity: u64 = 2;
const EInvalidCertificate: u64 = 3;
const EInvalidEvidence: u64 = 4;
const ECertificateNotFound: u64 = 5;
```

**Error Handling:**
```typescript
try {
  await signAndExecuteTransaction({ transactionBlock: tx });
} catch (error) {
  if (error.message.includes('ENotAuthorizedUniversity')) {
    alert('Only authorized universities can mint certificates');
  } else if (error.message.includes('EInvalidCertificate')) {
    alert('Certificate data is invalid');
  }
  // Handle other errors
}
```

## Event Subscription

```typescript
const subscribeToEvents = () => {
  // Certificate issued events
  suiClient.subscribeEvent({
    filter: {
      MoveEventType: `${PACKAGE_ID}::certificate_registry::CertificateIssued`
    },
    onMessage: (event) => {
      console.log('New certificate:', event.parsedJson);
      // Update UI - refresh student dashboard
    }
  });

  // Certificate revoked events
  suiClient.subscribeEvent({
    filter: {
      MoveEventType: `${PACKAGE_ID}::certificate_registry::CertificateRevoked`
    },
    onMessage: (event) => {
      console.log('Certificate revoked:', event.parsedJson);
      // Update UI - mark certificate as invalid
    }
  });
};
```

## Test Data

```typescript
export const TEST_DATA = {
  // Test addresses (update with real ones after deployment)
  TEST_UNIVERSITY: "0x...",
  TEST_STUDENT: "0x...",
  TEST_ADMIN: "0x...",
  
  // Sample data for testing
  SAMPLE_CREDENTIALS: [
    "Bachelor of Science in Computer Science",
    "Master of Business Administration",
    "Certificate in Data Science",
    "Bachelor of Engineering"
  ],
  
  SAMPLE_GRADES: [
    "First Class",
    "Upper Second Class",
    "Lower Second Class", 
    "Third Class",
    "Pass",
    "Merit",
    "Distinction"
  ]
};
```

## Integration Checklist

- [ ] Contract deployed to testnet
- [ ] Package ID and Registry ID updated in this README
- [ ] Test university added to registry
- [ ] Sample certificates minted for testing
- [ ] Event subscription tested
- [ ] Error handling patterns documented
- [ ] All function examples tested with actual contract

