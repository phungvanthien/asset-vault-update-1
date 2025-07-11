#!/bin/bash

echo "🚀 Simple Aptos Vault Deployment"

VAULT_ADDRESS="0x2fdd1d8c08c6d2e447cffd67419cd9f0d53bedd003e5a6ee427b649f0c1077ef"

echo "📊 Vault Address: $VAULT_ADDRESS"
echo "🌐 Network: Aptos Mainnet"

# Check balance first
echo ""
echo "💰 Checking balance..."
aptos account list --profile mainnet

# Deploy simple vault first
echo ""
echo "📦 Deploying simple vault module..."
aptos move publish --profile mainnet --named-addresses vault=$VAULT_ADDRESS

# Check result
echo ""
echo "📋 Checking deployment result..."
sleep 10

# Check if modules are deployed
MODULES=$(curl -s "https://fullnode.mainnet.aptoslabs.com/v1/accounts/$VAULT_ADDRESS/modules")

if echo "$MODULES" | jq -e '.data' >/dev/null 2>&1; then
    echo "✅ SUCCESS: Modules deployed!"
    echo "$MODULES" | jq -r '.data[].name'
else
    echo "❌ FAILED: No modules found"
    echo "Response: $MODULES"
fi

echo ""
echo "🔗 View on Explorer:"
echo "https://explorer.aptoslabs.com/account/$VAULT_ADDRESS?network=mainnet"

echo ""
echo "🏁 Deployment completed!" 