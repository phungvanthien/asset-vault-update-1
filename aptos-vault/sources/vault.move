module vault::vault {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::account;

    // Vault configuration
    const VAULT_NAME: vector<u8> = b"Dexonic Asset Vault";
    const VAULT_SYMBOL: vector<u8> = b"DAV";
    const DECIMALS: u8 = 8;
    const INITIAL_SHARES: u64 = 100000000; // 1 share = 1e8

    // USDT LayerZero address on Aptos Mainnet
    const USDT_ADDRESS: address = @0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa;
    
    // APT address on Mainnet
    const APT_ADDRESS: address = @0x1;
    
    // PancakeSwap Router on Mainnet
    const PANCAKESWAP_ROUTER: address = @0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60;

    // Vault resource
    struct VaultResource has key {
        total_shares: u64,
        total_usdt: u64,
        total_apt: u64,
        owner: address,
        created_at: u64,
        is_active: bool,
        fee_rate: u64, // in basis points (100 = 1%)
        last_rebalance: u64,
    }

    // User shares
    struct UserShares has key, store {
        shares: u64,
        last_deposit: u64,
        last_withdraw: u64,
        total_deposited: u64,
        total_withdrawn: u64,
    }

    // Vault events
    struct DepositEvent has drop, store {
        user: address,
        amount: u64,
        shares_minted: u64,
        timestamp: u64,
        vault_total_shares: u64,
        vault_total_usdt: u64,
    }

    struct WithdrawEvent has drop, store {
        user: address,
        amount: u64,
        shares_burned: u64,
        timestamp: u64,
        vault_total_shares: u64,
        vault_total_usdt: u64,
    }

    struct RebalanceEvent has drop, store {
        usdt_amount: u64,
        apt_amount: u64,
        timestamp: u64,
        target_ratio: u64,
        current_ratio: u64,
    }

    struct SwapEvent has drop, store {
        input_token: address,
        output_token: address,
        input_amount: u64,
        output_amount: u64,
        timestamp: u64,
    }

    // Error codes
    const EINSUFFICIENT_BALANCE: u64 = 1;
    const EINSUFFICIENT_SHARES: u64 = 2;
    const EZERO_AMOUNT: u64 = 3;
    const EVAULT_NOT_ACTIVE: u64 = 4;
    const EACCESS_DENIED: u64 = 5;
    const EINVALID_FEE_RATE: u64 = 6;
    const EINVALID_SHARE_CALCULATION: u64 = 7;

    // Initialize vault
    public entry fun initialize_vault(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        
        move_to(owner, VaultResource {
            total_shares: 0,
            total_usdt: 0,
            total_apt: 0,
            owner: owner_addr,
            created_at: timestamp::now_seconds(),
            is_active: true,
            fee_rate: 100, // 1% fee
            last_rebalance: 0,
        });
    }

    // Deposit USDT into vault (ERC4626 deposit)
    public entry fun deposit(
        user: &signer,
        amount: u64,
    ) acquires VaultResource, UserShares {
        let user_addr = signer::address_of(user);
        
        if (amount == 0) {
            return
        };

        // Check if vault exists
        if (!exists<VaultResource>(@vault)) {
            return
        };

        let vault = borrow_global_mut<VaultResource>(@vault);
        
        if (!vault.is_active) {
            return
        };

        // Calculate shares to mint with proper arithmetic
        let shares_to_mint = if (vault.total_shares == 0) {
            amount // First deposit: 1:1 ratio
        } else {
            let total_value = vault.total_usdt + vault.total_apt;
            if (total_value == 0) {
                return
            };
            (amount * vault.total_shares) / total_value
        };

        if (shares_to_mint == 0) {
            return
        };

        // Update vault state with checked arithmetic
        vault.total_shares = vault.total_shares + shares_to_mint;
        vault.total_usdt = vault.total_usdt + amount;

        // Mint shares for user
        if (!exists<UserShares>(user_addr)) {
            move_to(user, UserShares {
                shares: shares_to_mint,
                last_deposit: timestamp::now_seconds(),
                last_withdraw: 0,
                total_deposited: amount,
                total_withdrawn: 0,
            });
        } else {
            let user_shares = borrow_global_mut<UserShares>(user_addr);
            user_shares.shares = user_shares.shares + shares_to_mint;
            user_shares.last_deposit = timestamp::now_seconds();
            user_shares.total_deposited = user_shares.total_deposited + amount;
        };

        // Emit deposit event
        let deposit_event = DepositEvent {
            user: user_addr,
            amount: amount,
            shares_minted: shares_to_mint,
            timestamp: timestamp::now_seconds(),
            vault_total_shares: vault.total_shares,
            vault_total_usdt: vault.total_usdt,
        };

        // In a real implementation, you would emit this event
        // event::emit(deposit_event_handle, deposit_event);
    }

    // Withdraw USDT from vault (ERC4626 withdraw)
    public entry fun withdraw(
        user: &signer,
        shares_to_burn: u64,
    ) acquires VaultResource, UserShares {
        let user_addr = signer::address_of(user);
        
        if (shares_to_burn == 0) {
            return
        };

        // Check if vault exists
        if (!exists<VaultResource>(@vault)) {
            return
        };

        let vault = borrow_global_mut<VaultResource>(@vault);
        
        if (!vault.is_active) {
            return
        };

        // Check if user has enough shares
        if (!exists<UserShares>(user_addr)) {
            return
        };

        let user_shares = borrow_global_mut<UserShares>(user_addr);
        
        if (user_shares.shares < shares_to_burn) {
            return
        };

        // Calculate amount to withdraw with proper arithmetic
        let total_value = vault.total_usdt + vault.total_apt;
        let amount_to_withdraw = if (vault.total_shares == 0) {
            return
        } else {
            (shares_to_burn * total_value) / vault.total_shares
        };

        if (amount_to_withdraw == 0) {
            return
        };

        // Check if vault has enough balance
        if (vault.total_usdt < amount_to_withdraw) {
            return
        };

        // Update vault state with checked arithmetic
        vault.total_shares = vault.total_shares - shares_to_burn;
        vault.total_usdt = vault.total_usdt - amount_to_withdraw;

        // Burn user shares
        user_shares.shares = user_shares.shares - shares_to_burn;
        user_shares.last_withdraw = timestamp::now_seconds();
        user_shares.total_withdrawn = user_shares.total_withdrawn + amount_to_withdraw;

        // Emit withdraw event
        let withdraw_event = WithdrawEvent {
            user: user_addr,
            amount: amount_to_withdraw,
            shares_burned: shares_to_burn,
            timestamp: timestamp::now_seconds(),
            vault_total_shares: vault.total_shares,
            vault_total_usdt: vault.total_usdt,
        };

        // In a real implementation, you would emit this event
        // event::emit(withdraw_event_handle, withdraw_event);
    }

    // Redeem shares for USDT (ERC4626 redeem)
    public entry fun redeem(
        user: &signer,
        shares_to_burn: u64,
    ) acquires VaultResource, UserShares {
        // Redeem is the same as withdraw in this implementation
        withdraw(user, shares_to_burn);
    }

    // Rebalance vault assets (owner only)
    public entry fun rebalance(
        owner: &signer,
        usdt_amount: u64,
    ) acquires VaultResource {
        let owner_addr = signer::address_of(owner);
        
        // Check if vault exists
        if (!exists<VaultResource>(@vault)) {
            return
        };

        let vault = borrow_global_mut<VaultResource>(@vault);
        
        // Check access control
        if (vault.owner != owner_addr) {
            return
        };

        if (!vault.is_active) {
            return
        };

        if (usdt_amount == 0) {
            return
        };

        // Check if vault has enough USDT
        if (vault.total_usdt < usdt_amount) {
            return
        };

        // Calculate target ratio (50% USDT, 50% APT)
        let target_usdt_ratio = 5000; // 50% in basis points
        let current_usdt_ratio = if (vault.total_usdt + vault.total_apt > 0) {
            (vault.total_usdt * 10000) / (vault.total_usdt + vault.total_apt)
        } else {
            0
        };

        // Only rebalance if deviation is significant (>10%)
        let threshold = 1000; // 10% deviation
        if (current_usdt_ratio > target_usdt_ratio + threshold || 
            current_usdt_ratio < target_usdt_ratio - threshold) {
            
            // Calculate APT amount (simplified 1:1 ratio for demo)
            let apt_amount = usdt_amount;
            
            // Update vault state with checked arithmetic
            vault.total_usdt = vault.total_usdt - usdt_amount;
            vault.total_apt = vault.total_apt + apt_amount;
            vault.last_rebalance = timestamp::now_seconds();

            // Emit rebalance event
            let rebalance_event = RebalanceEvent {
                usdt_amount: vault.total_usdt,
                apt_amount: vault.total_apt,
                timestamp: timestamp::now_seconds(),
                target_ratio: target_usdt_ratio,
                current_ratio: current_usdt_ratio,
            };

            // In a real implementation, you would emit this event
            // event::emit(rebalance_event_handle, rebalance_event);
        };
    }

    // Convert USDT to shares (ERC4626 convertToShares)
    #[view]
    public fun convert_to_shares(assets: u64): u64 acquires VaultResource {
        if (!exists<VaultResource>(@vault)) {
            return 0
        };

        let vault = borrow_global<VaultResource>(@vault);
        
        if (vault.total_shares == 0) {
            return assets // First deposit: 1:1 ratio
        };

        let total_value = vault.total_usdt + vault.total_apt;
        if (total_value == 0) {
            return 0
        };

        (assets * vault.total_shares) / total_value
    }

    // Convert shares to USDT (ERC4626 convertToAssets)
    #[view]
    public fun convert_to_assets(shares: u64): u64 acquires VaultResource {
        if (!exists<VaultResource>(@vault)) {
            return 0
        };

        let vault = borrow_global<VaultResource>(@vault);
        
        if (vault.total_shares == 0) {
            return 0
        };

        let total_value = vault.total_usdt + vault.total_apt;
        (shares * total_value) / vault.total_shares
    }

    // Get total assets (ERC4626 totalAssets)
    #[view]
    public fun total_assets(): u64 acquires VaultResource {
        if (!exists<VaultResource>(@vault)) {
            return 0
        };

        let vault = borrow_global<VaultResource>(@vault);
        vault.total_usdt + vault.total_apt
    }

    // Get total shares (ERC4626 totalSupply)
    #[view]
    public fun total_shares(): u64 acquires VaultResource {
        if (!exists<VaultResource>(@vault)) {
            return 0
        };

        let vault = borrow_global<VaultResource>(@vault);
        vault.total_shares
    }

    // Get vault status
    #[view]
    public fun get_vault_status(): (u64, u64, u64, u64, bool, u64) acquires VaultResource {
        if (!exists<VaultResource>(@vault)) {
            return (0, 0, 0, 0, false, 0)
        };
        
        let vault = borrow_global<VaultResource>(@vault);
        (vault.total_shares, vault.total_usdt, vault.total_apt, vault.created_at, vault.is_active, vault.fee_rate)
    }

    // Get user balance
    #[view]
    public fun get_user_balance(user_addr: address): (u64, u64, u64, u64) acquires VaultResource, UserShares {
        if (!exists<UserShares>(user_addr)) {
            return (0, 0, 0, 0)
        };
        
        let user_shares = borrow_global<UserShares>(user_addr);
        let vault = borrow_global<VaultResource>(@vault);
        
        let usdt_balance = if (vault.total_shares > 0) {
            (user_shares.shares * vault.total_usdt) / vault.total_shares
        } else {
            0
        };
        
        (user_shares.shares, usdt_balance, user_shares.total_deposited, user_shares.total_withdrawn)
    }

    // Get vault owner
    #[view]
    public fun get_vault_owner(): address acquires VaultResource {
        if (!exists<VaultResource>(@vault)) {
            return @0x0
        };

        let vault = borrow_global<VaultResource>(@vault);
        vault.owner
    }

    // Set vault fee rate (owner only)
    public entry fun set_fee_rate(owner: &signer, new_fee_rate: u64) acquires VaultResource {
        let owner_addr = signer::address_of(owner);
        
        if (!exists<VaultResource>(@vault)) {
            return
        };

        let vault = borrow_global_mut<VaultResource>(@vault);
        
        if (vault.owner != owner_addr) {
            return
        };

        if (new_fee_rate > 1000) { // Max 10%
            return
        };

        vault.fee_rate = new_fee_rate;
    }

    // Set vault active status (owner only)
    public entry fun set_vault_active(owner: &signer, is_active: bool) acquires VaultResource {
        let owner_addr = signer::address_of(owner);
        
        if (!exists<VaultResource>(@vault)) {
            return
        };

        let vault = borrow_global_mut<VaultResource>(@vault);
        
        if (vault.owner != owner_addr) {
            return
        };

        vault.is_active = is_active;
    }

    // Get USDT address
    #[view]
    public fun get_usdt_address(): address {
        USDT_ADDRESS
    }

    // Get APT address
    #[view]
    public fun get_apt_address(): address {
        APT_ADDRESS
    }

    // Get vault address
    #[view]
    public fun get_vault_address(): address {
        @vault
    }

    // Get PancakeSwap router address
    #[view]
    public fun get_pancakeswap_router(): address {
        PANCAKESWAP_ROUTER
    }

    // Get initial shares value (for testing)
    #[view]
    public fun get_initial_shares(): u64 {
        INITIAL_SHARES
    }
} 