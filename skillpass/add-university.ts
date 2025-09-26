import { Transaction } from '@mysten/sui/transactions';
import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';

// Contract configuration
const PACKAGE_ID = "0xf1cb82954194f281b4bcddee3b8922b81322cd742d2ab23d169dfaf11883c736";
const REGISTRY_ID = "0x6c0bab54d2c4ba3caba62063cb7e972370e60deb9dbbe2fd46f825897bde0bdd";
const UNIVERSITY_ADDRESS = "0xc9b77d442570dafd4737da69ad2d3eadd36eb5eca8ecd021037979b117c35e2d";
const ADMIN_ADDRESS = "0x83b3e15b0f43aacdbd39ede604391ef9720df83b33420fb72deef7f8e795cbe9";

async function addUniversity() {
    // Create a Sui client
    const client = new SuiClient({
        url: getFullnodeUrl('testnet')
    });
    
    // Create a new transaction
    const tx = new Transaction();
    
    // Set the sender to the admin address
    tx.setSender(ADMIN_ADDRESS);
    
    // Call the add_university function
    tx.moveCall({
        target: `${PACKAGE_ID}::certificate_registry::add_university`,
        arguments: [
            tx.object(REGISTRY_ID),
            tx.pure.address(UNIVERSITY_ADDRESS)
        ],
    });
    
    // Build the transaction
    const txBytes = await tx.build({
        client,
        onlyTransactionKind: false
    });
    
    // Save the transaction to a file
    require('fs').writeFileSync('add_university_transaction.json', JSON.stringify(Array.from(txBytes)));
    
    console.log("Transaction created successfully!");
    console.log("Package ID:", PACKAGE_ID);
    console.log("Registry ID:", REGISTRY_ID);
    console.log("University Address to Add:", UNIVERSITY_ADDRESS);
    console.log("Sender (Admin) Address:", ADMIN_ADDRESS);
    console.log("\nTo execute this transaction, run:");
    console.log("sui client sign-and-execute-tx-block --tx-file add_university_transaction.json");
}

addUniversity().catch(console.error);