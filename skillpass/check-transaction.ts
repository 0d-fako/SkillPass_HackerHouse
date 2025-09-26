import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';

async function checkTransaction() {
    const client = new SuiClient({
        url: getFullnodeUrl('testnet')
    });
    
    // Use the transaction digest from the dry run
    const txDigest = '7g3wCR5TZfhBXEUQaH9i44L3W9FjoXy2WhhsUYkJ6qCR';
    
    try {
        const tx = await client.getTransactionBlock({
            digest: txDigest,
            options: {
                showInput: true,
                showEffects: true,
                showEvents: true,
                showObjectChanges: true
            }
        });
        
        console.log("Transaction details:");
        console.log(JSON.stringify(tx, null, 2));
        
        // Look for created Certificate object
        if (tx.objectChanges) {
            const certificateObjects = tx.objectChanges.filter(change => 
                change.type === 'created' && 
                'objectType' in change && 
                change.objectType.includes('certificate')
            );
            
            console.log("Certificate objects created:");
            console.log(JSON.stringify(certificateObjects, null, 2));
        }
    } catch (error) {
        console.error("Error checking transaction:", error);
    }
}

checkTransaction().catch(console.error);