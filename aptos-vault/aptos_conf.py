"""
Config variables for Aptos deployment scripts.
Tương thích với hackathon/conf.py hiện tại.

- Manually deployed
- Address recorded here
"""

# Aptos Module Address (sẽ được set sau khi deploy)
APTOS_MODULE_ADDRESS = None

# Vault ID (sẽ được set sau khi tạo vault)
VAULT_ID = 0

# USDT Address trên Aptos Mainnet
USDT_ADDRESS = "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"

# PancakeSwap Addresses trên Aptos Mainnet
PANCAKESWAP_ROUTER_ADDRESS = "0xc7efb4076dbe143cbcd98cf5e5f40f28f0c8a0c8"
PANCAKESWAP_FACTORY_ADDRESS = "0xc7efb4076dbe143cbcd98cf5e5f40f28f0c8a0c8"
PANCAKESWAP_QUOTER_ADDRESS = "0xc7efb4076dbe143cbcd98cf5e5f40f28f0c8a0c8"

# APT Coin Address
APT_COIN_ADDRESS = "0x1::aptos_coin::AptosCoin"

# Fee rate (basis points)
FEE_RATE = 100  # 1%

# Minimum deposit amount (USDT)
MIN_DEPOSIT_AMOUNT = 1000000  # 1 USDT

# Minimum rebalance threshold
MIN_REBALANCE_THRESHOLD = 300000  # 0.3 USDT

# Network configuration
APTOS_NODE_URL = "https://fullnode.mainnet.aptoslabs.com"
APTOS_FAUCET_URL = "https://faucet.mainnet.aptoslabs.com"

# Environment variables
APTOS_PRIVATE_KEY = None  # Sẽ được set từ environment
APTOS_MODULE_ADDRESS_ENV = "APTOS_MODULE_ADDRESS"
APTOS_PRIVATE_KEY_ENV = "APTOS_PRIVATE_KEY"

# Trading configuration
TRADING_STRATEGY_CYCLE = "4d"  # 4 days
MAX_ASSETS_IN_PORTFOLIO = 3
VALUE_ALLOCATED_TO_POSITIONS = 0.5  # 50%

# Stop loss and take profit
STOP_LOSS = 0.97  # 97%
TAKE_PROFIT = 1.33  # 133%

# Minimum thresholds
MINIMUM_MOMENTUM_THRESHOLD = 0.03  # 3%
MINIMUM_LIQUIDITY_THRESHOLD = 300000  # 300k USDT
MINIMUM_REBALANCE_TRADE_THRESHOLD = 300  # 0.3 USDT

# Bull market configuration
BULL_MARKET_MOVING_AVERAGE_WINDOW = 15  # days

# Reserve currency
RESERVE_CURRENCY = "USDT"

# Chain configuration
CHAIN_ID = "aptos"
EXCHANGE_SLUG = "pancakeswap"

# Quote tokens
QUOTE_TOKENS = {
    USDT_ADDRESS,  # USDT
    APT_COIN_ADDRESS,  # APT
}

# Time buckets
CANDLE_DATA_TIME_FRAME = "1d"  # 1 day
STOP_LOSS_DATA_GRANULARITY = "1h"  # 1 hour

# Strategy version
TRADING_STRATEGY_ENGINE_VERSION = "0.1"
TRADING_STRATEGY_TYPE = "managed_positions"

# Trade routing
TRADE_ROUTING = "ignore" 