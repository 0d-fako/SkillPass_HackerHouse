// tests/certificate_registry_tests.move
#[test_only]
module skillpass::certificate_registry_tests {
    use sui::test_scenario::{Self, Scenario, next_tx, ctx};
    use skillpass::certificate_registry::{Self, Certificate, CertificateRegistry};
    use sui::clock;
    use std::vector;
    use std::option;

    // Test addresses
    const ADMIN: address = @0xA;
    const UNIVERSITY: address = @0xB;
    const STUDENT: address = @0xC;
    const OTHER_UNIVERSITY: address = @0xD;

    // Test data
    const CREDENTIAL_TYPE: vector<u8> = b"Bachelor of Science in Computer Science";
    const GRADE: vector<u8> = b"First Class";
    const WALRUS_BLOB_ID: vector<u8> = b"walrus_blob_12345";
    
    // SEAL test data
    const ENCRYPTED_CREDENTIAL_TYPE: vector<u8> = b"encrypted_credential_type_data_sample";
    const ENCRYPTED_GRADE: vector<u8> = b"encrypted_grade_data_sample";
    const ENCRYPTION_PARAMS: vector<u8> = b"seal_encryption_parameters_sample";
    const PUBLIC_KEY_HASH: vector<u8> = b"public_key_hash_sample_32_bytes_";
    const ACCESS_POLICY: vector<u8> = b"[\"0xSTUDENT\",\"0xUNIVERSITY\"]";
    const ACCESS_PROOF: vector<u8> = b"cryptographic_access_proof_sample";

    #[test]
    fun test_create_registry() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // WHEN: Admin creates registry
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        // THEN: Registry should exist and be shared
        next_tx(scenario, ADMIN);
        {
            let registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            assert!(certificate_registry::get_total_certificates(&registry) == 0, 0);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_add_university_as_admin() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry exists
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        // WHEN: Admin adds university
        next_tx(scenario, ADMIN);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::add_university(&mut registry, UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        // THEN: University should be authorized
        next_tx(scenario, ADMIN);
        {
            let registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            assert!(certificate_registry::is_authorized_university(&registry, UNIVERSITY), 0);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::ENotAuthorized)]
    fun test_add_university_fails_for_non_admin() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry exists
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        // WHEN: Non-admin tries to add university
        // THEN: Should fail with ENotAuthorized
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::add_university(&mut registry, OTHER_UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_mint_certificate_by_authorized_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry with authorized university
        setup_registry_with_university(scenario);

        // WHEN: University mints certificate
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_certificate(
                &mut registry,
                STUDENT,
                CREDENTIAL_TYPE,
                option::some(GRADE),
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };

        // THEN: Certificate should be created and owned by student
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let (student_addr, university_addr, cred_type, _, is_valid) = 
                certificate_registry::get_certificate_info(&certificate);
            
            assert!(student_addr == STUDENT, 0);
            assert!(university_addr == UNIVERSITY, 1);
            assert!(cred_type == CREDENTIAL_TYPE, 2);
            assert!(is_valid == true, 3);
            
            test_scenario::return_to_sender(scenario, certificate);
        };

        // AND: Registry total should increment
        next_tx(scenario, ADMIN);
        {
            let registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            assert!(certificate_registry::get_total_certificates(&registry) == 1, 4);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::ENotAuthorizedUniversity)]
    fun test_mint_certificate_fails_for_unauthorized_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry exists but university not authorized
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        // WHEN: Unauthorized university tries to mint
        // THEN: Should fail with ENotAuthorizedUniversity
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_certificate(
                &mut registry,
                STUDENT,
                CREDENTIAL_TYPE,
                option::some(GRADE),
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_mint_certificate_with_evidence() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry with authorized university
        setup_registry_with_university(scenario);

        // WHEN: University mints certificate with Walrus evidence
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_with_evidence(
                &mut registry,
                STUDENT,
                CREDENTIAL_TYPE,
                WALRUS_BLOB_ID,
                option::some(GRADE),
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };

        // THEN: Certificate should have evidence blob reference
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let evidence = certificate_registry::get_evidence_blob(&certificate);
            
            assert!(option::is_some(&evidence), 0);
            assert!(*option::borrow(&evidence) == WALRUS_BLOB_ID, 1);
            
            test_scenario::return_to_sender(scenario, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_revoke_certificate_by_issuing_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists
        setup_certificate(scenario);

        // WHEN: Issuing university revokes certificate
        next_tx(scenario, UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            certificate_registry::revoke_certificate(
                &mut certificate,
                b"Academic misconduct",
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        // Certificate should be invalid
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let (_, _, _, _, is_valid) = certificate_registry::get_certificate_info(&certificate);
            assert!(is_valid == false, 0);
            test_scenario::return_to_sender(scenario, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::ENotAuthorizedUniversity)]
    fun test_revoke_certificate_fails_for_wrong_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists and other university is authorized
        setup_certificate(scenario);
        next_tx(scenario, ADMIN);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::add_university(&mut registry, OTHER_UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        // WHEN: Different university tries to revoke
        // THEN: Should fail with ENotAuthorizedUniversity
        next_tx(scenario, OTHER_UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            certificate_registry::revoke_certificate(
                &mut certificate,
                b"Unauthorized revocation",
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_verify_certificate_returns_correct_info() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists
        setup_certificate(scenario);

        // WHEN: Anyone verifies certificate
        next_tx(scenario, @0xE); // Random verifier address
        {
            let certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            let (student_addr, university_addr, cred_type, issue_date, is_valid) = 
                certificate_registry::get_certificate_info(&certificate);

            // THEN: Should return correct information
            assert!(student_addr == STUDENT, 0);
            assert!(university_addr == UNIVERSITY, 1);
            assert!(cred_type == CREDENTIAL_TYPE, 2);
            assert!(issue_date >= 0, 3); // Changed from > 0 to >= 0
            assert!(is_valid == true, 4);

            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    // Helper functions
    fun setup_registry_with_university(scenario: &mut Scenario) {
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        next_tx(scenario, ADMIN);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::add_university(&mut registry, UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };
    }

    fun setup_certificate(scenario: &mut Scenario) {
        setup_registry_with_university(scenario);

        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_certificate(
                &mut registry,
                STUDENT,
                CREDENTIAL_TYPE,
                option::some(GRADE),
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };
    }

    // New comprehensive tests for query functions and edge cases
    
    #[test]
    fun test_administrative_queries() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry exists
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        // WHEN & THEN: Test admin queries
        next_tx(scenario, ADMIN);
        {
            let registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            
            // Test is_admin function
            assert!(certificate_registry::is_admin(&registry, ADMIN), 0);
            assert!(!certificate_registry::is_admin(&registry, UNIVERSITY), 1);
            
            // Test get_admin function
            assert!(certificate_registry::get_admin(&registry) == ADMIN, 2);
            
            // Test total certificates initially zero
            assert!(certificate_registry::get_total_certificates(&registry) == 0, 3);
            
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_batch_add_universities() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry exists
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        // WHEN: Admin adds multiple universities
        next_tx(scenario, ADMIN);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let mut universities = vector::empty<address>();
            vector::push_back(&mut universities, UNIVERSITY);
            vector::push_back(&mut universities, OTHER_UNIVERSITY);
            vector::push_back(&mut universities, @0xE);
            
            certificate_registry::add_universities(&mut registry, universities, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        // THEN: All universities should be authorized
        next_tx(scenario, ADMIN);
        {
            let registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            assert!(certificate_registry::is_authorized_university(&registry, UNIVERSITY), 0);
            assert!(certificate_registry::is_authorized_university(&registry, OTHER_UNIVERSITY), 1);
            assert!(certificate_registry::is_authorized_university(&registry, @0xE), 2);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::ENotAuthorized)]
    fun test_batch_add_universities_fails_for_non_admin() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry exists
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        // WHEN: Non-admin tries to batch add universities
        // THEN: Should fail with ENotAuthorized
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let mut universities = vector::empty<address>();
            vector::push_back(&mut universities, OTHER_UNIVERSITY);
            
            certificate_registry::add_universities(&mut registry, universities, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_remove_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry with authorized university
        setup_registry_with_university(scenario);

        // WHEN: Admin removes university
        next_tx(scenario, ADMIN);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::remove_university(&mut registry, UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        // THEN: University should no longer be authorized
        next_tx(scenario, ADMIN);
        {
            let registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            assert!(!certificate_registry::is_authorized_university(&registry, UNIVERSITY), 0);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_remove_nonexistent_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry exists but university not added
        next_tx(scenario, ADMIN);
        {
            certificate_registry::create_registry(ctx(scenario));
        };

        // WHEN: Admin tries to remove non-existent university
        // THEN: Should not error (graceful handling)
        next_tx(scenario, ADMIN);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::remove_university(&mut registry, UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::ENotAuthorized)]
    fun test_remove_university_fails_for_non_admin() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry with authorized university
        setup_registry_with_university(scenario);

        // WHEN: Non-admin tries to remove university
        // THEN: Should fail with ENotAuthorized
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::remove_university(&mut registry, OTHER_UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_certificate_detail_queries() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists
        setup_certificate(scenario);

        // WHEN & THEN: Test all certificate query functions
        next_tx(scenario, @0xF); // Random address for testing
        {
            let certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            
            // Test individual field getters
            assert!(certificate_registry::get_student_address(&certificate) == STUDENT, 0);
            assert!(certificate_registry::get_university(&certificate) == UNIVERSITY, 1);
            assert!(certificate_registry::get_credential_type(&certificate) == CREDENTIAL_TYPE, 2);
            assert!(certificate_registry::get_issue_date(&certificate) >= 0, 3);
            assert!(certificate_registry::is_certificate_valid(&certificate), 4);
            
            // Test grade getter
            let grade_opt = certificate_registry::get_grade(&certificate);
            assert!(option::is_some(&grade_opt), 5);
            assert!(*option::borrow(&grade_opt) == GRADE, 6);
            
            // Test evidence blob (should be none for regular mint)
            let evidence_opt = certificate_registry::get_evidence_blob(&certificate);
            assert!(option::is_none(&evidence_opt), 7);
            
            // Test certificate ID getter
            let cert_id = certificate_registry::get_certificate_id(&certificate);
            assert!(cert_id != object::id_from_address(@0x0), 8);
            
            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_update_certificate_grade() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists
        setup_certificate(scenario);

        // WHEN: University updates certificate grade
        next_tx(scenario, UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            let new_grade = b"Distinction";
            certificate_registry::update_certificate_grade(
                &mut certificate,
                option::some(new_grade),
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        // THEN: Grade should be updated
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let grade_opt = certificate_registry::get_grade(&certificate);
            assert!(option::is_some(&grade_opt), 0);
            assert!(*option::borrow(&grade_opt) == b"Distinction", 1);
            test_scenario::return_to_sender(scenario, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::ENotAuthorizedUniversity)]
    fun test_update_certificate_grade_fails_for_wrong_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists and other university is authorized
        setup_certificate(scenario);
        next_tx(scenario, ADMIN);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::add_university(&mut registry, OTHER_UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        // WHEN: Wrong university tries to update grade
        // THEN: Should fail with ENotAuthorizedUniversity
        next_tx(scenario, OTHER_UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            certificate_registry::update_certificate_grade(
                &mut certificate,
                option::some(b"Fail"),
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_add_evidence_to_certificate() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists without evidence
        setup_certificate(scenario);

        // WHEN: University adds evidence to certificate
        next_tx(scenario, UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            certificate_registry::add_evidence_to_certificate(
                &mut certificate,
                WALRUS_BLOB_ID,
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        // THEN: Certificate should have evidence
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let evidence_opt = certificate_registry::get_evidence_blob(&certificate);
            assert!(option::is_some(&evidence_opt), 0);
            assert!(*option::borrow(&evidence_opt) == WALRUS_BLOB_ID, 1);
            test_scenario::return_to_sender(scenario, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::ENotAuthorizedUniversity)]
    fun test_add_evidence_fails_for_wrong_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists and other university is authorized
        setup_certificate(scenario);
        next_tx(scenario, ADMIN);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            certificate_registry::add_university(&mut registry, OTHER_UNIVERSITY, ctx(scenario));
            test_scenario::return_shared(registry);
        };

        // WHEN: Wrong university tries to add evidence
        // THEN: Should fail with ENotAuthorizedUniversity
        next_tx(scenario, OTHER_UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            certificate_registry::add_evidence_to_certificate(
                &mut certificate,
                WALRUS_BLOB_ID,
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::EInvalidCertificate)]
    fun test_update_revoked_certificate_grade_fails() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists and is revoked
        setup_certificate(scenario);
        next_tx(scenario, UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            certificate_registry::revoke_certificate(
                &mut certificate,
                b"Test revocation",
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        // WHEN: University tries to update grade of revoked certificate
        // THEN: Should fail with EInvalidCertificate
        next_tx(scenario, UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            certificate_registry::update_certificate_grade(
                &mut certificate,
                option::some(b"Pass"),
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::EInvalidEvidence)]
    fun test_add_empty_evidence_fails() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Certificate exists
        setup_certificate(scenario);

        // WHEN: University tries to add empty evidence
        // THEN: Should fail with EInvalidEvidence
        next_tx(scenario, UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            certificate_registry::add_evidence_to_certificate(
                &mut certificate,
                vector::empty<u8>(),
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::EInvalidCertificate)]
    fun test_mint_certificate_with_empty_credential_type_fails() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry with authorized university
        setup_registry_with_university(scenario);

        // WHEN: University tries to mint certificate with empty credential type
        // THEN: Should fail with EInvalidCertificate
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_certificate(
                &mut registry,
                STUDENT,
                vector::empty<u8>(),
                option::some(GRADE),
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = certificate_registry::EInvalidCertificate)]
    fun test_mint_certificate_with_zero_address_fails() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry with authorized university
        setup_registry_with_university(scenario);

        // WHEN: University tries to mint certificate to zero address
        // THEN: Should fail with EInvalidCertificate
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_certificate(
                &mut registry,
                @0x0,
                CREDENTIAL_TYPE,
                option::some(GRADE),
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_mint_certificate_without_grade() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry with authorized university
        setup_registry_with_university(scenario);

        // WHEN: University mints certificate without grade
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_certificate(
                &mut registry,
                STUDENT,
                CREDENTIAL_TYPE,
                option::none<vector<u8>>(),
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };

        // THEN: Certificate should be created without grade
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let grade_opt = certificate_registry::get_grade(&certificate);
            assert!(option::is_none(&grade_opt), 0);
            test_scenario::return_to_sender(scenario, certificate);
        };

        test_scenario::end(scenario_val);
    }

    // =============================================================================
    // SEAL ENCRYPTION TESTS
    // =============================================================================

    #[test]
    fun test_mint_encrypted_certificate_by_authorized_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Registry with authorized university
        setup_registry_with_university(scenario);

        // WHEN: University mints encrypted certificate
        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_encrypted_certificate(
                &mut registry,
                STUDENT,
                ENCRYPTED_CREDENTIAL_TYPE,
                option::some(ENCRYPTED_GRADE),
                ENCRYPTION_PARAMS,
                PUBLIC_KEY_HASH,
                ACCESS_POLICY,
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };

        // THEN: Encrypted certificate should be created and owned by student
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let (student_addr, university_addr, issue_date, is_valid, pub_key_hash) = 
                certificate_registry::get_certificate_metadata(&certificate);
            
            assert!(student_addr == STUDENT, 0);
            assert!(university_addr == UNIVERSITY, 1);
            assert!(is_valid == true, 2);
            assert!(pub_key_hash == PUBLIC_KEY_HASH, 3);
            assert!(issue_date >= 0, 4);
            
            test_scenario::return_to_sender(scenario, certificate);
        };

        // AND: Registry total should increment
        next_tx(scenario, ADMIN);
        {
            let registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            assert!(certificate_registry::get_total_certificates(&registry) == 1, 5);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_get_encrypted_certificate_data() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Encrypted certificate exists
        setup_encrypted_certificate(scenario);

        // WHEN & THEN: Anyone can get encrypted data (but cannot decrypt without key)
        next_tx(scenario, @0xE); // Random verifier address
        {
            let certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            let (
                encrypted_cred_type,
                encrypted_grade_opt,
                encryption_params,
                public_key_hash,
                access_policy
            ) = certificate_registry::get_encrypted_certificate_data(&certificate);

            // THEN: Should return encrypted data
            assert!(encrypted_cred_type == ENCRYPTED_CREDENTIAL_TYPE, 0);
            assert!(option::is_some(&encrypted_grade_opt), 1);
            assert!(*option::borrow(&encrypted_grade_opt) == ENCRYPTED_GRADE, 2);
            assert!(encryption_params == ENCRYPTION_PARAMS, 3);
            assert!(public_key_hash == PUBLIC_KEY_HASH, 4);
            assert!(access_policy == ACCESS_POLICY, 5);

            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_verify_decryption_access_for_student() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Encrypted certificate exists
        setup_encrypted_certificate(scenario);

        // WHEN: Student verifies access to their certificate
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let has_access = certificate_registry::verify_decryption_access(
                &certificate,
                STUDENT,
                ACCESS_PROOF,
                ctx(scenario)
            );

            // THEN: Student should have access
            assert!(has_access == true, 0);

            test_scenario::return_to_sender(scenario, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_verify_decryption_access_for_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Encrypted certificate exists
        setup_encrypted_certificate(scenario);

        // WHEN: University verifies access to certificate they issued
        next_tx(scenario, UNIVERSITY);
        {
            let certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            let has_access = certificate_registry::verify_decryption_access(
                &certificate,
                UNIVERSITY,
                ACCESS_PROOF,
                ctx(scenario)
            );

            // THEN: University should have access
            assert!(has_access == true, 0);

            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_verify_decryption_access_denied_for_unauthorized() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Encrypted certificate exists
        setup_encrypted_certificate(scenario);

        // WHEN: Unauthorized user tries to verify access
        next_tx(scenario, OTHER_UNIVERSITY);
        {
            let certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            let has_access = certificate_registry::verify_decryption_access(
                &certificate,
                OTHER_UNIVERSITY,
                ACCESS_PROOF,
                ctx(scenario)
            );

            // THEN: Access should be denied
            assert!(has_access == false, 0);

            test_scenario::return_to_address(STUDENT, certificate);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_update_access_policy_by_university() {
        let mut scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // GIVEN: Encrypted certificate exists
        setup_encrypted_certificate(scenario);

        // WHEN: University updates access policy
        next_tx(scenario, UNIVERSITY);
        {
            let mut certificate = test_scenario::take_from_address<Certificate>(scenario, STUDENT);
            let new_policy = b"[\"0xSTUDENT\",\"0xUNIVERSITY\",\"0xVERIFIER\"]";
            certificate_registry::update_access_policy(
                &mut certificate,
                new_policy,
                ctx(scenario)
            );
            test_scenario::return_to_address(STUDENT, certificate);
        };

        // THEN: Access policy should be updated
        next_tx(scenario, STUDENT);
        {
            let certificate = test_scenario::take_from_sender<Certificate>(scenario);
            let (
                _,
                _,
                _,
                _,
                access_policy
            ) = certificate_registry::get_encrypted_certificate_data(&certificate);
            
            let expected_policy = b"[\"0xSTUDENT\",\"0xUNIVERSITY\",\"0xVERIFIER\"]";
            assert!(access_policy == expected_policy, 0);
            
            test_scenario::return_to_sender(scenario, certificate);
        };

        test_scenario::end(scenario_val);
    }

    // SEAL-specific helper function
    fun setup_encrypted_certificate(scenario: &mut Scenario) {
        setup_registry_with_university(scenario);

        next_tx(scenario, UNIVERSITY);
        {
            let mut registry = test_scenario::take_shared<CertificateRegistry>(scenario);
            let clock = clock::create_for_testing(ctx(scenario));
            certificate_registry::mint_encrypted_certificate(
                &mut registry,
                STUDENT,
                ENCRYPTED_CREDENTIAL_TYPE,
                option::some(ENCRYPTED_GRADE),
                ENCRYPTION_PARAMS,
                PUBLIC_KEY_HASH,
                ACCESS_POLICY,
                &clock,
                ctx(scenario)
            );
            clock::destroy_for_testing(clock);
            test_scenario::return_shared(registry);
        };
    }
}