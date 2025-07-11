#!/bin/bash

echo "🚀 Starting Aptos Vault Project..."

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
echo "🌐 Starting API server..."
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
echo "✅ Project started successfully!"
echo ""
echo "📊 Services running:"
echo "   🌐 API Server: http://localhost:5001"
echo "   🎨 Frontend:   http://localhost:5174"
echo "   📋 API Endpoints:"
echo "      GET  /api/vault/status"
echo "      GET  /api/vault/balance/<address>"
echo "      POST /api/vault/deposit"
echo "      POST /api/vault/withdraw"
echo "      POST /api/vault/rebalance"
echo "      POST /api/vault/swap"
echo "      GET  /api/vault/info"
echo ""
echo "🔗 Vault Address: 0xc8fa51ab7f319d232099afe32ebc9f57b898879dc724fb4f71b4d92f62ea0a77"
echo "🌐 Network: testnet"
echo ""
echo "💡 To stop the project, press Ctrl+C"
echo ""

# Wait for user to stop
wait 