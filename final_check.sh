#!/bin/bash

echo "🎯 Final Deployment Check for Aptos Vault"

VAULT_ADDRESS="0x2fdd1d8c08c6d2e447cffd67419cd9f0d53bedd003e5a6ee427b649f0c1077ef"

echo "📊 Vault Address: $VAULT_ADDRESS"
echo "🌐 Network: Aptos Mainnet"

# Check account status
echo ""
echo "💰 Account Status:"
aptos account list --profile mainnet

# Check if modules are deployed
echo ""
echo "📦 Checking Deployed Modules:"
MODULES_RESPONSE=$(curl -s "https://fullnode.mainnet.aptoslabs.com/v1/accounts/$VAULT_ADDRESS/modules")

if echo "$MODULES_RESPONSE" | jq -e '.data' >/dev/null 2>&1; then
    echo "✅ Modules deployed successfully!"
    echo "$MODULES_RESPONSE" | jq -r '.data[].name'
else
    echo "❌ No modules found"
    echo "Response: $MODULES_RESPONSE"
fi

# Check recent transactions
echo ""
echo "📋 Recent Transactions:"
TRANSACTIONS=$(curl -s "https://fullnode.mainnet.aptoslabs.com/v1/accounts/$VAULT_ADDRESS/transactions?limit=5")

if echo "$TRANSACTIONS" | jq -e '.data' >/dev/null 2>&1; then
    echo "✅ Found transactions:"
    echo "$TRANSACTIONS" | jq -r '.data[] | "\(.version): \(.payload.function)"'
else
    echo "❌ No transactions found"
fi

# Check explorer link
echo ""
echo "🔗 Explorer Links:"
echo "Account: https://explorer.aptoslabs.com/account/$VAULT_ADDRESS?network=mainnet"
echo "Modules: https://explorer.aptoslabs.com/account/$VAULT_ADDRESS/modules?network=mainnet"

# Summary
echo ""
echo "📊 DEPLOYMENT SUMMARY:"
echo "================================"

if echo "$MODULES_RESPONSE" | jq -e '.data' >/dev/null 2>&1; then
    echo "✅ SUCCESS: Aptos Vault deployed successfully!"
    echo "📦 Modules: $(echo "$MODULES_RESPONSE" | jq -r '.data | length') modules deployed"
    echo "💰 Balance: $(aptos account list --profile mainnet --query balance 2>/dev/null | jq -r '.Result[0]."0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>".coin.value' 2>/dev/null || echo "Unknown") octas"
    echo ""
    echo "🎉 Your Aptos Vault is now live on Mainnet!"
    echo "🔗 View on Explorer: https://explorer.aptoslabs.com/account/$VAULT_ADDRESS?network=mainnet"
else
    echo "❌ FAILED: Deployment unsuccessful"
    echo "💡 Possible issues:"
    echo "   - Insufficient gas fees"
    echo "   - Network congestion"
    echo "   - Compilation errors"
    echo ""
    echo "🔄 Try deploying again or check the logs above"
fi

echo ""
echo "🏁 Check completed!" 