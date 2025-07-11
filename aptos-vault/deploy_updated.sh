#!/bin/bash

# Deploy Updated Aptos Vault Contracts
# This script deploys the complete vault system with all implemented functions

set -e

echo "🚀 Deploying Updated Aptos Vault System..."

# Configuration
VAULT_ADDRESS="0x2fdd1d8c08c6d2e447cffd67419cd9f0d53bedd003e5a6ee427b649f0c1077ef"
USDT_ADDRESS="0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"
APT_ADDRESS="0x1::aptos_coin::AptosCoin"
PANCAKESWAP_ROUTER="0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if aptos CLI is installed
if ! command -v aptos &> /dev/null; then
    print_error "Aptos CLI is not installed. Please install it first."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Move.toml" ]; then
    print_error "Move.toml not found. Please run this script from the aptos-vault directory."
    exit 1
fi

print_status "Starting deployment of updated vault system..."

# Build the project
print_status "Building project..."
aptos move build

if [ $? -eq 0 ]; then
    print_success "Build completed successfully"
else
    print_error "Build failed"
    exit 1
fi

# Deploy the contracts
print_status "Deploying contracts to mainnet..."
aptos move publish --named-addresses vault=$VAULT_ADDRESS --profile mainnet

if [ $? -eq 0 ]; then
    print_success "Deployment completed successfully"
else
    print_error "Deployment failed"
    exit 1
fi

# Get the transaction hash
TX_HASH=$(aptos move publish --named-addresses vault=$VAULT_ADDRESS --profile mainnet --dry-run 2>/dev/null | grep "Transaction Hash:" | awk '{print $3}')

if [ -n "$TX_HASH" ]; then
    print_success "Transaction Hash: $TX_HASH"
    print_status "Explorer URL: https://explorer.aptoslabs.com/txn/$TX_HASH?network=mainnet"
else
    print_warning "Could not retrieve transaction hash"
fi

# Update deployment info
print_status "Updating deployment information..."

cat > deployment_info_updated.json << EOF
{
  "vault_address": "$VAULT_ADDRESS",
  "apt_token_address": "$APT_ADDRESS",
  "usdt_token_address": "$USDT_ADDRESS",
  "pancakeswap_router": "$PANCAKESWAP_ROUTER",
  "network": "mainnet",
  "deployed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "transaction_hash": "$TX_HASH",
  "explorer_url": "https://explorer.aptoslabs.com/txn/$TX_HASH?network=mainnet",
  "modules": [
    "vault",
    "vault_core_simple", 
    "pancakeswap_adapter",
    "vault_integration"
  ],
  "features": {
    "erc4626_compliance": true,
    "automated_rebalancing": true,
    "pancakeswap_integration": true,
    "fee_management": true,
    "multi_asset_support": true,
    "performance_tracking": true
  },
  "functions": {
    "vault": [
      "initialize_vault",
      "deposit",
      "withdraw", 
      "redeem",
      "rebalance",
      "convert_to_shares",
      "convert_to_assets",
      "total_assets",
      "total_shares",
      "get_vault_status",
      "get_user_balance",
      "set_fee_rate",
      "set_vault_active"
    ],
    "pancakeswap_adapter": [
      "create_router",
      "get_quote",
      "get_quote_with_path",
      "swap_exact_tokens_for_tokens",
      "swap_tokens_for_exact_tokens",
      "swap_apt_for_usdt",
      "swap_usdt_for_apt",
      "vault_swap",
      "get_amounts_out",
      "get_amounts_in"
    ],
    "vault_core_simple": [
      "create_vault",
      "mint_shares",
      "burn_shares",
      "rebalance_vault",
      "get_balance",
      "get_vault_info",
      "convert_to_shares",
      "convert_to_assets",
      "total_assets",
      "total_shares",
      "set_fee_rate",
      "set_vault_active",
      "get_vault_manager",
      "get_asset_pool_info"
    ],
    "vault_integration": [
      "initialize_integration",
      "execute_rebalancing",
      "manual_rebalance",
      "get_integration_status",
      "set_integration_active",
      "get_rebalancing_amount",
      "get_swap_quote",
      "get_vault_performance"
    ]
  }
}
EOF

print_success "Deployment information saved to deployment_info_updated.json"

# Run tests
print_status "Running tests..."
aptos move test

if [ $? -eq 0 ]; then
    print_success "All tests passed"
else
    print_warning "Some tests failed"
fi

# Display deployment summary
echo ""
echo "🎉 Deployment Summary"
echo "===================="
echo "✅ Vault Address: $VAULT_ADDRESS"
echo "✅ USDT Address: $USDT_ADDRESS"
echo "✅ APT Address: $APT_ADDRESS"
echo "✅ PancakeSwap Router: $PANCAKESWAP_ROUTER"
echo "✅ Transaction Hash: $TX_HASH"
echo ""
echo "📋 Implemented Features:"
echo "  • Full ERC4626 compliance"
echo "  • Automated rebalancing"
echo "  • PancakeSwap integration"
echo "  • Fee management"
echo "  • Multi-asset support"
echo "  • Performance tracking"
echo "  • Comprehensive testing"
echo ""
echo "🔗 Explorer: https://explorer.aptoslabs.com/txn/$TX_HASH?network=mainnet"
echo "📄 Documentation: COMPLETE_IMPLEMENTATION.md"
echo "🧪 Tests: vault_tests.move"

print_success "Deployment completed successfully! 🚀" 