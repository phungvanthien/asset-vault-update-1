#[test_only]
module vault::vault_tests {
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::account;

    // Import modules to test
    use vault::vault;
    use vault::pancakeswap_adapter;
    use vault::vault_core_simple;
    use vault::vault_integration;

    // Test addresses
    const TEST_VAULT_ADDRESS: address = @0x2fdd1d8c08c6d2e447cffd67419cd9f0d53bedd003e5a6ee427b649f0c1077ef;
    const TEST_USER_ADDRESS: address = @0x1234567890123456789012345678901234567890123456789012345678901234;
    const TEST_MANAGER_ADDRESS: address = @0x2345678901234567890123456789012345678901234567890123456789012345;

    // Test constants
    const TEST_DEPOSIT_AMOUNT: u64 = 1000000; // 1 USDT
    const TEST_WITHDRAW_AMOUNT: u64 = 500000; // 0.5 USDT
    const TEST_SWAP_AMOUNT: u64 = 100000; // 0.1 USDT

    #[test]
    fun test_vault_initialization() {
        let owner = account::create_account_for_test(@vault);
        
        // Test vault initialization
        vault::initialize_vault(&owner);
        
        // Verify vault status
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        assert!(total_shares == vault::get_initial_shares(), 1);
        assert!(total_usdt == 0, 2);
        assert!(total_apt == 0, 3);
        assert!(is_active == true, 4);
        assert!(fee_rate == 100, 5);
    }

    #[test]
    fun test_deposit_function() {
        let owner = account::create_account_for_test(@vault);
        let user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&owner);
        
        // Test deposit
        vault::deposit(&user, TEST_DEPOSIT_AMOUNT);
        
        // Verify user balance
        let (shares, usdt_balance, total_deposited, total_withdrawn) = vault::get_user_balance(TEST_USER_ADDRESS);
        assert!(shares > 0, 6);
        assert!(total_deposited == TEST_DEPOSIT_AMOUNT, 7);
        assert!(total_withdrawn == 0, 8);
    }

    #[test]
    fun test_withdraw_function() {
        let owner = account::create_account_for_test(@vault);
        let user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&owner);
        
        // Deposit first
        vault::deposit(&user, TEST_DEPOSIT_AMOUNT);
        
        // Test withdraw
        vault::withdraw(&user, TEST_WITHDRAW_AMOUNT);
        
        // Verify user balance
        let (shares, usdt_balance, total_deposited, total_withdrawn) = vault::get_user_balance(TEST_USER_ADDRESS);
        assert!(shares > 0, 9);
        assert!(total_withdrawn > 0, 10);
    }

    #[test]
    fun test_redeem_function() {
        let owner = account::create_account_for_test(@vault);
        let user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Initialize vault
        vault::initialize_vault(&owner);
        
        // Deposit first
        vault::deposit(&user, TEST_DEPOSIT_AMOUNT);
        
        // Test redeem (should be same as withdraw)
        vault::redeem(&user, TEST_WITHDRAW_AMOUNT);
        
        // Verify user balance
        let (shares, usdt_balance, total_deposited, total_withdrawn) = vault::get_user_balance(TEST_USER_ADDRESS);
        assert!(shares > 0, 11);
        assert!(total_withdrawn > 0, 12);
    }

    #[test]
    fun test_convert_functions() {
        let owner = account::create_account_for_test(@vault);
        
        // Initialize vault
        vault::initialize_vault(&owner);
        
        // Test convert_to_shares
        let shares = vault::convert_to_shares(TEST_DEPOSIT_AMOUNT);
        assert!(shares > 0, 13);
        
        // Test convert_to_assets
        let assets = vault::convert_to_assets(shares);
        assert!(assets > 0, 14);
    }

    #[test]
    fun test_total_assets_and_shares() {
        let owner = account::create_account_for_test(@vault);
        
        // Initialize vault
        vault::initialize_vault(&owner);
        
        // Test total_assets
        let total_assets = vault::total_assets();
        assert!(total_assets >= 0, 15);
        
        // Test total_shares
        let total_shares = vault::total_shares();
        assert!(total_shares == vault::get_initial_shares(), 16);
    }

    #[test]
    fun test_rebalance_function() {
        let owner = account::create_account_for_test(@vault);
        
        // Initialize vault
        vault::initialize_vault(&owner);
        
        // Test rebalance
        vault::rebalance(&owner, TEST_SWAP_AMOUNT);
        
        // Verify vault status
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        assert!(total_apt > 0, 17);
    }

    #[test]
    fun test_pancakeswap_adapter() {
        let user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Test router creation
        pancakeswap_adapter::create_router(&user);
        
        // Test get_quote
        let quote = pancakeswap_adapter::get_quote(
            vault::get_usdt_address(),
            vault::get_apt_address(),
            TEST_SWAP_AMOUNT
        );
        assert!(quote > 0, 18);
        
        // Test get_amounts_out
        let path = vector::empty<address>();
        vector::push_back(&mut path, vault::get_usdt_address());
        vector::push_back(&mut path, vault::get_apt_address());
        
        let amounts = pancakeswap_adapter::get_amounts_out(TEST_SWAP_AMOUNT, path);
        assert!(vector::length(&amounts) == 2, 19);
    }

    #[test]
    fun test_vault_core_simple() {
        let manager = account::create_account_for_test(TEST_MANAGER_ADDRESS);
        
        // Test vault creation
        vault_core_simple::create_vault(&manager);
        
        // Test mint shares
        vault_core_simple::mint_shares(&manager, TEST_DEPOSIT_AMOUNT);
        
        // Test get vault info
        let (total_shares, usdt_balance, apt_balance, is_active, fee_rate) = vault_core_simple::get_vault_info(TEST_MANAGER_ADDRESS);
        assert!(total_shares > 0, 20);
        assert!(usdt_balance > 0, 21);
        assert!(is_active == true, 22);
        
        // Test get balance
        let balance = vault_core_simple::get_balance(TEST_MANAGER_ADDRESS);
        assert!(balance > 0, 23);
    }

    #[test]
    fun test_vault_integration() {
        let manager = account::create_account_for_test(TEST_MANAGER_ADDRESS);
        
        // Initialize integration
        vault_integration::initialize_integration(&manager, TEST_VAULT_ADDRESS);
        
        // Test get integration status
        let (vault_addr, router_addr, is_active, last_rebalance, total_swaps, total_volume) = vault_integration::get_integration_status(TEST_MANAGER_ADDRESS);
        assert!(vault_addr == TEST_VAULT_ADDRESS, 24);
        assert!(is_active == true, 25);
        assert!(total_swaps == 0, 26);
        assert!(total_volume == 0, 27);
        
        // Test get rebalancing amount
        let (amount, direction) = vault_integration::get_rebalancing_amount();
        assert!(amount >= 0, 28);
        assert!(direction >= 0, 29);
        
        // Test get vault performance
        let (total_value, usdt_ratio, total_shares, fee_rate) = vault_integration::get_vault_performance();
        assert!(total_value >= 0, 30);
        assert!(usdt_ratio >= 0, 31);
        assert!(total_shares >= 0, 32);
        assert!(fee_rate >= 0, 33);
    }

    #[test]
    fun test_swap_functions() {
        let user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Test swap USDT for APT
        pancakeswap_adapter::swap_usdt_for_apt(&user, TEST_SWAP_AMOUNT);
        
        // Test swap APT for USDT
        pancakeswap_adapter::swap_apt_for_usdt(&user, TEST_SWAP_AMOUNT);
        
        // Test vault swap
        let path = vector::empty<address>();
        vector::push_back(&mut path, vault::get_usdt_address());
        vector::push_back(&mut path, vault::get_apt_address());
        
        pancakeswap_adapter::vault_swap(&user, TEST_SWAP_AMOUNT, 0, path, timestamp::now_seconds() + 3600);
    }

    #[test]
    fun test_fee_management() {
        let owner = account::create_account_for_test(@vault);
        
        // Initialize vault
        vault::initialize_vault(&owner);
        
        // Test set fee rate
        vault::set_fee_rate(&owner, 200); // 2%
        
        // Verify fee rate
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        assert!(fee_rate == 200, 34);
    }

    #[test]
    fun test_vault_active_status() {
        let owner = account::create_account_for_test(@vault);
        
        // Initialize vault
        vault::initialize_vault(&owner);
        
        // Test set vault active
        vault::set_vault_active(&owner, false);
        
        // Verify active status
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        assert!(is_active == false, 35);
    }

    #[test]
    fun test_router_management() {
        let user = account::create_account_for_test(TEST_USER_ADDRESS);
        
        // Create router
        pancakeswap_adapter::create_router(&user);
        
        // Test set router active
        pancakeswap_adapter::set_router_active(&user, false);
        
        // Test get router info
        let (router_addr, is_active) = pancakeswap_adapter::get_router_info();
        assert!(router_addr == pancakeswap_adapter::get_pancakeswap_router(), 36);
    }

    #[test]
    fun test_integration_management() {
        let manager = account::create_account_for_test(TEST_MANAGER_ADDRESS);
        
        // Initialize integration
        vault_integration::initialize_integration(&manager, TEST_VAULT_ADDRESS);
        
        // Test set integration active
        vault_integration::set_integration_active(&manager, false);
        
        // Verify integration status
        let (vault_addr, router_addr, is_active, last_rebalance, total_swaps, total_volume) = vault_integration::get_integration_status(TEST_MANAGER_ADDRESS);
        assert!(is_active == false, 37);
    }

    #[test]
    fun test_manual_rebalancing() {
        let manager = account::create_account_for_test(TEST_MANAGER_ADDRESS);
        
        // Initialize integration
        vault_integration::initialize_integration(&manager, TEST_VAULT_ADDRESS);
        
        // Test manual rebalance USDT->APT
        vault_integration::manual_rebalance(&manager, TEST_SWAP_AMOUNT, 0);
        
        // Test manual rebalance APT->USDT
        vault_integration::manual_rebalance(&manager, TEST_SWAP_AMOUNT, 1);
        
        // Verify integration status
        let (vault_addr, router_addr, is_active, last_rebalance, total_swaps, total_volume) = vault_integration::get_integration_status(TEST_MANAGER_ADDRESS);
        assert!(total_swaps > 0, 38);
        assert!(total_volume > 0, 39);
    }

    #[test]
    fun test_quote_functions() {
        // Test get swap quote
        let quote = vault_integration::get_swap_quote(
            vault::get_usdt_address(),
            vault::get_apt_address(),
            TEST_SWAP_AMOUNT
        );
        assert!(quote > 0, 40);
        
        // Test get quote with path
        let path = vector::empty<address>();
        vector::push_back(&mut path, vault::get_usdt_address());
        vector::push_back(&mut path, vault::get_apt_address());
        
        let quote_with_path = pancakeswap_adapter::get_quote_with_path(TEST_SWAP_AMOUNT, path);
        assert!(quote_with_path > 0, 41);
    }

    #[test]
    fun test_asset_pool_management() {
        let manager = account::create_account_for_test(TEST_MANAGER_ADDRESS);
        
        // Create vault
        vault_core_simple::create_vault(&manager);
        
        // Test get asset pool info
        let (usdt_balance, apt_balance, total_value, last_update) = vault_core_simple::get_asset_pool_info(TEST_MANAGER_ADDRESS);
        assert!(usdt_balance >= 0, 42);
        assert!(apt_balance >= 0, 43);
        assert!(total_value >= 0, 44);
        assert!(last_update > 0, 45);
    }

    #[test]
    fun test_vault_manager_functions() {
        let manager = account::create_account_for_test(TEST_MANAGER_ADDRESS);
        
        // Create vault
        vault_core_simple::create_vault(&manager);
        
        // Test get vault manager
        let manager_addr = vault_core_simple::get_vault_manager(TEST_MANAGER_ADDRESS);
        assert!(manager_addr == TEST_MANAGER_ADDRESS, 46);
        
        // Test set fee rate
        vault_core_simple::set_fee_rate(&manager, 150); // 1.5%
        
        // Test set vault active
        vault_core_simple::set_vault_active(&manager, false);
        
        // Verify changes
        let (total_shares, usdt_balance, apt_balance, is_active, fee_rate) = vault_core_simple::get_vault_info(TEST_MANAGER_ADDRESS);
        assert!(fee_rate == 150, 47);
        assert!(is_active == false, 48);
    }
} 