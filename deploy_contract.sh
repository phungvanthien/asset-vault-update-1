#!/bin/bash

echo "🚀 Starting contract deployment..."

cd aptos-vault

echo "📦 Compiling contracts..."
aptos move compile

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful"
    
    echo "🚀 Publishing contracts..."
    aptos move publish --named-addresses vault=0xc8fa51ab7f319d232099afe32ebc9f57b898879dc724fb4f71b4d92f62ea0a77 --profile testnet
    
    if [ $? -eq 0 ]; then
        echo "✅ Contract deployment successful!"
        echo "📊 Vault Address: 0xc8fa51ab7f319d232099afe32ebc9f57b898879dc724fb4f71b4d92f62ea0a77"
        echo "🌐 Network: testnet"
    else
        echo "❌ Contract deployment failed"
    fi
else
    echo "❌ Compilation failed"
fi

echo "🏁 Deployment script completed" 