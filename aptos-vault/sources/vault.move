module vault::vault {
    use std::signer;
    use aptos_framework::timestamp;

    // Vault configuration
    const VAULT_NAME: vector<u8> = b"Aptos Vault";
    const VAULT_SYMBOL: vector<u8> = b"VAULT";
    const DECIMALS: u8 = 8;
    const INITIAL_SHARES: u64 = 100000000; // 1 share = 1e8

    // USDT LayerZero address on Aptos Mainnet
    // Source: https://explorer.aptoslabs.com/coin/0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT?network=mainnet
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
    }

    // User shares
    struct UserShares has key {
        shares: u64,
        last_deposit: u64,
        last_withdraw: u64,
    }

    // Vault events
    struct DepositEvent has drop, store {
        user: address,
        amount: u64,
        shares_minted: u64,
        timestamp: u64,
    }

    struct WithdrawEvent has drop, store {
        user: address,
        amount: u64,
        shares_burned: u64,
        timestamp: u64,
    }

    struct RebalanceEvent has drop, store {
        usdt_amount: u64,
        apt_amount: u64,
        timestamp: u64,
    }

    // Error codes
    const EZERO_AMOUNT: u64 = 1;
    const EINSUFFICIENT_SHARES: u64 = 2;
    const EINSUFFICIENT_BALANCE: u64 = 3;
    const EVAULT_NOT_INITIALIZED: u64 = 4;
    const EUSER_NOT_FOUND: u64 = 5;

    // Initialize vault
    public entry fun initialize_vault(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        
        // Create vault resource
        move_to(owner, VaultResource {
            total_shares: INITIAL_SHARES,
            total_usdt: 0,
            total_apt: 0,
            owner: owner_addr,
            created_at: timestamp::now_seconds(),
        });

        // Create user shares for owner
        move_to(owner, UserShares {
            shares: INITIAL_SHARES,
            last_deposit: timestamp::now_seconds(),
            last_withdraw: 0,
        });
    }

    // Deposit USDT into vault
    public entry fun deposit(
        user: &signer,
        amount: u64,
    ) acquires VaultResource, UserShares {
        if (amount == 0) {
            return
        };

        let user_addr = signer::address_of(user);
        let vault = borrow_global_mut<VaultResource>(@vault);
        
        // Calculate shares to mint
        let shares_to_mint = if (vault.total_shares == INITIAL_SHARES && vault.total_usdt == 0) {
            // First deposit
            amount
        } else {
            // Calculate proportional shares
            (amount * vault.total_shares) / vault.total_usdt
        };

        // Update vault state
        vault.total_usdt = vault.total_usdt + amount;
        vault.total_shares = vault.total_shares + shares_to_mint;

        // Update or create user shares
        if (exists<UserShares>(user_addr)) {
            let user_shares = borrow_global_mut<UserShares>(user_addr);
            user_shares.shares = user_shares.shares + shares_to_mint;
            user_shares.last_deposit = timestamp::now_seconds();
        } else {
            move_to(user, UserShares {
                shares: shares_to_mint,
                last_deposit: timestamp::now_seconds(),
                last_withdraw: 0,
            });
        };
    }

    // Withdraw USDT from vault
    public entry fun withdraw(
        user: &signer,
        shares_to_burn: u64,
    ) acquires VaultResource, UserShares {
        if (shares_to_burn == 0) {
            return
        };

        let user_addr = signer::address_of(user);
        
        if (!exists<UserShares>(user_addr)) {
            return
        };

        let user_shares = borrow_global_mut<UserShares>(user_addr);
        
        if (user_shares.shares < shares_to_burn) {
            return
        };

        let vault = borrow_global_mut<VaultResource>(@vault);
        
        // Calculate USDT to withdraw
        let usdt_to_withdraw = (shares_to_burn * vault.total_usdt) / vault.total_shares;
        
        if (usdt_to_withdraw > vault.total_usdt) {
            return
        };

        // Update vault state
        vault.total_shares = vault.total_shares - shares_to_burn;
        vault.total_usdt = vault.total_usdt - usdt_to_withdraw;

        // Update user shares
        user_shares.shares = user_shares.shares - shares_to_burn;
        user_shares.last_withdraw = timestamp::now_seconds();
    }

    // Rebalance vault (swap USDT for APT)
    public entry fun rebalance(
        owner: &signer,
        usdt_amount: u64,
    ) acquires VaultResource {
        let owner_addr = signer::address_of(owner);
        let vault = borrow_global_mut<VaultResource>(@vault);
        
        if (vault.owner != owner_addr) {
            return
        };

        if (usdt_amount == 0 || usdt_amount > vault.total_usdt) {
            return
        };

        // Calculate APT amount (simplified 1:1 ratio for demo)
        let apt_amount = usdt_amount;
        
        // Update vault balances
        vault.total_usdt = vault.total_usdt - usdt_amount;
        vault.total_apt = vault.total_apt + apt_amount;
    }

    // Get vault status
    #[view]
    public fun get_vault_status(): (u64, u64, u64, u64) acquires VaultResource {
        if (!exists<VaultResource>(@vault)) {
            return (0, 0, 0, 0)
        };
        
        let vault = borrow_global<VaultResource>(@vault);
        (vault.total_shares, vault.total_usdt, vault.total_apt, vault.created_at)
    }

    // Get user balance
    #[view]
    public fun get_user_balance(user_addr: address): (u64, u64) acquires VaultResource, UserShares {
        if (!exists<UserShares>(user_addr)) {
            return (0, 0)
        };
        
        let user_shares = borrow_global<UserShares>(user_addr);
        let vault = borrow_global<VaultResource>(@vault);
        
        let usdt_balance = if (vault.total_shares > 0) {
            (user_shares.shares * vault.total_usdt) / vault.total_shares
        } else {
            0
        };
        
        (user_shares.shares, usdt_balance)
    }

    // Get vault owner
    #[view]
    public fun get_vault_owner(): address acquires VaultResource {
        let vault = borrow_global<VaultResource>(@vault);
        vault.owner
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
} 