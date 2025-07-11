#!/bin/bash

echo "🔍 Monitoring Aptos Vault Deployment..."

VAULT_ADDRESS="0x2fdd1d8c08c6d2e447cffd67419cd9f0d53bedd003e5a6ee427b649f0c1077ef"

# Function to check deployment status
check_deployment() {
    echo "📊 Checking deployment status..."
    
    # Check account sequence number
    SEQUENCE=$(aptos account list --profile mainnet --query sequence_number 2>/dev/null | jq -r '.Result[0]."0x1::account::Account".sequence_number' 2>/dev/null)
    
    if [ "$SEQUENCE" != "0" ] && [ "$SEQUENCE" != "null" ]; then
        echo "✅ Deployment successful! Sequence number: $SEQUENCE"
        return 0
    else
        echo "⏳ Deployment in progress or failed..."
        return 1
    fi
}

# Function to check modules
check_modules() {
    echo "📦 Checking deployed modules..."
    MODULES=$(curl -s "https://fullnode.mainnet.aptoslabs.com/v1/accounts/$VAULT_ADDRESS/modules" 2>/dev/null)
    
    if echo "$MODULES" | jq -e '.data' >/dev/null 2>&1; then
        echo "✅ Modules found:"
        echo "$MODULES" | jq -r '.data[].name'
        return 0
    else
        echo "❌ No modules found yet"
        return 1
    fi
}

# Monitor for 5 minutes
echo "⏰ Monitoring for 5 minutes..."
for i in {1..30}; do
    echo ""
    echo "🔄 Check $i/30..."
    
    if check_deployment && check_modules; then
        echo ""
        echo "🎉 DEPLOYMENT SUCCESSFUL!"
        echo "📊 Vault Address: $VAULT_ADDRESS"
        echo "🔗 Explorer: https://explorer.aptoslabs.com/account/$VAULT_ADDRESS?network=mainnet"
        exit 0
    fi
    
    sleep 10
done

echo ""
echo "⏰ Timeout reached. Checking final status..."
check_deployment
check_modules

echo ""
echo "📋 Final status check completed." 