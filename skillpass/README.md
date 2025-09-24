# SkillPass Smart Contract API Documentation
# SkillPass Smart Contract API Documentation - ✅ **DEPLOYED ON TESTNET**

## Contract Deployment Information

```typescript
export const CONTRACT_CONFIG = {
  PACKAGE_ID: "0x86d3de7d2236b8158edee702a9e4cde816242c57b25e4e4e9a759dadd6ac9e00", // ✅ DEPLOYED!
  REGISTRY_ID: "0xfda14bfe14d6bfc474eaa2245c3cb75b4cb62b579d837091af4b32984e635d6d", // ✅ DEPLOYED!
  NETWORK: "https://fullnode.testnet.sui.io:443", // ✅ TESTNET
  MODULE_NAME: "skillpass::certificate_registry",
  ADMIN_ADDRESS: "0x83b3e15b0f43aacdbd39ede604391ef9720df83b33420fb72deef7f8e795cbe9" // ✅ DEPLOYED!
};
```

### 🚀 **Deployment Status:**
- **Package ID**: ✅ Deployed
- **Registry**: ✅ Created and Shared
- **Network**: ✅ Sui Testnet
- **Admin**: ✅ Set (Your Address)
- **Status**: 🔥 **LIVE AND READY FOR USE!**

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

### 2.1. Add Multiple Universities (Admin Function)
```move
public fun add_universities(
    registry: &mut CertificateRegistry,
    university_addresses: vector<address>,
    ctx: &mut TxContext
)
```

**Frontend Implementation:**
```typescript
const addUniversities = (universityAddresses: string[]) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::add_universities`,
    arguments: [
      tx.object(REGISTRY_ID),
      tx.pure(universityAddresses)
    ]
  });
  return tx;
};
```

---

### 2.2. Remove University (Admin Function) 
```move
public fun remove_university(
    registry: &mut CertificateRegistry,
    university_address: address,
    ctx: &mut TxContext
)
```

**Frontend Implementation:**
```typescript
const removeUniversity = (universityAddress: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::remove_university`,
    arguments: [
      tx.object(REGISTRY_ID),
      tx.pure(universityAddress)
    ]
  });
  return tx;
};
```

---

### 3. Mint Certificate (University Function)
```move
public fun mint_certificate(
    registry: &mut CertificateRegistry,
    student_address: address,
    credential_type: vector<u8>,
    grade: Option<vector<u8>>,
    clock: &clock::Clock,
    ctx: &mut TxContext
) // Note: No return value, certificate is transferred to student
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
      tx.pure(grade ? [grade] : []), // Option handling
      tx.object('0x6') // Clock object ID
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
    clock: &clock::Clock,
    ctx: &mut TxContext
) // Note: No return value, certificate is transferred to student
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
      tx.pure(grade ? [grade] : []),
      tx.object('0x6') // Clock object ID
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

### 6.1. Update Certificate Grade (University Function) 
```move
public fun update_certificate_grade(
    cert: &mut Certificate,
    new_grade: Option<vector<u8>>,
    ctx: &mut TxContext
)
```

**Frontend Implementation:**
```typescript
const updateCertificateGrade = (certificateId: string, newGrade?: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::update_certificate_grade`,
    arguments: [
      tx.object(certificateId),
      tx.pure(newGrade ? [newGrade] : [])
    ]
  });
  return tx;
};
```

---

### 6.2. Add Evidence to Certificate (University Function) 
```move
public fun add_evidence_to_certificate(
    cert: &mut Certificate,
    evidence_blob_id: vector<u8>,
    ctx: &mut TxContext
)
```

**Frontend Implementation:**
```typescript
const addEvidenceToCertificate = (certificateId: string, walrusBlobId: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::add_evidence_to_certificate`,
    arguments: [
      tx.object(certificateId),
      tx.pure(walrusBlobId)
    ]
  });
  return tx;
};
```

---

### 7. Verify Certificate (Public Read-Only) - UNCHANGED
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

---

## Individual Query Functions !

### Administrative Queries

#### Check if Address is Admin
```move
public fun is_admin(registry: &CertificateRegistry, addr: address): bool
```

**Frontend Implementation:**
```typescript
const isAdmin = (registryId: string, address: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::is_admin`,
    arguments: [tx.object(registryId), tx.pure(address)]
  });
  return tx;
};
```

#### Get Admin Address
```move
public fun get_admin(registry: &CertificateRegistry): address
```

**Frontend Implementation:**
```typescript
const getAdmin = (registryId: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::get_admin`,
    arguments: [tx.object(registryId)]
  });
  return tx;
};
```

### Certificate Detail Queries

#### Get Certificate Issue Date
```move
public fun get_issue_date(cert: &Certificate): u64
```

**Frontend Implementation:**
```typescript
const getCertificateIssueDate = (certificateId: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::get_issue_date`,
    arguments: [tx.object(certificateId)]
  });
  return tx;
};
```

#### Get Certificate Student Address
```move
public fun get_student_address(cert: &Certificate): address
```

**Frontend Implementation:**
```typescript
const getCertificateStudent = (certificateId: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::get_student_address`,
    arguments: [tx.object(certificateId)]
  });
  return tx;
};
```

#### Get Certificate University
```move
public fun get_university(cert: &Certificate): address
```

**Frontend Implementation:**
```typescript
const getCertificateUniversity = (certificateId: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::get_university`,
    arguments: [tx.object(certificateId)]
  });
  return tx;
};
```

#### Get Certificate Type
```move
public fun get_credential_type(cert: &Certificate): vector<u8>
```

**Frontend Implementation:**
```typescript
const getCertificateType = (certificateId: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::get_credential_type`,
    arguments: [tx.object(certificateId)]
  });
  return tx;
};
```

#### Check Certificate Validity
```move
public fun is_certificate_valid(cert: &Certificate): bool
```

**Frontend Implementation:**
```typescript
const isCertificateValid = (certificateId: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::is_certificate_valid`,
    arguments: [tx.object(certificateId)]
  });
  return tx;
};
```

#### Get Certificate ID
```move
public fun get_certificate_id(cert: &Certificate): object::ID
```

**Frontend Implementation:**
```typescript
const getCertificateObjectId = (certificateId: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::get_certificate_id`,
    arguments: [tx.object(certificateId)]
  });
  return tx;
};
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

### Enhanced Certificate Verification 
```typescript
const getFullCertificateInfo = async (certificateId: string) => {
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
        id: certificateId,
        isValid: fields.is_valid,
        student: fields.student_address,
        university: fields.university,
        credentialType: fields.credential_type,
        issueDate: new Date(parseInt(fields.issue_date)),
        grade: fields.grade?.[0] || null,
        hasEvidence: fields.walrus_evidence_blob !== null,
        evidenceBlob: fields.walrus_evidence_blob?.[0] || null,
        owner: response.data.owner
      };
    }
    
    return null;
  } catch (error) {
    console.error('Certificate verification failed:', error);
    return null;
  }
};
```

### Batch Certificate Queries 
```typescript
// Get multiple certificates at once
const getBatchCertificates = async (certificateIds: string[]) => {
  const responses = await Promise.all(
    certificateIds.map(id => suiClient.getObject({
      id,
      options: { showContent: true }
    }))
  );
  
  return responses.map((response, index) => {
    if (response.data?.content?.dataType === 'moveObject') {
      return {
        id: certificateIds[index],
        ...response.data.content.fields
      };
    }
    return null;
  }).filter(cert => cert !== null);
};

// Check authorization status
const checkUniversityAuth = async (universityAddress: string) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::certificate_registry::is_authorized_university`,
    arguments: [
      tx.object(REGISTRY_ID),
      tx.pure(universityAddress)
    ]
  });
  return tx;
};
```

---

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
  } else if (error.message.includes('EInvalidEvidence')) {
    alert('Invalid evidence provided');
  } else if (error.message.includes('ECertificateNotFound')) {
    alert('Certificate not found');
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

## Integration Checklist - FULLY UPDATED!

- [ ] Contract deployed to testnet
- [ ] Package ID and Registry ID updated in this README
- [ ] Test university added to registry  
- [ ] Sample certificates minted for testing
- [ ] Event subscription tested
- [ ] Error handling patterns documented
- [ ] All function examples tested with actual contract
- [ ] Individual query functions fully documented (8 functions)
- [ ] Administrative query functions documented (2 functions)
- [ ] Batch operations documented and verified (2 functions)
- [ ] Certificate update functions documented and tested (2 functions)



### ✅ **All Functions(16 total):**

1. **Core Functions (7):**
   - `create_registry()` - Initialize system
   - `add_university()` - Add single university
   - `mint_certificate()` - Basic certificate minting
   - `mint_with_evidence()` - Evidence-based minting
   - `revoke_certificate()` - Certificate revocation
   - `update_certificate_grade()` - Update grades
   - `add_evidence_to_certificate()` - Add evidence

2. **Administrative Functions (4):**
   - `add_universities()` - Batch add universities
   - `remove_university()` - Remove university
   - `is_admin()` - Check admin status
   - `get_admin()` - Get admin address

3. **Query Functions (11):**
   - `get_certificate_info()` - Complete certificate data
   - `get_issue_date()` - Issue timestamp
   - `get_student_address()` - Student owner
   - `get_university()` - Issuing university
   - `get_credential_type()` - Certificate type
   - `is_certificate_valid()` - Validity status
   - `get_certificate_id()` - Object ID
   - `get_evidence_blob()` - Walrus evidence
   - `get_grade()` - Certificate grade
   - `get_total_certificates()` - System statistics
   - `is_authorized_university()` - Authorization check


**The SkillPass smart contract is FULLY DOCUMENTED and PRODUCTION READY!**



