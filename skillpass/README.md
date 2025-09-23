# SkillPass Smart Contract

## Overview
Move contracts for dynamic NFT passports. Deployed package ID: [Paste after deploy, e.g., 0xabc123].

## Key Modules
- **issuer_registry.move**: Manages authorized issuers (shared object).
- **education_passport.move**: Handles passport NFTs (owned objects).

## Functions (ABI Guide)
Use Sui JS SDK to call: `tx.moveCall({ target: 'package::module::func', arguments: [...] })`.

### 1. create_registry(admin: address)
- **Purpose**: Setup issuer list (call once).
- **Send**: Admin address (e.g., `tx.pure('0xadmin_wallet')`).
- **Expect**: New shared registry object ID (query via `getObject`).
- **Gas**: ~0.001 SUI.

### 2. add_issuer(registry: &mut IssuerRegistry, new_addr: address, metadata: vector<u8>)
- **Purpose**: Add new issuer (admin only).
- **Send**: Registry object ID (as `ObjectArg`), new issuer address (`tx.pure('0xnew_issuer')`), metadata string (e.g., `tx.pure('UNILAG')` as UTF-8 bytes).
- **Expect**: Updated registry; event `NewIssuerAdded { addr, metadata }` (subscribe via SDK).
- **Gas**: ~0.002 SUI.

### 3. is_authorized_issuer(registry: &IssuerRegistry, addr: address): bool
- **Purpose**: Check if address can issue (view-only).
- **Send**: Registry ID, address to check.
- **Expect**: Boolean true/false (read via `programmableTransactionBlock` or query).
- **Gas**: Negligible (view).

### 4. mint_passport(initial_cred: vector<u8])
- **Purpose**: Create starter/formal passport NFT.
- **Send**: Cred details as string (e.g., `tx.pure('BSc CS, UNILAG 2023')` as bytes).
- **Expect**: New NFT object ID (owned by caller/user); initial XP=0.
- **Gas**: ~0.005 SUI. (Issuer-only via auth check.)

### 5. add_xp(passport: &mut Passport, amount: u64, registry: &IssuerRegistry)
- **Purpose**: Evolve passport with skill XP.
- **Send**: Passport object ID, XP amount (e.g., `tx.pure(20u64)`), registry ID.
- **Expect**: Updated XP; dynamic field added (skill log); event `XpUpdate { amount, verifier }`.
- **Gas**: ~0.003 SUI. (Issuer-only.)

### 6. verify_passport(passport: &Passport, min_xp: u64): bool
- **Purpose**: Validate passport level.
- **Send**: Passport ID, min XP (e.g., `tx.pure(50u64)`).
- **Expect**: Boolean + XP metadata (read via `getObject`).
- **Gas**: Negligible (view).

## Events to Watch
- `NewIssuerAdded`: New issuer onboarded.
- `XpUpdate`: Skill endorsed (subscribe: `client.onTransaction({ filter: { MoveEventType: 'package::module::XpUpdate' } })`).

## Integration Tips for Frontend
- Use `@mysten/sui.js` SDK: Import `getFullnodeUrl`, `TransactionBlock`.
- Example Mint Call (JS):
  ```js
  const tx = new TransactionBlock();
  tx.moveCall({
    target: '0xPACKAGE::education_passport::mint_passport',
    arguments: [tx.pure('BSc CS')],
  });
  const result = await client.signAndExecuteTransaction({ signer, transaction: tx });