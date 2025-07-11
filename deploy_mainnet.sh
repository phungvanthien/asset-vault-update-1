#!/bin/bash

echo "🚀 Deploying Aptos Vault to Mainnet..."

# Configuration
VAULT_ADDRESS="0x19fc3b30e6839f609514af5861645f365b87627d25faf83d2a6d4889614f2883"
NETWORK="mainnet"

echo "📊 Vault Address: $VAULT_ADDRESS"
echo "🌐 Network: $NETWORK"
echo "💰 USDT LayerZero: 0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"

cd aptos-vault

echo "📦 Compiling contracts for mainnet..."
aptos move compile

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful"
    
    echo "🚀 Publishing contracts to mainnet..."
    aptos move publish \
        --named-addresses vault=$VAULT_ADDRESS \
        --profile mainnet
    
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
    else
        echo "❌ Contract deployment failed"
        echo "💡 Make sure you have enough APT for gas fees"
    fi
else
    echo "❌ Compilation failed"
fi

echo "🏁 Deployment script completed" 