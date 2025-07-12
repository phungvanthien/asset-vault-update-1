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
    const TARGET_USDT_RATIO: u64 = 5000; // 50% in basis points
    const REBALANCE_THRESHOLD: u64 = 1000; // 10% deviation

    // Integration storage
    struct IntegrationStorage has key {
        vault_address: address,
        router_address: address,
        owner: address,
        is_active: bool,
        last_rebalance: u64,
        total_swaps: u64,
        total_volume: u64,
        manager_address: address,
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

    // Rebalance event
    struct RebalanceEvent has drop, store {
        usdt_amount: u64,
        apt_amount: u64,
        timestamp: u64,
        target_ratio: u64,
        current_ratio: u64,
        slippage: u64,
    }

    // Error codes
    const EINTEGRATION_NOT_ACTIVE: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EEXCESSIVE_SLIPPAGE: u64 = 3;
    const EREBALANCE_COOLDOWN: u64 = 4;
    const EINVALID_STRATEGY: u64 = 5;
    const EACCESS_DENIED: u64 = 6;
    const EINVALID_AMOUNT: u64 = 7;

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
            manager_address: owner_addr,
        });
    }

    // Execute automated rebalancing with proper checks
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
        let current_time = timestamp::now_seconds();
        if (current_time - integration.last_rebalance < REBALANCE_COOLDOWN) {
            return
        };

        // Get vault status
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        
        if (!is_active) {
            return
        };

        // Calculate current ratio with proper arithmetic
        let total_value = total_usdt + total_apt;
        let current_usdt_ratio = if (total_value > 0) {
            (total_usdt * 10000) / total_value
        } else {
            0
        };

        // Check if rebalancing is needed
        if (current_usdt_ratio > TARGET_USDT_RATIO + REBALANCE_THRESHOLD || 
            current_usdt_ratio < TARGET_USDT_RATIO - REBALANCE_THRESHOLD) {
            
            let trade_amount = if (current_usdt_ratio > TARGET_USDT_RATIO) {
                // Too much USDT, swap USDT for APT
                let excess_usdt = (total_usdt - (total_value * TARGET_USDT_RATIO / 10000)) / 2;
                if (excess_usdt > MIN_REBALANCE_THRESHOLD) {
                    excess_usdt
                } else {
                    0
                }
            } else {
                // Too much APT, swap APT for USDT
                let excess_apt = (total_apt - (total_value * (10000 - TARGET_USDT_RATIO) / 10000)) / 2;
                if (excess_apt > MIN_REBALANCE_THRESHOLD) {
                    excess_apt
                } else {
                    0
                }
            };

            if (trade_amount > 0) {
                // Execute trade with proper timestamp
                let trade_timestamp = timestamp::now_seconds();
                
                if (current_usdt_ratio > TARGET_USDT_RATIO) {
                    // Swap USDT for APT
                    execute_swap_usdt_for_apt(manager, trade_amount, trade_timestamp);
                } else {
                    // Swap APT for USDT
                    execute_swap_apt_for_usdt(manager, trade_amount, trade_timestamp);
                };

                integration.last_rebalance = trade_timestamp;
                integration.total_swaps = integration.total_swaps + 1;
                integration.total_volume = integration.total_volume + trade_amount;

                // Emit rebalance event
                let rebalance_event = RebalanceEvent {
                    usdt_amount: total_usdt,
                    apt_amount: total_apt,
                    timestamp: trade_timestamp,
                    target_ratio: TARGET_USDT_RATIO,
                    current_ratio: current_usdt_ratio,
                    slippage: 0, // Will be calculated from actual swap
                };

                // In a real implementation, you would emit this event
                // event::emit(rebalance_event_handle, rebalance_event);
            };
        };
    }

    // Execute USDT to APT swap with slippage protection
    fun execute_swap_usdt_for_apt(
        manager: &signer,
        usdt_amount: u64,
        trade_timestamp: u64,
    ) {
        // Get quote from PancakeSwap
        let expected_apt = pancakeswap_adapter::get_quote(
            vault::get_usdt_address(),
            vault::get_apt_address(),
            usdt_amount
        );

        // Calculate minimum output with slippage protection
        let min_output = if (expected_apt > 0) {
            expected_apt - (expected_apt * MAX_SLIPPAGE / 10000)
        } else {
            0
        };

        // Execute swap through adapter
        let path = vector::empty<address>();
        vector::push_back(&mut path, vault::get_usdt_address());
        vector::push_back(&mut path, vault::get_apt_address());

        pancakeswap_adapter::swap_exact_tokens_for_tokens(
            manager,
            usdt_amount,
            min_output,
            path,
            signer::address_of(manager),
            trade_timestamp + 3600
        );
    }

    // Execute APT to USDT swap with slippage protection
    fun execute_swap_apt_for_usdt(
        manager: &signer,
        apt_amount: u64,
        trade_timestamp: u64,
    ) {
        // Get quote from PancakeSwap
        let expected_usdt = pancakeswap_adapter::get_quote(
            vault::get_apt_address(),
            vault::get_usdt_address(),
            apt_amount
        );

        // Calculate minimum output with slippage protection
        let min_output = if (expected_usdt > 0) {
            expected_usdt - (expected_usdt * MAX_SLIPPAGE / 10000)
        } else {
            0
        };

        // Execute swap through adapter
        let path = vector::empty<address>();
        vector::push_back(&mut path, vault::get_apt_address());
        vector::push_back(&mut path, vault::get_usdt_address());

        pancakeswap_adapter::swap_exact_tokens_for_tokens(
            manager,
            apt_amount,
            min_output,
            path,
            signer::address_of(manager),
            trade_timestamp + 3600
        );
    }

    // Manual rebalancing with custom amount and proper checks
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

        // Check access control
        if (integration.manager_address != manager_addr) {
            return
        };

        if (usdt_amount == 0) {
            return
        };

        // Check cooldown
        let current_time = timestamp::now_seconds();
        if (current_time - integration.last_rebalance < REBALANCE_COOLDOWN) {
            return
        };

        if (direction == 0) {
            // Swap USDT for APT
            execute_swap_usdt_for_apt(manager, usdt_amount, current_time);
        } else if (direction == 1) {
            // Swap APT for USDT
            execute_swap_apt_for_usdt(manager, usdt_amount, current_time);
        };

        integration.last_rebalance = current_time;
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

    // Get optimal rebalancing amount with proper calculations
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

        if (current_usdt_ratio > TARGET_USDT_RATIO + REBALANCE_THRESHOLD) {
            // Too much USDT, need to swap USDT for APT
            let excess_usdt = (total_usdt - (total_value * TARGET_USDT_RATIO / 10000)) / 2;
            (excess_usdt, 0) // USDT amount, direction (0 = USDT->APT)
        } else if (current_usdt_ratio < TARGET_USDT_RATIO - REBALANCE_THRESHOLD) {
            // Too much APT, need to swap APT for USDT
            let excess_apt = (total_apt - (total_value * (10000 - TARGET_USDT_RATIO) / 10000)) / 2;
            (excess_apt, 1) // APT amount, direction (1 = APT->USDT)
        } else {
            (0, 0) // No rebalancing needed
        }
    }

    // Get quote for swap with slippage calculation
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

    // Check if rebalancing is needed
    #[view]
    public fun is_rebalancing_needed(): bool {
        let (total_shares, total_usdt, total_apt, created_at, is_active, fee_rate) = vault::get_vault_status();
        
        if (!is_active) {
            return false
        };

        let total_value = total_usdt + total_apt;
        let current_usdt_ratio = if (total_value > 0) {
            (total_usdt * 10000) / total_value
        } else {
            0
        };

        current_usdt_ratio > TARGET_USDT_RATIO + REBALANCE_THRESHOLD || 
        current_usdt_ratio < TARGET_USDT_RATIO - REBALANCE_THRESHOLD
    }

    // Get cooldown status
    #[view]
    public fun get_cooldown_status(manager_addr: address): (bool, u64) acquires IntegrationStorage {
        if (!exists<IntegrationStorage>(manager_addr)) {
            return (false, 0)
        };

        let integration = borrow_global<IntegrationStorage>(manager_addr);
        let current_time = timestamp::now_seconds();
        let time_since_last = current_time - integration.last_rebalance;
        
        (time_since_last >= REBALANCE_COOLDOWN, time_since_last)
    }
} 