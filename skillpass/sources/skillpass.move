// sources/certificate_registry.move
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

    // Main certificate object
    public struct Certificate has key, store {
        id: UID,
        student_address: address,
        university: address,
        credential_type: vector<u8>,
        issue_date: u64,
        walrus_evidence_blob: Option<vector<u8>>,
        is_valid: bool,
        grade: Option<vector<u8>>,
    }

    // Registry to manage universities and certificates
    public struct CertificateRegistry has key {
        id: UID,
        admin: address,
        total_certificates: u64,
        authorized_universities: Table<address, bool>,
    }

    // Events
    public struct CertificateIssued has copy, drop {
        certificate_id: object::ID,
        student: address,
        university: address,
        credential_type: vector<u8>,
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

    // Mint certificate (university only)
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

        let certificate_id = object::new(ctx);
        let certificate = Certificate {
            id: certificate_id,
            student_address,
            university: sender,
            credential_type: credential_type,
            issue_date: clock::timestamp_ms(clock),
            walrus_evidence_blob: option::none(),
            is_valid: true,
            grade,
        };

        registry.total_certificates = registry.total_certificates + 1;

        // Emit event
        sui::event::emit(CertificateIssued {
            certificate_id: object::uid_to_inner(&certificate.id),
            student: student_address,
            university: sender,
            credential_type: credential_type,
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

        let certificate_id = object::new(ctx);
        let certificate = Certificate {
            id: certificate_id,
            student_address,
            university: sender,
            credential_type: credential_type,
            issue_date: clock::timestamp_ms(clock),
            walrus_evidence_blob: option::some(evidence_blob_id),
            is_valid: true,
            grade,
        };

        registry.total_certificates = registry.total_certificates + 1;

        // Emit event
        sui::event::emit(CertificateIssued {
            certificate_id: object::uid_to_inner(&certificate.id),
            student: student_address,
            university: sender,
            credential_type: credential_type,
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

    // Public verification function
    public fun get_certificate_info(cert: &Certificate): (
        address,      // student
        address,      // university
        vector<u8>,   // credential_type
        u64,          // issue_date
        bool          // is_valid
    ) {
        (
            cert.student_address,
            cert.university,
            cert.credential_type,
            cert.issue_date,
            cert.is_valid
        )
    }

    // Get evidence blob (for Walrus integration)
    public fun get_evidence_blob(cert: &Certificate): Option<vector<u8>> {
        cert.walrus_evidence_blob
    }

    // Get grade information
    public fun get_grade(cert: &Certificate): Option<vector<u8>> {
        cert.grade
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

    // Get certificate type
    public fun get_credential_type(cert: &Certificate): vector<u8> {
        cert.credential_type
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
        
        cert.grade = new_grade;
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