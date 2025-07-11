module vault::vault_integration {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;

    // Import vault modules
    use vault::vault;
    use vault::pancakeswap_adapter;

    // Integration configuration
    const MIN_REBALANCE_THRESHOLD: u64 = 1000000; // 1 USDT
    const MAX_SLIPPAGE: u64 = 500; // 5% in basis points
    const REBALANCE_COOLDOWN: u64 = 3600; // 1 hour in seconds

    // Integration storage
    struct IntegrationStorage has key {
        vault_address: address,
        router_address: address,
        owner: address,
        is_active: bool,
        last_rebalance: u64,
        total_swaps: u64,
        total_volume: u64,
    }

    // Trading strategy
    struct TradingStrategy has drop, store {
        target_usdt_ratio: u64, // in basis points
        rebalance_threshold: u64, // in basis points
        max_slippage: u64, // in basis points
        min_trade_size: u64, // minimum trade size in USDT
    }

    // Trade execution result
    struct TradeResult has drop, store {
        input_token: address,
        output_token: address,
        input_amount: u64,
        output_amount: u64,
        slippage: u64,
        timestamp: u64,
    }

    // Integration events
    struct IntegrationEvent has drop, store {
        event_type: vector<u8>,
        vault_address: address,
        amount: u64,
        timestamp: u64,
    }

    // Error codes
    const EINTEGRATION_NOT_ACTIVE: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EEXCESSIVE_SLIPPAGE: u64 = 3;
    const EREBALANCE_COOLDOWN: u64 = 4;
    const EINVALID_STRATEGY: u64 = 5;

    // Initialize integration
    public entry fun initialize_integration(
        owner: &signer,
        vault_address: address,
    ) {
        let owner_addr = signer::address_of(owner);
        
        move_to(owner, IntegrationStorage {
            vault_address: vault_address,
            router_address: pancakeswap_adapter::get_pancakeswap_router(),
            owner: owner_addr,
            is_active: true,
            last_rebalance: 0,
            total_swaps: 0,
            total_volume: 0,
        });
    }

    // Execute automated rebalancing
    public entry fun execute_rebalancing(
        manager: &signer,
    ) acquires IntegrationStorage {
        let manager_addr = signer::address_of(manager);
        
        if (!exists<IntegrationStorage>(manager_addr)) {
            return
        };

        let integration = borrow_global_mut<IntegrationStorage>(manager_addr);
        
        if (!integration.is_active) {
            return
        };

        // Check cooldown
        if (timestamp::now_seconds() - integration.last_rebalance < REBALANCE_COOLDOWN) {
            return
        };

        // Get vault status
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        
        if (!is_active) {
            return
        };

        // Calculate current ratio
        let total_value = total_usdt + total_apt;
        let current_usdt_ratio = if (total_value > 0) {
            (total_usdt * 10000) / total_value
        } else {
            0
        };

        // Target ratio: 50% USDT, 50% APT
        let target_usdt_ratio = 5000; // 50% in basis points
        let threshold = 1000; // 10% deviation

        // Check if rebalancing is needed
        if (current_usdt_ratio > target_usdt_ratio + threshold || current_usdt_ratio < target_usdt_ratio - threshold) {
            let trade_amount = if (current_usdt_ratio > target_usdt_ratio) {
                // Too much USDT, swap USDT for APT
                let excess_usdt = (total_usdt - (total_value * target_usdt_ratio / 10000)) / 2;
                if (excess_usdt > MIN_REBALANCE_THRESHOLD) {
                    excess_usdt
                } else {
                    0
                }
            } else {
                // Too much APT, swap APT for USDT
                let excess_apt = (total_apt - (total_value * (10000 - target_usdt_ratio) / 10000)) / 2;
                if (excess_apt > MIN_REBALANCE_THRESHOLD) {
                    excess_apt
                } else {
                    0
                }
            };

            if (trade_amount > 0) {
                // Execute trade
                if (current_usdt_ratio > target_usdt_ratio) {
                    // Swap USDT for APT
                    execute_swap_usdt_for_apt(manager, trade_amount);
                } else {
                    // Swap APT for USDT
                    execute_swap_apt_for_usdt(manager, trade_amount);
                };

                integration.last_rebalance = timestamp::now_seconds();
                integration.total_swaps = integration.total_swaps + 1;
                integration.total_volume = integration.total_volume + trade_amount;
            };
        };
    }

    // Execute USDT to APT swap
    fun execute_swap_usdt_for_apt(
        manager: &signer,
        usdt_amount: u64,
    ) {
        // Get quote from PancakeSwap
        let expected_apt = pancakeswap_adapter::get_quote(
            vault::get_usdt_address(),
            vault::get_apt_address(),
            usdt_amount
        );

        // Calculate minimum output with slippage protection
        let min_output = expected_apt - (expected_apt * MAX_SLIPPAGE / 10000);

        // Execute swap
        let path = vector::empty<address>();
        vector::push_back(&mut path, vault::get_usdt_address());
        vector::push_back(&mut path, vault::get_apt_address());

        pancakeswap_adapter::swap_exact_tokens_for_tokens(
            manager,
            usdt_amount,
            min_output,
            path,
            timestamp::now_seconds() + 3600
        );
    }

    // Execute APT to USDT swap
    fun execute_swap_apt_for_usdt(
        manager: &signer,
        apt_amount: u64,
    ) {
        // Get quote from PancakeSwap
        let expected_usdt = pancakeswap_adapter::get_quote(
            vault::get_apt_address(),
            vault::get_usdt_address(),
            apt_amount
        );

        // Calculate minimum output with slippage protection
        let min_output = expected_usdt - (expected_usdt * MAX_SLIPPAGE / 10000);

        // Execute swap
        let path = vector::empty<address>();
        vector::push_back(&mut path, vault::get_apt_address());
        vector::push_back(&mut path, vault::get_usdt_address());

        pancakeswap_adapter::swap_exact_tokens_for_tokens(
            manager,
            apt_amount,
            min_output,
            path,
            timestamp::now_seconds() + 3600
        );
    }

    // Manual rebalancing with custom amount
    public entry fun manual_rebalance(
        manager: &signer,
        usdt_amount: u64,
        direction: u64, // 0: USDT->APT, 1: APT->USDT
    ) acquires IntegrationStorage {
        let manager_addr = signer::address_of(manager);
        
        if (!exists<IntegrationStorage>(manager_addr)) {
            return
        };

        let integration = borrow_global_mut<IntegrationStorage>(manager_addr);
        
        if (!integration.is_active) {
            return
        };

        if (usdt_amount == 0) {
            return
        };

        if (direction == 0) {
            // Swap USDT for APT
            execute_swap_usdt_for_apt(manager, usdt_amount);
        } else if (direction == 1) {
            // Swap APT for USDT
            execute_swap_apt_for_usdt(manager, usdt_amount);
        };

        integration.total_swaps = integration.total_swaps + 1;
        integration.total_volume = integration.total_volume + usdt_amount;
    }

    // Get integration status
    #[view]
    public fun get_integration_status(manager_addr: address): (address, address, bool, u64, u64, u64) acquires IntegrationStorage {
        if (!exists<IntegrationStorage>(manager_addr)) {
            return (@0x0, @0x0, false, 0, 0, 0)
        };
        
        let integration = borrow_global<IntegrationStorage>(manager_addr);
        (integration.vault_address, integration.router_address, integration.is_active, integration.last_rebalance, integration.total_swaps, integration.total_volume)
    }

    // Set integration active status
    public entry fun set_integration_active(
        manager: &signer,
        is_active: bool,
    ) acquires IntegrationStorage {
        let manager_addr = signer::address_of(manager);
        
        if (!exists<IntegrationStorage>(manager_addr)) {
            return
        };
        
        let integration = borrow_global_mut<IntegrationStorage>(manager_addr);
        
        if (integration.owner != manager_addr) {
            return
        };
        
        integration.is_active = is_active;
    }

    // Get optimal rebalancing amount
    #[view]
    public fun get_rebalancing_amount(): (u64, u64) {
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        
        if (!is_active) {
            return (0, 0)
        };

        let total_value = total_usdt + total_apt;
        let current_usdt_ratio = if (total_value > 0) {
            (total_usdt * 10000) / total_value
        } else {
            0
        };

        let target_usdt_ratio = 5000; // 50% in basis points
        let threshold = 1000; // 10% deviation

        if (current_usdt_ratio > target_usdt_ratio + threshold) {
            // Too much USDT, need to swap USDT for APT
            let excess_usdt = (total_usdt - (total_value * target_usdt_ratio / 10000)) / 2;
            (excess_usdt, 0) // USDT amount, direction (0 = USDT->APT)
        } else if (current_usdt_ratio < target_usdt_ratio - threshold) {
            // Too much APT, need to swap APT for USDT
            let excess_apt = (total_apt - (total_value * (10000 - target_usdt_ratio) / 10000)) / 2;
            (excess_apt, 1) // APT amount, direction (1 = APT->USDT)
        } else {
            (0, 0) // No rebalancing needed
        }
    }

    // Get quote for swap
    #[view]
    public fun get_swap_quote(
        input_token: address,
        output_token: address,
        amount_in: u64,
    ): u64 {
        pancakeswap_adapter::get_quote(input_token, output_token, amount_in)
    }

    // Get vault performance metrics
    #[view]
    public fun get_vault_performance(): (u64, u64, u64, u64) {
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        let total_value = total_usdt + total_apt;
        let usdt_ratio = if (total_value > 0) {
            (total_usdt * 10000) / total_value
        } else {
            0
        };
        
        (total_value, usdt_ratio, total_shares, fee_rate)
    }
} 