
module skillpass::certificate_registry {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::clock;
    use std::option::{Self, Option};
    use std::vector;

    // Error codes
    const ENotAuthorized: u64 = 1;
    const ENotAuthorizedUniversity: u64 = 2;
    const EInvalidCertificate: u64 = 3;
    const EInvalidEvidence: u64 = 4;
    const ECertificateNotFound: u64 = 5;

    // Main certificate object with SEAL encryption support
    public struct Certificate has key, store {
        id: UID,
        student_address: address,
        university: address,
        // Encrypted fields using SEAL
        encrypted_credential_type: vector<u8>,  // SEAL encrypted credential type
        encrypted_grade: Option<vector<u8>>,     // SEAL encrypted grade
        // Metadata for SEAL decryption
        encryption_params: vector<u8>,           // SEAL encryption parameters
        public_key_hash: vector<u8>,            // Hash of public key used
        // Plain fields (non-sensitive)
        issue_date: u64,
        walrus_evidence_blob: Option<vector<u8>>,
        is_valid: bool,
        // Additional privacy fields
        access_policy: vector<u8>,              // Who can decrypt this certificate
    }

    // Registry to manage universities and certificates
    public struct CertificateRegistry has key {
        id: UID,
        admin: address,
        total_certificates: u64,
        authorized_universities: Table<address, bool>,
    }

    // SEAL encryption events
    public struct CertificateIssued has copy, drop {
        certificate_id: object::ID,
        student: address,
        university: address,
        encryption_params_hash: vector<u8>,  // Hash of encryption params for verification
    }

    public struct CertificateDecrypted has copy, drop {
        certificate_id: object::ID,
        accessor: address,
        access_granted: bool,
    }

    public struct CertificateRevoked has copy, drop {
        certificate_id: object::ID,
        university: address,
        reason: vector<u8>,
    }

    // Initialize registry (called once)
    public fun create_registry(ctx: &mut TxContext) {
        let registry = CertificateRegistry {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            total_certificates: 0,
            authorized_universities: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // Add university as authorized issuer (admin only)
    public fun add_university(
        registry: &mut CertificateRegistry,
        university_address: address,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == registry.admin, ENotAuthorized);
        table::add(&mut registry.authorized_universities, university_address, true);
    }

    // Check if university is authorized
    public fun is_authorized_university(
        registry: &CertificateRegistry,
        university: address
    ): bool {
        table::contains(&registry.authorized_universities, university)
    }

    // Get total certificates count
    public fun get_total_certificates(registry: &CertificateRegistry): u64 {
        registry.total_certificates
    }

    // Mint certificate with SEAL encryption (university only)
    public fun mint_encrypted_certificate(
        registry: &mut CertificateRegistry,
        student_address: address,
        encrypted_credential_type: vector<u8>,   // Pre-encrypted with SEAL
        encrypted_grade: Option<vector<u8>>,     // Pre-encrypted with SEAL
        encryption_params: vector<u8>,           // SEAL encryption parameters
        public_key_hash: vector<u8>,            // Hash of public key
        access_policy: vector<u8>,              // Access control policy
        clock: &clock::Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(is_authorized_university(registry, sender), ENotAuthorizedUniversity);
        assert!(!vector::is_empty(&encrypted_credential_type), EInvalidCertificate);
        assert!(student_address != @0x0, EInvalidCertificate);
        assert!(!vector::is_empty(&encryption_params), EInvalidCertificate);
        assert!(!vector::is_empty(&public_key_hash), EInvalidCertificate);

        let certificate_id = object::new(ctx);
        let certificate = Certificate {
            id: certificate_id,
            student_address,
            university: sender,
            encrypted_credential_type,
            encrypted_grade,
            encryption_params,
            public_key_hash,
            issue_date: clock::timestamp_ms(clock),
            walrus_evidence_blob: option::none(),
            is_valid: true,
            access_policy,
        };

        registry.total_certificates = registry.total_certificates + 1;

        // Emit event with encryption metadata
        sui::event::emit(CertificateIssued {
            certificate_id: object::uid_to_inner(&certificate.id),
            student: student_address,
            university: sender,
            encryption_params_hash: public_key_hash,
        });

        transfer::transfer(certificate, student_address);
    }

    // Legacy mint certificate function for backward compatibility
    public fun mint_certificate(
        registry: &mut CertificateRegistry,
        student_address: address,
        credential_type: vector<u8>,
        grade: Option<vector<u8>>,
        clock: &clock::Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(is_authorized_university(registry, sender), ENotAuthorizedUniversity);
        assert!(!vector::is_empty(&credential_type), EInvalidCertificate);
        assert!(student_address != @0x0, EInvalidCertificate);

        // Convert to encrypted format for compatibility
        let encrypted_credential_type = credential_type;
        let encrypted_grade = grade;
        let encryption_params = b"legacy_mode_no_encryption";
        let public_key_hash = b"legacy_public_key_hash_placeholder";
        let access_policy = b"[\"legacy_access\"]";

        let certificate_id = object::new(ctx);
        let certificate = Certificate {
            id: certificate_id,
            student_address,
            university: sender,
            encrypted_credential_type,
            encrypted_grade,
            encryption_params,
            public_key_hash,
            issue_date: clock::timestamp_ms(clock),
            walrus_evidence_blob: option::none(),
            is_valid: true,
            access_policy,
        };

        registry.total_certificates = registry.total_certificates + 1;

        // Emit event
        sui::event::emit(CertificateIssued {
            certificate_id: object::uid_to_inner(&certificate.id),
            student: student_address,
            university: sender,
            encryption_params_hash: public_key_hash,
        });

        transfer::transfer(certificate, student_address);
    }

    // Mint certificate with evidence (for on-demand minting)
    public fun mint_with_evidence(
        registry: &mut CertificateRegistry,
        student_address: address,
        credential_type: vector<u8>,
        evidence_blob_id: vector<u8>,
        grade: Option<vector<u8>>,
        clock: &clock::Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(is_authorized_university(registry, sender), ENotAuthorizedUniversity);
        assert!(!vector::is_empty(&credential_type), EInvalidCertificate);
        assert!(student_address != @0x0, EInvalidCertificate);
        assert!(!vector::is_empty(&evidence_blob_id), EInvalidEvidence);

        // Convert to encrypted format for compatibility
        let encrypted_credential_type = credential_type;
        let encrypted_grade = grade;
        let encryption_params = b"legacy_mode_no_encryption";
        let public_key_hash = b"legacy_public_key_hash_placeholder";
        let access_policy = b"[\"legacy_access\"]";

        let certificate_id = object::new(ctx);
        let certificate = Certificate {
            id: certificate_id,
            student_address,
            university: sender,
            encrypted_credential_type,
            encrypted_grade,
            encryption_params,
            public_key_hash,
            issue_date: clock::timestamp_ms(clock),
            walrus_evidence_blob: option::some(evidence_blob_id),
            is_valid: true,
            access_policy,
        };

        registry.total_certificates = registry.total_certificates + 1;

        // Emit event
        sui::event::emit(CertificateIssued {
            certificate_id: object::uid_to_inner(&certificate.id),
            student: student_address,
            university: sender,
            encryption_params_hash: public_key_hash,
        });

        transfer::transfer(certificate, student_address);
    }

    // Revoke certificate (issuing university only)
    public fun revoke_certificate(
        cert: &mut Certificate,
        reason: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == cert.university, ENotAuthorizedUniversity);
        
        cert.is_valid = false;

        // Emit event
        sui::event::emit(CertificateRevoked {
            certificate_id: object::uid_to_inner(&cert.id),
            university: sender,
            reason,
        });
    }

    // SEAL-specific query functions
    
    // Get encrypted certificate data (requires proper SEAL private key to decrypt)
    public fun get_encrypted_certificate_data(cert: &Certificate): (
        vector<u8>,           // encrypted_credential_type
        Option<vector<u8>>,   // encrypted_grade
        vector<u8>,           // encryption_params
        vector<u8>,           // public_key_hash
        vector<u8>            // access_policy
    ) {
        (
            cert.encrypted_credential_type,
            cert.encrypted_grade,
            cert.encryption_params,
            cert.public_key_hash,
            cert.access_policy
        )
    }

    // Verify access rights for decryption (on-chain access control)
    public fun verify_decryption_access(
        cert: &Certificate,
        accessor: address,
        _access_proof: vector<u8>,  // Cryptographic proof of access rights (unused for now)
        ctx: &mut TxContext
    ): bool {
        let sender = tx_context::sender(ctx);
        
        // Allow student, university, and admin to access
        let has_basic_access = sender == cert.student_address || 
                              sender == cert.university ||
                              accessor == cert.student_address;
        
        // Emit access attempt event
        sui::event::emit(CertificateDecrypted {
            certificate_id: object::uid_to_inner(&cert.id),
            accessor,
            access_granted: has_basic_access,
        });
        
        has_basic_access
    }

    // Get certificate metadata (non-encrypted fields)
    public fun get_certificate_metadata(cert: &Certificate): (
        address,    // student
        address,    // university
        u64,        // issue_date
        bool,       // is_valid
        vector<u8>  // public_key_hash
    ) {
        (
            cert.student_address,
            cert.university,
            cert.issue_date,
            cert.is_valid,
            cert.public_key_hash
        )
    }
    
    // Update access policy (university only)
    public fun update_access_policy(
        cert: &mut Certificate,
        new_access_policy: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == cert.university, ENotAuthorizedUniversity);
        assert!(cert.is_valid, EInvalidCertificate);
        
        cert.access_policy = new_access_policy;
    }

    // Get evidence blob (for Walrus integration)
    public fun get_evidence_blob(cert: &Certificate): Option<vector<u8>> {
        cert.walrus_evidence_blob
    }

    // Get grade information (legacy compatibility)
    public fun get_grade(cert: &Certificate): Option<vector<u8>> {
        cert.encrypted_grade
    }

    // Query functions for better frontend integration
    
    // Check if an address is admin
    public fun is_admin(registry: &CertificateRegistry, addr: address): bool {
        registry.admin == addr
    }

    // Get admin address
    public fun get_admin(registry: &CertificateRegistry): address {
        registry.admin
    }

    // Get certificate issue date
    public fun get_issue_date(cert: &Certificate): u64 {
        cert.issue_date
    }

    // Get certificate student address
    public fun get_student_address(cert: &Certificate): address {
        cert.student_address
    }

    // Get certificate university
    public fun get_university(cert: &Certificate): address {
        cert.university
    }

    // Get certificate type (legacy compatibility)
    public fun get_credential_type(cert: &Certificate): vector<u8> {
        cert.encrypted_credential_type
    }

    // Legacy get_certificate_info function for backward compatibility
    public fun get_certificate_info(cert: &Certificate): (
        address,      // student
        address,      // university
        vector<u8>,   // credential_type (encrypted)
        u64,          // issue_date
        bool          // is_valid
    ) {
        (
            cert.student_address,
            cert.university,
            cert.encrypted_credential_type,
            cert.issue_date,
            cert.is_valid
        )
    }

    // Check if certificate is valid
    public fun is_certificate_valid(cert: &Certificate): bool {
        cert.is_valid
    }

    // Get certificate ID
    public fun get_certificate_id(cert: &Certificate): object::ID {
        object::uid_to_inner(&cert.id)
    }

    // Batch operations for efficiency
    
    // Add multiple universities at once (admin only)
    public fun add_universities(
        registry: &mut CertificateRegistry,
        university_addresses: vector<address>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == registry.admin, ENotAuthorized);
        let mut i = 0;
        let len = vector::length(&university_addresses);
        while (i < len) {
            let addr = *vector::borrow(&university_addresses, i);
            if (!table::contains(&registry.authorized_universities, addr)) {
                table::add(&mut registry.authorized_universities, addr, true);
            };
            i = i + 1;
        };
    }

    // Remove university authorization (admin only)
    public fun remove_university(
        registry: &mut CertificateRegistry,
        university_address: address,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == registry.admin, ENotAuthorized);
        if (table::contains(&registry.authorized_universities, university_address)) {
            table::remove(&mut registry.authorized_universities, university_address);
        };
    }

    // Update certificate grade (issuing university only)
    public fun update_certificate_grade(
        cert: &mut Certificate,
        new_grade: Option<vector<u8>>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == cert.university, ENotAuthorizedUniversity);
        assert!(cert.is_valid, EInvalidCertificate);
        
        cert.encrypted_grade = new_grade;
    }

    // Add evidence to existing certificate (issuing university only)
    public fun add_evidence_to_certificate(
        cert: &mut Certificate,
        evidence_blob_id: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == cert.university, ENotAuthorizedUniversity);
        assert!(cert.is_valid, EInvalidCertificate);
        assert!(!vector::is_empty(&evidence_blob_id), EInvalidEvidence);
        
        cert.walrus_evidence_blob = option::some(evidence_blob_id);
    }
}