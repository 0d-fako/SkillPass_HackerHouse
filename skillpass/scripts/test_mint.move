// Test script for minting certificate
script {
    use skillpass::certificate_registry;
    use sui::clock;

    fun test_mint_certificate(
        registry: &mut certificate_registry::CertificateRegistry,
        clock: &clock::Clock,
        ctx: &mut sui::tx_context::TxContext
    ) {
        let student_address = @0x83b3e15b0f43aacdbd39ede604391ef9720df83b33420fb72deef7f8e795cbe9;
        let credential_type = b"Bachelor of Computer Science";
        let grade = std::option::some(b"First Class");
        
        certificate_registry::mint_certificate(
            registry,
            student_address,
            credential_type,
            grade,
            clock,
            ctx
        );
    }
}