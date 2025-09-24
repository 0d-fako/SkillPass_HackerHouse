#[test_only]
module skillpass::skillpass_tests {
    use skillpass::skillpass::{Self, IssuerRegistry};
    use skillpass::education_passport;
    use sui::test_scenario;

    #[test]
    fun test_create_registry() {
        let scenario_val = test_scenario::begin(@0x1);
        let scenario = &mut scenario_val;
        let admin = @0x1;
        let registry = skillpass::create_registry(admin, test_scenario::ctx(scenario));
        // Check creation (admin set, empty issuers)
        assert!(skillpass::is_authorized_issuer(&registry, admin) == false, 0);  // Admin not auto-added
        test_scenario::return_shared(registry);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_add_issuer_unauthorized() {
        let scenario_val = test_scenario::begin(@0x1);
        let scenario = &mut scenario_val;
        let admin = @0x1;
        let registry = skillpass::create_registry(admin, test_scenario::ctx(scenario));
        test_scenario::next_tx(scenario, @0x2);  // Non-admin
        skillpass::add_issuer(&mut registry, @0x3, b"Test", test_scenario::ctx(scenario));  // Abort
        test_scenario::return_shared(registry);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_add_issuer_success() {
        let scenario_val = test_scenario::begin(@0x1);
        let scenario = &mut scenario_val;
        let admin = @0x1;
        let registry = skillpass::create_registry(admin, test_scenario::ctx(scenario));
        test_scenario::next_tx(scenario, admin);
        skillpass::add_issuer(&mut registry, @0x3, b"Test Uni", test_scenario::ctx(scenario));
        assert!(skillpass::is_authorized_issuer(&registry, @0x3) == true, 1);
        test_scenario::return_shared(registry);
        test_scenario::end(scenario_val);
    }

    
}