#!/bin/bash

echo "🚀 Deploying Aptos Vault to Mainnet with Cost Estimation..."

# Configuration
VAULT_ADDRESS="0x19fc3b30e6839f609514af5861645f365b87627d25faf83d2a6d4889614f2883"
NETWORK="mainnet"

echo "📊 Vault Address: $VAULT_ADDRESS"
echo "🌐 Network: $NETWORK"
echo "💰 USDT LayerZero: 0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"

cd aptos-vault

# Check account balance first
echo "💳 Checking account balance..."
BALANCE=$(aptos account list --profile mainnet --query balance --output json | jq -r '.result[0].coin.value')
echo "💰 Current balance: $BALANCE APT"

# Estimate minimum required
MIN_REQUIRED="0.1"
if (( $(echo "$BALANCE < $MIN_REQUIRED" | bc -l) )); then
    echo "❌ Insufficient balance. Need at least $MIN_REQUIRED APT"
    echo "💡 Please fund your account with more APT"
    exit 1
fi

echo "✅ Sufficient balance for deployment"

# Cost estimation
echo ""
echo "💰 COST ESTIMATION:"
echo "   📦 Compile: ~0.001 APT"
echo "   🚀 Deploy vault_core: ~0.02 APT"
echo "   🚀 Deploy pancakeswap_adapter: ~0.02 APT"
echo "   🚀 Deploy vault_comptroller: ~0.02 APT"
echo "   🏦 Create vault: ~0.01 APT"
echo "   📊 Total estimated: ~0.06 APT"
echo ""

echo "📦 Compiling contracts for mainnet..."
aptos move compile --estimate-max-gas

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful"
    
    echo "🚀 Publishing contracts to mainnet..."
    echo "💡 Estimated cost: ~0.06 APT"
    echo ""
    
    aptos move publish \
        --named-addresses vault=$VAULT_ADDRESS \
        --profile mainnet \
        --estimate-max-gas
    
    if [ $? -eq 0 ]; then
        echo "✅ Contract deployment successful!"
        echo "📊 Vault Address: $VAULT_ADDRESS"
        echo "🌐 Network: $NETWORK"
        echo ""
        echo "🔗 View on Explorer:"
        echo "https://explorer.aptoslabs.com/account/$VAULT_ADDRESS?network=mainnet"
        echo ""
        echo "💰 USDT LayerZero Address:"
        echo "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"
        echo ""
        echo "🎉 Vault is now live on Aptos Mainnet!"
        echo ""
        echo "💡 Next steps:"
        echo "   1. Fund vault with USDT for testing"
        echo "   2. Test deposit/withdraw functions"
        echo "   3. Test rebalancing functionality"
    else
        echo "❌ Contract deployment failed"
        echo "💡 Check your balance and try again"
    fi
else
    echo "❌ Compilation failed"
fi

echo "🏁 Deployment script completed" 