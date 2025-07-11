module vault::vault_core_simple {
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::account;

    // USDT address on Aptos Mainnet
    const USDT_ADDRESS: address = 0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa;

    // Vault storage for managing USDT balances
    struct VaultStorage has key {
        total_deposits: u64,
        total_shares: u64,
        vault_manager: address,
    }

    // Vault shares for tracking user ownership
    struct VaultShares has key {
        shares: u64,
    }

    // Vault manager capability
    struct VaultManagerCap has key {
        vault_id: u64,
    }

    // Error codes
    const EINSUFFICIENT_BALANCE: u64 = 1;
    const EINSUFFICIENT_SHARES: u64 = 2;
    const EZERO_AMOUNT: u64 = 3;
    const EVAULT_NOT_FOUND: u64 = 4;
    const EACCESS_DENIED: u64 = 5;

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
            total_deposits: 0,
            total_shares: 0,
            vault_manager: vault_manager_addr,
        });

        // Create vault manager capability
        move_to(vault_manager, VaultManagerCap {
            vault_id: 0,
        });
    }

    // Deposit USDT into vault
    public entry fun deposit(
        user: &signer,
        amount: u64,
    ) acquires VaultStorage, VaultShares {
        let user_addr = signer::address_of(user);
        
        if (amount == 0) {
            return
        };

        // Get user's USDT balance
        let user_coins = coin::withdraw<coin::USDT>(user, amount);
        
        // Calculate shares to mint (simple 1:1 ratio)
        let shares_to_mint = amount;
        
        // Update vault storage
        let vault_storage = borrow_global_mut<VaultStorage>(user_addr);
        vault_storage.total_deposits = vault_storage.total_deposits + amount;
        vault_storage.total_shares = vault_storage.total_shares + shares_to_mint;
        
        // Mint shares for user
        if (!exists<VaultShares>(user_addr)) {
            move_to(user, VaultShares {
                shares: shares_to_mint,
            });
        } else {
            let user_shares = borrow_global_mut<VaultShares>(user_addr);
            user_shares.shares = user_shares.shares + shares_to_mint;
        };

        // Return coins to user (in a real implementation, these would be held by the vault)
        coin::deposit(user_addr, user_coins);
    }

    // Withdraw USDT from vault
    public entry fun withdraw(
        user: &signer,
        shares_to_burn: u64,
    ) acquires VaultStorage, VaultShares {
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

        // Calculate amount to withdraw (simple 1:1 ratio)
        let amount_to_withdraw = shares_to_burn;
        
        // Update vault storage
        let vault_storage = borrow_global_mut<VaultStorage>(user_addr);
        vault_storage.total_deposits = vault_storage.total_deposits - amount_to_withdraw;
        vault_storage.total_shares = vault_storage.total_shares - shares_to_burn;
        
        // Burn shares
        user_shares.shares = user_shares.shares - shares_to_burn;
        
        // Transfer USDT to user
        let coins_to_transfer = coin::withdraw<coin::USDT>(user, 0);
        coin::deposit(user_addr, coins_to_transfer);
    }

    // Get user's share balance
    public fun get_balance(user_addr: address): u64 {
        if (exists<VaultShares>(user_addr)) {
            let user_shares = borrow_global<VaultShares>(user_addr);
            user_shares.shares
        } else {
            0
        }
    }

    // Get vault info
    public fun get_vault_info(vault_addr: address): (u64, u64) {
        if (exists<VaultStorage>(vault_addr)) {
            let vault_storage = borrow_global<VaultStorage>(vault_addr);
            (vault_storage.total_deposits, vault_storage.total_shares)
        } else {
            (0, 0)
        }
    }

    // Get USDT address
    public fun get_usdt_address(): address {
        USDT_ADDRESS
    }
} 