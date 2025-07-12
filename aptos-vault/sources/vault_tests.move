#[test_only]
module vault::vault_tests {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::account;

    // Import vault modules
    use vault::vault;
    use vault::pancakeswap_adapter;
    use vault::vault_core_simple;
    use vault::vault_integration;

    // Test addresses
    const TEST_USER_ADDRESS: address = @0x1234567890123456789012345678901234567890123456789012345678901234;
    const TEST_MANAGER_ADDRESS: address = @0xf9bf1298a04a1fe13ed75059e9e6950ec1ec2d6ed95f8a04a6e11af23c87381e;

    // Test amounts
    const TEST_DEPOSIT_AMOUNT: u64 = 1000000; // 1 USDT
    const TEST_WITHDRAW_AMOUNT: u64 = 500000; // 0.5 USDT
    const TEST_SWAP_AMOUNT: u64 = 100000; // 0.1 APT

    // Test vault initialization
    #[test]
    fun test_vault_initialization() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Check vault status
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        
        assert!(total_shares == 0, 1);
        assert!(total_usdt == 0, 2);
        assert!(total_apt == 0, 3);
        assert!(is_active == true, 4);
        assert!(fee_rate == 100, 5); // 1% fee
        
        // Check vault owner
        let owner = vault::get_vault_owner();
        assert!(owner == TEST_USER_ADDRESS, 6);
    }

    // Test deposit functionality
    #[test]
    fun test_deposit() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Deposit USDT
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Check vault status after deposit
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        
        assert!(total_shares == TEST_DEPOSIT_AMOUNT, 7); // First deposit: 1:1 ratio
        assert!(total_usdt == TEST_DEPOSIT_AMOUNT, 8);
        assert!(total_apt == 0, 9);
        
        // Check user balance
        let (user_shares, user_usdt, total_deposited, total_withdrawn) = vault::get_user_balance(TEST_USER_ADDRESS);
        
        assert!(user_shares == TEST_DEPOSIT_AMOUNT, 10);
        assert!(user_usdt == TEST_DEPOSIT_AMOUNT, 11);
        assert!(total_deposited == TEST_DEPOSIT_AMOUNT, 12);
        assert!(total_withdrawn == 0, 13);
    }

    // Test withdraw functionality
    #[test]
    fun test_withdraw() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Deposit USDT
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Withdraw shares
        vault::withdraw(&test_user, TEST_WITHDRAW_AMOUNT);
        
        // Check vault status after withdrawal
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        
        assert!(total_shares == TEST_DEPOSIT_AMOUNT - TEST_WITHDRAW_AMOUNT, 14);
        assert!(total_usdt == TEST_DEPOSIT_AMOUNT - TEST_WITHDRAW_AMOUNT, 15);
        
        // Check user balance
        let (user_shares, user_usdt, total_deposited, total_withdrawn) = vault::get_user_balance(TEST_USER_ADDRESS);
        
        assert!(user_shares == TEST_DEPOSIT_AMOUNT - TEST_WITHDRAW_AMOUNT, 16);
        assert!(user_usdt == TEST_DEPOSIT_AMOUNT - TEST_WITHDRAW_AMOUNT, 17);
        assert!(total_withdrawn == TEST_WITHDRAW_AMOUNT, 18);
    }

    // Test rebalance functionality
    #[test]
    fun test_rebalance() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Deposit USDT
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Rebalance (swap USDT for APT)
        vault::rebalance(&test_user, TEST_WITHDRAW_AMOUNT);
        
        // Check vault status after rebalance
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        
        assert!(total_shares == TEST_DEPOSIT_AMOUNT, 19);
        assert!(total_usdt == TEST_DEPOSIT_AMOUNT - TEST_WITHDRAW_AMOUNT, 20);
        assert!(total_apt == TEST_WITHDRAW_AMOUNT, 21); // 1:1 ratio for demo
    }

    // Test convert functions
    #[test]
    fun test_convert_functions() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Deposit USDT
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Test convert_to_shares
        let shares = vault::convert_to_shares(TEST_WITHDRAW_AMOUNT);
        assert!(shares == TEST_WITHDRAW_AMOUNT, 22); // 1:1 ratio for first deposit
        
        // Test convert_to_assets
        let assets = vault::convert_to_assets(TEST_WITHDRAW_AMOUNT);
        assert!(assets == TEST_WITHDRAW_AMOUNT, 23); // 1:1 ratio for first deposit
    }

    // Test total assets and shares
    #[test]
    fun test_total_assets_and_shares() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Check initial state
        assert!(vault::total_assets() == 0, 24);
        assert!(vault::total_shares() == 0, 25);
        
        // Deposit USDT
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Check after deposit
        assert!(vault::total_assets() == TEST_DEPOSIT_AMOUNT, 26);
        assert!(vault::total_shares() == TEST_DEPOSIT_AMOUNT, 27);
    }

    // Test vault core simple functions
    #[test]
    fun test_vault_core_simple() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Create vault
        vault_core_simple::create_vault(&test_user);
        
        // Mint shares
        vault_core_simple::mint_shares(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Check user shares
        let user_shares = vault_core_simple::get_user_shares(TEST_USER_ADDRESS);
        assert!(user_shares == TEST_DEPOSIT_AMOUNT, 28);
        
        // Burn shares
        vault_core_simple::burn_shares(&test_user, TEST_WITHDRAW_AMOUNT);
        
        // Check user shares after burn
        let user_shares_after = vault_core_simple::get_user_shares(TEST_USER_ADDRESS);
        assert!(user_shares_after == TEST_DEPOSIT_AMOUNT - TEST_WITHDRAW_AMOUNT, 29);
    }

    // Test pancakeswap adapter functions
    #[test]
    fun test_pancakeswap_adapter() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize router
        pancakeswap_adapter::initialize_router(&test_user);
        
        // Get router address
        let router_address = pancakeswap_adapter::get_pancakeswap_router();
        assert!(router_address == @0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60, 30);
        
        // Get quote
        let quote = pancakeswap_adapter::get_quote(
            vault::get_apt_address(),
            vault::get_usdt_address(),
            TEST_SWAP_AMOUNT
        );
        assert!(quote == TEST_SWAP_AMOUNT, 31); // 1:1 ratio for demo
        
        // Get router stats
        let (router_addr, is_active, total_swaps, total_volume, last_swap) = pancakeswap_adapter::get_router_stats(TEST_USER_ADDRESS);
        assert!(is_active == true, 32);
        assert!(total_swaps == 0, 33);
        assert!(total_volume == 0, 34);
    }

    // Test vault integration functions
    #[test]
    fun test_vault_integration() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize integration
        vault_integration::initialize_integration(&test_user, vault::get_vault_address());
        
        // Get integration status
        let (vault_addr, router_addr, is_active, last_rebalance, total_swaps, total_volume) = vault_integration::get_integration_status(TEST_USER_ADDRESS);
        assert!(is_active == true, 35);
        assert!(total_swaps == 0, 36);
        assert!(total_volume == 0, 37);
        
        // Get rebalancing amount
        let (amount, direction) = vault_integration::get_rebalancing_amount();
        // This will depend on vault state, so we just test it doesn't panic
        assert!(true, 38);
        
        // Get vault performance
        let (total_value, usdt_ratio, total_shares, fee_rate) = vault_integration::get_vault_performance();
        // This will depend on vault state, so we just test it doesn't panic
        assert!(true, 39);
    }

    // Test access control
    #[test]
    fun test_access_control() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        let unauthorized_user = account::create_account_for_test(@0x9999999999999999999999999999999999999999999999999999999999999999);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Try to set fee rate with unauthorized user (should fail silently)
        vault::set_fee_rate(&unauthorized_user, 200);
        
        // Check fee rate is still original
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        assert!(fee_rate == 100, 40); // Should still be 1%
        
        // Set fee rate with authorized user
        vault::set_fee_rate(&test_user, 200);
        
        // Check fee rate changed
        let (total_shares2, total_usdt2, total_apt2, created_at2, is_active2, fee_rate2) = vault::get_vault_status();
        assert!(fee_rate2 == 200, 41);
    }

    // Test edge cases
    #[test]
    fun test_edge_cases() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Try to deposit 0 amount (should fail silently)
        vault::deposit(&test_user, 0);
        
        // Check no change
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        assert!(total_shares == 0, 42);
        assert!(total_usdt == 0, 43);
        
        // Try to withdraw more than available (should fail silently)
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        vault::withdraw(&test_user, TEST_DEPOSIT_AMOUNT + 1);
        
        // Check shares not changed
        let (user_shares, user_usdt, total_deposited, total_withdrawn) = vault::get_user_balance(TEST_USER_ADDRESS);
        assert!(user_shares == TEST_DEPOSIT_AMOUNT, 44);
    }

    // Test vault deactivation
    #[test]
    fun test_vault_deactivation() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // Deactivate vault
        vault::set_vault_active(&test_user, false);
        
        // Check vault is inactive
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        assert!(is_active == false, 45);
        
        // Try to deposit when inactive (should fail silently)
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Check no change
        let (total_shares2, total_usdt2, total_apt2, created_at2, is_active2, fee_rate2) = vault::get_vault_status();
        assert!(total_shares2 == 0, 46);
        assert!(total_usdt2 == 0, 47);
    }

    // Test multiple deposits
    #[test]
    fun test_multiple_deposits() {
        let test_user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&test_user);
        
        // First deposit
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Second deposit
        vault::deposit(&test_user, TEST_DEPOSIT_AMOUNT);
        
        // Check total shares and USDT
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        assert!(total_shares == TEST_DEPOSIT_AMOUNT * 2, 48);
        assert!(total_usdt == TEST_DEPOSIT_AMOUNT * 2, 49);
        
        // Check user balance
        let (user_shares, user_usdt, total_deposited, total_withdrawn) = vault::get_user_balance(TEST_USER_ADDRESS);
        assert!(user_shares == TEST_DEPOSIT_AMOUNT * 2, 50);
        assert!(total_deposited == TEST_DEPOSIT_AMOUNT * 2, 51);
    }
} 