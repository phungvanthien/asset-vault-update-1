module vault::vault_core_simple {
    use std::signer;
    use aptos_framework::timestamp;

    // Vault storage for managing shares
    struct VaultStorage has key {
        total_shares: u64,
        vault_manager: address,
        is_active: bool,
        created_at: u64,
        last_rebalance: u64,
        fee_rate: u64, // in basis points
    }

    // Vault shares for tracking user ownership
    struct VaultShares has key, store {
        shares: u64,
        last_deposit: u64,
        last_withdraw: u64,
        total_deposited: u64,
        total_withdrawn: u64,
    }

    // Vault manager capability
    struct VaultManagerCap has key {
        vault_id: u64,
        manager_addr: address,
    }

    // Asset pool for tracking vault assets
    struct AssetPool has key {
        usdt_balance: u64,
        apt_balance: u64,
        total_value: u64,
        last_update: u64,
    }

    // Rebalance strategy
    struct RebalanceStrategy has drop, store {
        target_usdt_ratio: u64, // in basis points
        rebalance_threshold: u64, // in basis points
        max_slippage: u64, // in basis points
    }

    // Vault events
    struct VaultEvent has drop, store {
        event_type: vector<u8>,
        user: address,
        amount: u64,
        shares: u64,
        timestamp: u64,
    }

    // Error codes
    const EINSUFFICIENT_SHARES: u64 = 2;
    const EZERO_AMOUNT: u64 = 3;
    const EVAULT_NOT_FOUND: u64 = 4;
    const EACCESS_DENIED: u64 = 5;
    const EVAULT_NOT_ACTIVE: u64 = 6;
    const EINVALID_FEE_RATE: u64 = 7;
    const EINSUFFICIENT_BALANCE: u64 = 8;

    // Initialize vault module
    fun init_module(account: &signer) {
        // Module initialization logic can be added here
    }

    // Create a new vault
    public entry fun create_vault(
        vault_manager: &signer,
    ) {
        let vault_manager_addr = signer::address_of(vault_manager);
        
        // Create vault storage
        move_to(vault_manager, VaultStorage {
            total_shares: 0,
            vault_manager: vault_manager_addr,
            is_active: true,
            created_at: timestamp::now_seconds(),
            last_rebalance: 0,
            fee_rate: 100, // 1% fee
        });

        // Create vault manager capability
        move_to(vault_manager, VaultManagerCap {
            vault_id: 0,
            manager_addr: vault_manager_addr,
        });

        // Create asset pool
        move_to(vault_manager, AssetPool {
            usdt_balance: 0,
            apt_balance: 0,
            total_value: 0,
            last_update: timestamp::now_seconds(),
        });
    }

    // Mint shares for user (ERC4626 equivalent)
    public entry fun mint_shares(
        user: &signer,
        amount: u64,
    ) acquires VaultStorage, VaultShares, AssetPool {
        let user_addr = signer::address_of(user);
        
        if (amount == 0) {
            return
        };

        let vault_storage = borrow_global_mut<VaultStorage>(user_addr);
        
        if (!vault_storage.is_active) {
            return
        };

        // Calculate shares to mint (ERC4626 formula with fee)
        let shares_to_mint = if (vault_storage.total_shares == 0) {
            // First deposit
            amount
        } else {
            // Calculate proportional shares with fee
            let fee_amount = (amount * vault_storage.fee_rate) / 10000;
            let net_amount = amount - fee_amount;
            (net_amount * vault_storage.total_shares) / vault_storage.total_shares
        };
        
        // Update vault storage
        vault_storage.total_shares = vault_storage.total_shares + shares_to_mint;
        
        // Update asset pool
        let asset_pool = borrow_global_mut<AssetPool>(user_addr);
        asset_pool.usdt_balance = asset_pool.usdt_balance + amount;
        asset_pool.total_value = asset_pool.total_value + amount;
        asset_pool.last_update = timestamp::now_seconds();
        
        // Mint shares for user
        if (!exists<VaultShares>(user_addr)) {
            move_to(user, VaultShares {
                shares: shares_to_mint,
                last_deposit: timestamp::now_seconds(),
                last_withdraw: 0,
                total_deposited: amount,
                total_withdrawn: 0,
            });
        } else {
            let user_shares = borrow_global_mut<VaultShares>(user_addr);
            user_shares.shares = user_shares.shares + shares_to_mint;
            user_shares.last_deposit = timestamp::now_seconds();
            user_shares.total_deposited = user_shares.total_deposited + amount;
        };
    }

    // Burn shares from user (ERC4626 equivalent)
    public entry fun burn_shares(
        user: &signer,
        shares_to_burn: u64,
    ) acquires VaultStorage, VaultShares, AssetPool {
        let user_addr = signer::address_of(user);
        
        if (shares_to_burn == 0) {
            return
        };

        // Check if user has enough shares
        if (!exists<VaultShares>(user_addr)) {
            return
        };

        let user_shares = borrow_global_mut<VaultShares>(user_addr);
        if (user_shares.shares < shares_to_burn) {
            return
        };

        let vault_storage = borrow_global_mut<VaultStorage>(user_addr);
        
        if (!vault_storage.is_active) {
            return
        };

        // Calculate USDT to withdraw (ERC4626 formula)
        let usdt_to_withdraw = if (vault_storage.total_shares > 0) {
            (shares_to_burn * vault_storage.total_shares) / vault_storage.total_shares
        } else {
            0
        };

        // Update vault storage
        vault_storage.total_shares = vault_storage.total_shares - shares_to_burn;
        
        // Update asset pool
        let asset_pool = borrow_global_mut<AssetPool>(user_addr);
        asset_pool.usdt_balance = asset_pool.usdt_balance - usdt_to_withdraw;
        asset_pool.total_value = asset_pool.total_value - usdt_to_withdraw;
        asset_pool.last_update = timestamp::now_seconds();
        
        // Burn shares
        user_shares.shares = user_shares.shares - shares_to_burn;
        user_shares.last_withdraw = timestamp::now_seconds();
        user_shares.total_withdrawn = user_shares.total_withdrawn + usdt_to_withdraw;
    }

    // Rebalance vault assets
    public entry fun rebalance_vault(
        manager: &signer,
        usdt_amount: u64,
    ) acquires VaultStorage, AssetPool {
        let manager_addr = signer::address_of(manager);
        
        if (!exists<VaultStorage>(manager_addr)) {
            return
        };

        let vault_storage = borrow_global_mut<VaultStorage>(manager_addr);
        
        if (vault_storage.vault_manager != manager_addr) {
            return
        };

        if (!vault_storage.is_active) {
            return
        };

        let asset_pool = borrow_global_mut<AssetPool>(manager_addr);
        
        if (usdt_amount > asset_pool.usdt_balance) {
            return
        };

        // Calculate target ratio (50% USDT, 50% APT)
        let target_usdt_ratio = 5000; // 50% in basis points
        let current_usdt_ratio = if (asset_pool.total_value > 0) {
            (asset_pool.usdt_balance * 10000) / asset_pool.total_value
        } else {
            0
        };

        // Only rebalance if deviation is significant (>10%)
        if (current_usdt_ratio > target_usdt_ratio + 1000 || current_usdt_ratio < target_usdt_ratio - 1000) {
            // Calculate APT amount (simplified 1:1 ratio for demo)
            let apt_amount = usdt_amount;
            
            // Update asset pool
            asset_pool.usdt_balance = asset_pool.usdt_balance - usdt_amount;
            asset_pool.apt_balance = asset_pool.apt_balance + apt_amount;
            asset_pool.last_update = timestamp::now_seconds();
            
            vault_storage.last_rebalance = timestamp::now_seconds();
        };
    }

    // Get user's share balance
    #[view]
    public fun get_balance(user_addr: address): u64 acquires VaultShares {
        if (exists<VaultShares>(user_addr)) {
            let user_shares = borrow_global<VaultShares>(user_addr);
            user_shares.shares
        } else {
            0
        }
    }

    // Get vault info
    #[view]
    public fun get_vault_info(vault_addr: address): (u64, u64, u64, bool, u64) acquires VaultStorage, AssetPool {
        if (exists<VaultStorage>(vault_addr)) {
            let vault_storage = borrow_global<VaultStorage>(vault_addr);
            let asset_pool = borrow_global<AssetPool>(vault_addr);
            (vault_storage.total_shares, asset_pool.usdt_balance, asset_pool.apt_balance, vault_storage.is_active, vault_storage.fee_rate)
        } else {
            (0, 0, 0, false, 0)
        }
    }

    // Convert assets to shares (ERC4626 equivalent)
    #[view]
    public fun convert_to_shares(vault_addr: address, assets: u64): u64 acquires VaultStorage {
        if (!exists<VaultStorage>(vault_addr)) {
            return 0
        };
        
        let vault_storage = borrow_global<VaultStorage>(vault_addr);
        
        if (vault_storage.total_shares == 0) {
            return assets
        };
        
        // Apply fee
        let fee_amount = (assets * vault_storage.fee_rate) / 10000;
        let net_assets = assets - fee_amount;
        
        (net_assets * vault_storage.total_shares) / vault_storage.total_shares
    }

    // Convert shares to assets (ERC4626 equivalent)
    #[view]
    public fun convert_to_assets(vault_addr: address, shares: u64): u64 acquires VaultStorage {
        if (!exists<VaultStorage>(vault_addr)) {
            return 0
        };
        
        let vault_storage = borrow_global<VaultStorage>(vault_addr);
        
        if (vault_storage.total_shares == 0) {
            return 0
        };
        
        (shares * vault_storage.total_shares) / vault_storage.total_shares
    }

    // Get total assets (ERC4626 equivalent)
    #[view]
    public fun total_assets(vault_addr: address): u64 acquires AssetPool {
        if (!exists<AssetPool>(vault_addr)) {
            return 0
        };
        
        let asset_pool = borrow_global<AssetPool>(vault_addr);
        asset_pool.total_value
    }

    // Get total shares (ERC4626 equivalent)
    #[view]
    public fun total_shares(vault_addr: address): u64 acquires VaultStorage {
        if (!exists<VaultStorage>(vault_addr)) {
            return 0
        };
        
        let vault_storage = borrow_global<VaultStorage>(vault_addr);
        vault_storage.total_shares
    }

    // Set vault fee rate (manager only)
    public entry fun set_fee_rate(
        manager: &signer,
        new_fee_rate: u64,
    ) acquires VaultStorage {
        let manager_addr = signer::address_of(manager);
        
        if (!exists<VaultStorage>(manager_addr)) {
            return
        };
        
        let vault_storage = borrow_global_mut<VaultStorage>(manager_addr);
        
        if (vault_storage.vault_manager != manager_addr) {
            return
        };
        
        if (new_fee_rate > 1000) { // Max 10%
            return
        };
        
        vault_storage.fee_rate = new_fee_rate;
    }

    // Set vault active status (manager only)
    public entry fun set_vault_active(
        manager: &signer,
        is_active: bool,
    ) acquires VaultStorage {
        let manager_addr = signer::address_of(manager);
        
        if (!exists<VaultStorage>(manager_addr)) {
            return
        };
        
        let vault_storage = borrow_global_mut<VaultStorage>(manager_addr);
        
        if (vault_storage.vault_manager != manager_addr) {
            return
        };
        
        vault_storage.is_active = is_active;
    }

    // Get vault manager
    #[view]
    public fun get_vault_manager(vault_addr: address): address acquires VaultStorage {
        if (!exists<VaultStorage>(vault_addr)) {
            return @0x0
        };
        
        let vault_storage = borrow_global<VaultStorage>(vault_addr);
        vault_storage.vault_manager
    }

    // Get asset pool info
    #[view]
    public fun get_asset_pool_info(vault_addr: address): (u64, u64, u64, u64) acquires AssetPool {
        if (!exists<AssetPool>(vault_addr)) {
            return (0, 0, 0, 0)
        };
        
        let asset_pool = borrow_global<AssetPool>(vault_addr);
        (asset_pool.usdt_balance, asset_pool.apt_balance, asset_pool.total_value, asset_pool.last_update)
    }
} 