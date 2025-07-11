#!/bin/bash

echo "🔍 Checking Aptos Vault Deployment Status..."

# Configuration
VAULT_ADDRESS="0x2fdd1d8c08c6d2e447cffd67419cd9f0d53bedd003e5a6ee427b649f0c1077ef"
NETWORK="mainnet"

echo "📊 Vault Address: $VAULT_ADDRESS"
echo "🌐 Network: $NETWORK"

# Check account balance
echo ""
echo "💰 Checking account balance..."
aptos account list --profile mainnet

# Check if modules are deployed
echo ""
echo "📦 Checking deployed modules..."
curl -s "https://fullnode.mainnet.aptoslabs.com/v1/accounts/$VAULT_ADDRESS/modules" | jq .

# Check recent transactions
echo ""
echo "📋 Recent transactions..."
curl -s "https://fullnode.mainnet.aptoslabs.com/v1/accounts/$VAULT_ADDRESS/transactions?limit=5" | jq .

echo ""
echo "🔗 View on Explorer:"
echo "https://explorer.aptoslabs.com/account/$VAULT_ADDRESS?network=mainnet"

echo ""
echo "✅ Deployment check completed!" 