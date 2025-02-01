import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new project with main branch",
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
        assertEquals(project.default_branch, "main");

        // Verify main branch exists
        let getBranch = chain.callReadOnlyFn(
            'code_vault',
            'get-branch',
            [types.uint(1), types.ascii("main")],
            wallet_1.address
        );
        let branch = getBranch.result.expectSome().expectTuple();
        assertEquals(branch.base_branch, "main");
    }
});

Clarinet.test({
    name: "Can create and use feature branches",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        // Create project
        let block = chain.mineBlock([
            Tx.contractCall('code_vault', 'create-project', [
                types.ascii("Branch Test"),
                types.ascii("Testing branches"),
                types.bool(true)
            ], wallet_1.address)
        ]);
        
        // Create feature branch
        block = chain.mineBlock([
            Tx.contractCall('code_vault', 'create-branch', [
                types.uint(1),
                types.ascii("feature-1"),
                types.ascii("main")
            ], wallet_1.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);

        // Record commit on feature branch
        block = chain.mineBlock([
            Tx.contractCall('code_vault', 'record-commit', [
                types.uint(1),
                types.ascii("abc123def456"),
                types.ascii("Feature commit"),
                types.ascii("feature-1")
            ], wallet_1.address)
        ]);
        block.receipts[0].result.expectOk().expectUint(1);

        // Verify branch information
        let getBranch = chain.callReadOnlyFn(
            'code_vault',
            'get-branch',
            [types.uint(1), types.ascii("feature-1")],
            wallet_1.address
        );
        let branch = getBranch.result.expectSome().expectTuple();
        assertEquals(branch.last_commit, types.uint(1));
    }
});
