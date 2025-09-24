// Simple test script to mint certificate
script {
    use 0xf1cb82954194f281b4bcddee3b8922b81322cd742d2ab23d169dfaf11883c736::certificate_registry;
    use sui::clock;
    use std::option;

    fun test_mint_for_admin(
        registry: &mut certificate_registry::CertificateRegistry,
        clock: &clock::Clock,
        ctx: &mut sui::tx_context::TxContext
    ) {
        // Mint certificate for admin address
        let admin_addr = @0x83b3e15b0f43aacdbd39ede604391ef9720df83b33420fb72deef7f8e795cbe9;
        let credential_type = b"Master of Blockchain Technology";
        let grade = option::some(b"Distinction");
        let encryption_params = b"SEAL_test_encryption_params";
        let public_key_hash = b"test_public_key_hash_12345678";
        let access_policy = b"[\"admin\",\"test_access\"]";
        
        certificate_registry::mint_encrypted_certificate(
            registry,
            admin_addr,
            credential_type,
            grade,
            encryption_params,
            public_key_hash,
            access_policy,
            clock,
            ctx
        );
    }
}