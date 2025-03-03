import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
    name: "Cannot add member with invalid access level",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('code_vault', 'create-project', [
                types.ascii("Test Project"),
                types.ascii("Description"),
                types.bool(true)
            ], wallet_1.address)
        ]);
        
        block = chain.mineBlock([
            Tx.contractCall('code_vault', 'add-project-member', [
                types.uint(1),
                wallet_2.address,
                types.uint(4)  // Invalid access level
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(104);
    }
});

Clarinet.test({
    name: "Cannot add existing member",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('code_vault', 'create-project', [
                types.ascii("Test Project"),
                types.ascii("Description"),
                types.bool(true)
            ], wallet_1.address),
            Tx.contractCall('code_vault', 'add-project-member', [
                types.uint(1),
                wallet_2.address,
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        block = chain.mineBlock([
            Tx.contractCall('code_vault', 'add-project-member', [
                types.uint(1),
                wallet_2.address,
                types.uint(2)
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(102);
    }
});

// [Rest of the tests remain unchanged...]
