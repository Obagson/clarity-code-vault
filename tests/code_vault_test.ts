import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new project",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        let block = chain.mineBlock([
            Tx.contractCall('code_vault', 'create-project', [
                types.ascii("Test Project"),
                types.ascii("A test project description"),
                types.bool(true)
            ], wallet_1.address)
        ]);
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Verify project details
        let getProject = chain.callReadOnlyFn(
            'code_vault',
            'get-project',
            [types.uint(1)],
            wallet_1.address
        );
        let project = getProject.result.expectSome().expectTuple();
        assertEquals(project.name, "Test Project");
        assertEquals(project.owner, wallet_1.address);
        assertEquals(project.is_public, true);
    }
});

Clarinet.test({
    name: "Can add and verify project members",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        // Create project
        let block = chain.mineBlock([
            Tx.contractCall('code_vault', 'create-project', [
                types.ascii("Team Project"),
                types.ascii("A team project"),
                types.bool(false)
            ], wallet_1.address)
        ]);
        
        // Add member
        block = chain.mineBlock([
            Tx.contractCall('code_vault', 'add-project-member', [
                types.uint(1),
                types.principal(wallet_2.address),
                types.uint(2)  // Write access
            ], wallet_1.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify member access
        let getAccess = chain.callReadOnlyFn(
            'code_vault',
            'get-member-access',
            [types.uint(1), types.principal(wallet_2.address)],
            wallet_1.address
        );
        assertEquals(getAccess.result, types.uint(2));
    }
});

Clarinet.test({
    name: "Can record project commits",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        // Create project
        let block = chain.mineBlock([
            Tx.contractCall('code_vault', 'create-project', [
                types.ascii("Commit Test"),
                types.ascii("Testing commits"),
                types.bool(true)
            ], wallet_1.address)
        ]);
        
        // Record commit
        block = chain.mineBlock([
            Tx.contractCall('code_vault', 'record-commit', [
                types.uint(1),
                types.ascii("abc123def456"),
                types.ascii("Initial commit")
            ], wallet_1.address)
        ]);
        block.receipts[0].result.expectOk().expectUint(1);
    }
});