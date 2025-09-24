module skillpass::skillpass {
    use sui::object::{Self, UID};
    use sui::tx_context::{tx_context, TxContext};
    use sui::transfer;
    use sui::dynamic_field as df;
    use sui::vec_map::{Self, VecMap};
    use sui::event;

    // Public registry struct
    public struct IssuerRegistry has key {
        id: UID,
        admin: address,
        issuers: VecMap<address, vector<u8>>,  // addr -> metadata
    }

    // Public event struct
    public struct NewIssuerAdded has copy, drop {
        addr: address,
        metadata: vector<u8>,
    }

    public fun create_registry(admin: address, ctx: &mut TxContext) {
        let registry = IssuerRegistry {
            id: object::new(ctx),
            admin,
            issuers: vec_map::empty(),
        };
        transfer::share_object(registry);
    }

    public entry fun add_issuer(registry: &mut IssuerRegistry, new_addr: address, metadata: vector<u8>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == registry.admin, 0);  // Unauthorized
        vec_map::insert(&mut registry.issuers, new_addr, metadata);
        event::emit(NewIssuerAdded { addr: new_addr, metadata });  // Use fields
    }

    public fun is_authorized_issuer(registry: &IssuerRegistry, addr: address): bool {
        vec_map::contains(&registry.issuers, &addr)
    }
}

module skillpass::education_passport {
    // Passport NFT struct
    // mint_passport function
    // add_xp function
    // verify_passport function
    // XP tracking logic
}