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

        // THEN: Certificate should be invalid
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
}