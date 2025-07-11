#!/bin/bash

echo "🚀 Starting Aptos Vault Mainnet Demo..."

# Check if virtual environment exists
if [ ! -d "aptos_vault_env" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv aptos_vault_env
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source aptos_vault_env/bin/activate

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install flask flask-cors requests

# Start API server in background
echo "🌐 Starting API server for mainnet..."
python aptos_vault_api.py &
API_PID=$!

# Wait a moment for API to start
sleep 3

# Start frontend in background
echo "🎨 Starting frontend..."
cd frontend
npm run dev &
FRONTEND_PID=$!

# Wait a moment for frontend to start
sleep 5

echo ""
echo "✅ Aptos Vault Mainnet Demo started successfully!"
echo ""
echo "📊 Services running:"
echo "   🌐 API Server: http://localhost:5001"
echo "   🎨 Frontend: http://localhost:5174/"
echo ""
echo "🔗 Vault Information:"
echo "   📍 Vault Address: 0x19fc3b30e6839f609514af5861645f365b87627d25faf83d2a6d4889614f2883"
echo "   🌐 Network: Aptos Mainnet"
echo "   💰 USDT LayerZero: 0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT"
echo ""
echo "🎯 Features available:"
echo "   ✅ Wallet Connection (Pontem)"
echo "   ✅ USDT Deposit/Withdraw"
echo "   ✅ Vault Rebalancing"
echo "   ✅ Real-time Balance Tracking"
echo "   ✅ Cross-chain USDT Support"
echo ""
echo "📖 Documentation:"
echo "   📋 User Guide: USER_GUIDE.md"
echo "   💰 USDT Info: USDT_LAYERZERO_INFO.md"
echo ""
echo "🛑 To stop the demo, press Ctrl+C"
echo ""

# Keep the script running
wait 