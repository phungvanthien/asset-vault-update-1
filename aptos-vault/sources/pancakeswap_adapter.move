module vault::pancakeswap_adapter {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::account;

    // PancakeSwap Router address on Mainnet
    const PANCAKESWAP_ROUTER: address = @0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60;
    
    // Token addresses
    const USDT_ADDRESS: address = @0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa;
    const APT_ADDRESS: address = @0x1;

    // Router storage for managing swap state
    struct RouterStorage has key {
        router_address: address,
        owner: address,
        is_active: bool,
        total_swaps: u64,
        total_volume: u64,
        last_swap_timestamp: u64,
    }

    // Token approval storage
    struct TokenApproval has key {
        token_address: address,
        spender: address,
        amount: u64,
        approved_at: u64,
    }

    // Swap event
    struct SwapEvent has drop, store {
        user: address,
        input_token: address,
        output_token: address,
        input_amount: u64,
        output_amount: u64,
        timestamp: u64,
        slippage: u64,
    }

    // Error codes
    const EROUTER_NOT_ACTIVE: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EEXCESSIVE_SLIPPAGE: u64 = 3;
    const EINVALID_PATH: u64 = 4;
    const EAPPROVAL_REQUIRED: u64 = 5;
    const EINVALID_AMOUNT: u64 = 6;

    // Initialize router storage
    public entry fun initialize_router(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        
        move_to(owner, RouterStorage {
            router_address: PANCAKESWAP_ROUTER,
            owner: owner_addr,
            is_active: true,
            total_swaps: 0,
            total_volume: 0,
            last_swap_timestamp: 0,
        });
    }

    // Set router active status
    public entry fun set_router_active(owner: &signer, is_active: bool) acquires RouterStorage {
        let owner_addr = signer::address_of(owner);
        
        if (!exists<RouterStorage>(owner_addr)) {
            return
        };
        
        let router = borrow_global_mut<RouterStorage>(owner_addr);
        
        if (router.owner != owner_addr) {
            return
        };
        
        router.is_active = is_active;
    }

    // Get router address
    #[view]
    public fun get_pancakeswap_router(): address {
        PANCAKESWAP_ROUTER
    }

    // Get quote for swap
    #[view]
    public fun get_quote(
        input_token: address,
        output_token: address,
        amount_in: u64
    ): u64 {
        // In a real implementation, this would query PancakeSwap's getAmountsOut
        // For now, we'll use a simple 1:1 ratio as placeholder
        if (input_token == APT_ADDRESS && output_token == USDT_ADDRESS) {
            amount_in  // 1:1 ratio for demo
        } else if (input_token == USDT_ADDRESS && output_token == APT_ADDRESS) {
            amount_in  // 1:1 ratio for demo
        } else {
            0
        }
    }

    // Swap exact tokens for tokens
    public entry fun swap_exact_tokens_for_tokens(
        user: &signer,
        amount_in: u64,
        amount_out_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64
    ) acquires RouterStorage {
        let user_addr = signer::address_of(user);
        
        // Check if router is active
        if (!exists<RouterStorage>(user_addr)) {
            return
        };
        
        let router = borrow_global_mut<RouterStorage>(user_addr);
        
        if (!router.is_active) {
            return
        };

        // Validate deadline
        if (timestamp::now_seconds() > deadline) {
            return
        };

        // Validate path
        if (vector::length(&path) < 2) {
            return
        };

        let input_token = *vector::borrow(&path, 0);
        let output_token = *vector::borrow(&path, vector::length(&path) - 1);

        // Get quote
        let expected_output = get_quote(input_token, output_token, amount_in);
        
        // Check slippage
        if (expected_output < amount_out_min) {
            return
        };

        // Check if user has sufficient balance
        if (input_token == APT_ADDRESS) {
            let apt_balance = coin::balance<coin::AptosCoin>(user_addr);
            if (apt_balance < amount_in) {
                return
            };
        } else if (input_token == USDT_ADDRESS) {
            // Check USDT balance (would need proper USDT coin type)
            // For now, we'll assume sufficient balance
        };

        // Execute swap (simplified - in real implementation, this would call PancakeSwap)
        // For demo purposes, we'll just update the router stats
        
        router.total_swaps = router.total_swaps + 1;
        router.total_volume = router.total_volume + amount_in;
        router.last_swap_timestamp = timestamp::now_seconds();

        // Emit swap event
        let swap_event = SwapEvent {
            user: user_addr,
            input_token: input_token,
            output_token: output_token,
            input_amount: amount_in,
            output_amount: expected_output,
            timestamp: timestamp::now_seconds(),
            slippage: if (expected_output > 0) {
                ((expected_output - amount_out_min) * 10000) / expected_output
            } else {
                0
            },
        };

        // In a real implementation, you would emit this event
        // event::emit(swap_event_handle, swap_event);
    }

    // Swap APT for USDT
    public entry fun swap_apt_for_usdt(
        user: &signer,
        apt_amount: u64,
        min_usdt_amount: u64
    ) acquires RouterStorage {
        let path = vector::empty<address>();
        vector::push_back(&mut path, APT_ADDRESS);
        vector::push_back(&mut path, USDT_ADDRESS);
        
        swap_exact_tokens_for_tokens(
            user,
            apt_amount,
            min_usdt_amount,
            path,
            signer::address_of(user),
            timestamp::now_seconds() + 3600
        );
    }

    // Swap USDT for APT
    public entry fun swap_usdt_for_apt(
        user: &signer,
        usdt_amount: u64,
        min_apt_amount: u64
    ) acquires RouterStorage {
        let path = vector::empty<address>();
        vector::push_back(&mut path, USDT_ADDRESS);
        vector::push_back(&mut path, APT_ADDRESS);
        
        swap_exact_tokens_for_tokens(
            user,
            usdt_amount,
            min_apt_amount,
            path,
            signer::address_of(user),
            timestamp::now_seconds() + 3600
        );
    }

    // Get router stats
    #[view]
    public fun get_router_stats(owner_addr: address): (address, bool, u64, u64, u64) acquires RouterStorage {
        if (!exists<RouterStorage>(owner_addr)) {
            return (@0x0, false, 0, 0, 0)
        };
        
        let router = borrow_global<RouterStorage>(owner_addr);
        (router.router_address, router.is_active, router.total_swaps, router.total_volume, router.last_swap_timestamp)
    }

    // Approve token for swap
    public entry fun approve_token(
        user: &signer,
        token_address: address,
        spender: address,
        amount: u64
    ) {
        let user_addr = signer::address_of(user);
        
        move_to(user, TokenApproval {
            token_address: token_address,
            spender: spender,
            amount: amount,
            approved_at: timestamp::now_seconds(),
        });
    }

    // Check token approval
    #[view]
    public fun check_approval(
        user_addr: address,
        token_address: address,
        spender: address
    ): (bool, u64) acquires TokenApproval {
        if (!exists<TokenApproval>(user_addr)) {
            return (false, 0)
        };
        
        let approval = borrow_global<TokenApproval>(user_addr);
        
        if (approval.token_address == token_address && approval.spender == spender) {
            (true, approval.amount)
        } else {
            (false, 0)
        }
    }

    // Calculate slippage
    #[view]
    public fun calculate_slippage(
        expected_amount: u64,
        actual_amount: u64
    ): u64 {
        if (expected_amount == 0) {
            return 0
        };
        
        if (actual_amount >= expected_amount) {
            0
        } else {
            ((expected_amount - actual_amount) * 10000) / expected_amount
        }
    }

    // Get optimal swap path
    #[view]
    public fun get_optimal_path(
        input_token: address,
        output_token: address
    ): vector<address> {
        let path = vector::empty<address>();
        vector::push_back(&mut path, input_token);
        vector::push_back(&mut path, output_token);
        path
    }
} 