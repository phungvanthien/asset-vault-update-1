# 🔗 Integration Guide - Dexonic Asset Vault

## 📋 Tổng quan tích hợp

Hướng dẫn này cung cấp các bước chi tiết để tích hợp Dexonic Asset Vault API vào Frontend và Trading Bot.

---

## 🖥️ Frontend Integration

### 1. Setup Environment

#### Install Dependencies
```bash
# JavaScript/TypeScript
npm install @dexonic/api axios websocket

# React
npm install react-query @tanstack/react-query

# Vue.js
npm install vue-query @vueuse/core
```

#### Environment Variables
```env
# .env
VITE_API_BASE_URL=https://api.dexonic-vault.com/api
VITE_WS_URL=wss://api.dexonic-vault.com/ws
VITE_API_KEY=your_api_key_here
VITE_VAULT_ADDRESS=0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d
```

### 2. API Client Setup

#### JavaScript/TypeScript
```typescript
// api/client.ts
import axios from 'axios';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: {
    'Authorization': `Bearer ${import.meta.env.VITE_API_KEY}`,
    'Content-Type': 'application/json'
  }
});

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    // Add loading state
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    // Handle errors
    if (error.response?.status === 401) {
      // Redirect to login
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

#### React Hooks
```typescript
// hooks/useVault.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import apiClient from '../api/client';

export const useVaultStatus = () => {
  return useQuery({
    queryKey: ['vault', 'status'],
    queryFn: async () => {
      const response = await apiClient.get('/vault/status');
      return response.data;
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  });
};

export const useUserBalance = (address: string) => {
  return useQuery({
    queryKey: ['vault', 'balance', address],
    queryFn: async () => {
      const response = await apiClient.get(`/vault/balance/${address}`);
      return response.data;
    },
    enabled: !!address,
  });
};

export const useDeposit = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (data: { userAddress: string; amount: string }) => {
      const response = await apiClient.post('/vault/deposit', data);
      return response.data;
    },
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries({ queryKey: ['vault', 'status'] });
      queryClient.invalidateQueries({ queryKey: ['vault', 'balance'] });
    },
  });
};

export const useWithdraw = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (data: { userAddress: string; shares: string }) => {
      const response = await apiClient.post('/vault/withdraw', data);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vault', 'status'] });
      queryClient.invalidateQueries({ queryKey: ['vault', 'balance'] });
    },
  });
};
```

### 3. WebSocket Integration

#### Real-time Updates
```typescript
// hooks/useWebSocket.ts
import { useEffect, useState } from 'react';

export const useWebSocket = () => {
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const websocket = new WebSocket(import.meta.env.VITE_WS_URL);

    websocket.onopen = () => {
      setIsConnected(true);
      // Subscribe to channels
      websocket.send(JSON.stringify({
        action: 'subscribe',
        channels: ['vault_status', 'price_updates', 'bot_alerts']
      }));
    };

    websocket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      
      switch (data.type) {
        case 'vault_status':
          // Update vault status
          break;
        case 'price_update':
          // Update price data
          break;
        case 'bot_alert':
          // Show notification
          break;
      }
    };

    websocket.onclose = () => {
      setIsConnected(false);
    };

    setWs(websocket);

    return () => {
      websocket.close();
    };
  }, []);

  return { ws, isConnected };
};
```

### 4. Component Examples

#### Vault Dashboard
```typescript
// components/VaultDashboard.tsx
import React from 'react';
import { useVaultStatus, useUserBalance } from '../hooks/useVault';

export const VaultDashboard: React.FC = () => {
  const { data: vaultStatus, isLoading: statusLoading } = useVaultStatus();
  const { data: userBalance, isLoading: balanceLoading } = useUserBalance(userAddress);

  if (statusLoading || balanceLoading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="vault-dashboard">
      <div className="vault-stats">
        <h2>Vault Statistics</h2>
        <div className="stats-grid">
          <div className="stat">
            <label>Total Value</label>
            <span>${vaultStatus?.data?.vault_value_usd}</span>
          </div>
          <div className="stat">
            <label>APY</label>
            <span>{vaultStatus?.data?.apy}%</span>
          </div>
          <div className="stat">
            <label>Total Shares</label>
            <span>{vaultStatus?.data?.total_shares}</span>
          </div>
        </div>
      </div>
      
      <div className="user-balance">
        <h3>Your Balance</h3>
        <div className="balance-grid">
          <div className="balance-item">
            <label>Shares</label>
            <span>{userBalance?.data?.shares}</span>
          </div>
          <div className="balance-item">
            <label>Value</label>
            <span>${userBalance?.data?.total_value_usd}</span>
          </div>
          <div className="balance-item">
            <label>P&L</label>
            <span className={userBalance?.data?.profit_loss_percentage > 0 ? 'positive' : 'negative'}>
              {userBalance?.data?.profit_loss_percentage}%
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
```

#### Deposit Form
```typescript
// components/DepositForm.tsx
import React, { useState } from 'react';
import { useDeposit } from '../hooks/useVault';

export const DepositForm: React.FC = () => {
  const [amount, setAmount] = useState('');
  const [slippage, setSlippage] = useState('0.5');
  const depositMutation = useDeposit();

  const handleDeposit = async () => {
    try {
      await depositMutation.mutateAsync({
        userAddress: userAddress,
        amount: amount,
        slippage: slippage
      });
      
      // Show success message
      setAmount('');
    } catch (error) {
      // Show error message
    }
  };

  return (
    <div className="deposit-form">
      <h3>Deposit USDT</h3>
      <div className="form-group">
        <label>Amount (USDT)</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="Enter amount"
        />
      </div>
      
      <div className="form-group">
        <label>Slippage (%)</label>
        <input
          type="number"
          value={slippage}
          onChange={(e) => setSlippage(e.target.value)}
          step="0.1"
        />
      </div>
      
      <button
        onClick={handleDeposit}
        disabled={depositMutation.isPending}
      >
        {depositMutation.isPending ? 'Processing...' : 'Deposit'}
      </button>
    </div>
  );
};
```

---

## 🤖 Trading Bot Integration

### 1. Python Setup

#### Install Dependencies
```bash
pip install requests websocket-client pandas numpy ta-lib ccxt
```

#### Environment Setup
```python
# config.py
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    API_BASE_URL = os.getenv('API_BASE_URL', 'https://api.dexonic-vault.com/api')
    API_KEY = os.getenv('API_KEY')
    VAULT_ADDRESS = os.getenv('VAULT_ADDRESS', '0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d')
    WS_URL = os.getenv('WS_URL', 'wss://api.dexonic-vault.com/ws')
```

### 2. API Client

```python
# api_client.py
import requests
import json
from typing import Dict, Any, Optional

class DexonicAPIClient:
    def __init__(self, base_url: str, api_key: str):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
    
    def _make_request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        url = f"{self.base_url}{endpoint}"
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=self.headers)
            elif method == 'POST':
                response = requests.post(url, headers=self.headers, json=data)
            
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"API request failed: {e}")
    
    def get_vault_status(self) -> Dict[str, Any]:
        return self._make_request('GET', '/vault/status')
    
    def get_user_balance(self, address: str) -> Dict[str, Any]:
        return self._make_request('GET', f'/vault/balance/{address}')
    
    def deposit(self, user_address: str, amount: str, slippage: str = '0.5') -> Dict[str, Any]:
        data = {
            'user_address': user_address,
            'amount': amount,
            'slippage': slippage
        }
        return self._make_request('POST', '/vault/deposit', data)
    
    def withdraw(self, user_address: str, shares: str, slippage: str = '0.5') -> Dict[str, Any]:
        data = {
            'user_address': user_address,
            'amount': shares,
            'slippage': slippage
        }
        return self._make_request('POST', '/vault/withdraw', data)
    
    def get_market_data(self) -> Dict[str, Any]:
        return self._make_request('GET', '/trading/market-data')
    
    def start_bot(self, strategy: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        data = {
            'strategy': strategy,
            'parameters': parameters,
            'auto_trading': True,
            'notification': True
        }
        return self._make_request('POST', '/trading/bot/start', data)
    
    def stop_bot(self, bot_id: str) -> Dict[str, Any]:
        data = {'bot_id': bot_id}
        return self._make_request('POST', '/trading/bot/stop', data)
    
    def get_bot_status(self, bot_id: str) -> Dict[str, Any]:
        return self._make_request('GET', f'/trading/bot/status/{bot_id}')
```

### 3. Trading Bot Implementation

```python
# trading_bot.py
import time
import logging
from typing import Dict, Any
from api_client import DexonicAPIClient
from config import Config

class DexonicTradingBot:
    def __init__(self):
        self.api_client = DexonicAPIClient(Config.API_BASE_URL, Config.API_KEY)
        self.bot_id = None
        self.is_running = False
        self.logger = logging.getLogger(__name__)
    
    def start_rebalancing_bot(self, user_address: str) -> Dict[str, Any]:
        """Start rebalancing trading bot"""
        try:
            parameters = {
                'rebalance_threshold': '10',
                'target_ratio': {
                    'usdt': '50',
                    'apt': '50'
                },
                'max_slippage': '0.5',
                'gas_limit': '100000'
            }
            
            response = self.api_client.start_bot('rebalancing', parameters)
            
            if response['success']:
                self.bot_id = response['data']['bot_id']
                self.is_running = True
                self.logger.info(f"Bot started: {self.bot_id}")
                return response
            else:
                raise Exception("Failed to start bot")
                
        except Exception as e:
            self.logger.error(f"Error starting bot: {e}")
            raise
    
    def stop_bot(self) -> Dict[str, Any]:
        """Stop the trading bot"""
        if not self.bot_id:
            raise Exception("No bot running")
        
        try:
            response = self.api_client.stop_bot(self.bot_id)
            
            if response['success']:
                self.is_running = False
                self.logger.info(f"Bot stopped: {self.bot_id}")
                return response
            else:
                raise Exception("Failed to stop bot")
                
        except Exception as e:
            self.logger.error(f"Error stopping bot: {e}")
            raise
    
    def get_bot_status(self) -> Dict[str, Any]:
        """Get current bot status"""
        if not self.bot_id:
            raise Exception("No bot running")
        
        return self.api_client.get_bot_status(self.bot_id)
    
    def monitor_bot(self, interval: int = 60):
        """Monitor bot performance"""
        while self.is_running:
            try:
                status = self.get_bot_status()
                
                if status['success']:
                    data = status['data']
                    self.logger.info(f"Bot Status: {data['status']}")
                    self.logger.info(f"Total Trades: {data['total_trades']}")
                    self.logger.info(f"Total Profit: ${data['total_profit']}")
                    
                    # Check if bot is still running
                    if data['status'] != 'running':
                        self.is_running = False
                        break
                
                time.sleep(interval)
                
            except Exception as e:
                self.logger.error(f"Error monitoring bot: {e}")
                time.sleep(interval)
    
    def get_market_analysis(self) -> Dict[str, Any]:
        """Get market analysis for decision making"""
        try:
            market_data = self.api_client.get_market_data()
            vault_status = self.api_client.get_vault_status()
            
            # Perform analysis
            analysis = {
                'apt_price': market_data['data']['apt_price_usd'],
                'price_change': market_data['data']['apt_price_change_24h'],
                'volatility': market_data['data']['volatility'],
                'trend': market_data['data']['trend'],
                'vault_apy': vault_status['data']['apy'],
                'rebalance_needed': self._check_rebalance_needed(vault_status['data'])
            }
            
            return analysis
            
        except Exception as e:
            self.logger.error(f"Error getting market analysis: {e}")
            raise
    
    def _check_rebalance_needed(self, vault_data: Dict[str, Any]) -> bool:
        """Check if rebalancing is needed"""
        current_ratio = vault_data['total_usdt'] / (vault_data['total_usdt'] + vault_data['total_apt'])
        target_ratio = 0.5
        
        deviation = abs(current_ratio - target_ratio)
        threshold = vault_data['rebalance_threshold'] / 100
        
        return deviation > threshold
```

### 4. WebSocket Client for Real-time Data

```python
# websocket_client.py
import websocket
import json
import threading
from typing import Callable

class DexonicWebSocketClient:
    def __init__(self, ws_url: str, on_message: Callable = None):
        self.ws_url = ws_url
        self.on_message = on_message
        self.ws = None
        self.is_connected = False
    
    def connect(self):
        """Connect to WebSocket"""
        self.ws = websocket.WebSocketApp(
            self.ws_url,
            on_open=self._on_open,
            on_message=self._on_message,
            on_error=self._on_error,
            on_close=self._on_close
        )
        
        # Start WebSocket connection in a separate thread
        wst = threading.Thread(target=self.ws.run_forever)
        wst.daemon = True
        wst.start()
    
    def _on_open(self, ws):
        """Handle WebSocket open"""
        self.is_connected = True
        print("WebSocket connected")
        
        # Subscribe to channels
        subscribe_message = {
            'action': 'subscribe',
            'channels': ['vault_status', 'price_updates', 'bot_alerts']
        }
        ws.send(json.dumps(subscribe_message))
    
    def _on_message(self, ws, message):
        """Handle incoming messages"""
        try:
            data = json.loads(message)
            
            if self.on_message:
                self.on_message(data)
            else:
                print(f"Received: {data}")
                
        except json.JSONDecodeError as e:
            print(f"Error decoding message: {e}")
    
    def _on_error(self, ws, error):
        """Handle WebSocket errors"""
        print(f"WebSocket error: {error}")
        self.is_connected = False
    
    def _on_close(self, ws, close_status_code, close_msg):
        """Handle WebSocket close"""
        print("WebSocket disconnected")
        self.is_connected = False
    
    def disconnect(self):
        """Disconnect from WebSocket"""
        if self.ws:
            self.ws.close()
```

### 5. Main Bot Runner

```python
# main.py
import logging
from trading_bot import DexonicTradingBot
from websocket_client import DexonicWebSocketClient
from config import Config

def main():
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Initialize bot
    bot = DexonicTradingBot()
    
    # Setup WebSocket for real-time updates
    def handle_websocket_message(data):
        print(f"Real-time update: {data}")
    
    ws_client = DexonicWebSocketClient(Config.WS_URL, handle_websocket_message)
    ws_client.connect()
    
    try:
        # Start the trading bot
        user_address = "0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d"
        bot_response = bot.start_rebalancing_bot(user_address)
        
        print(f"Bot started successfully: {bot_response}")
        
        # Monitor the bot
        bot.monitor_bot(interval=60)
        
    except KeyboardInterrupt:
        print("Stopping bot...")
        bot.stop_bot()
        ws_client.disconnect()
    except Exception as e:
        print(f"Error: {e}")
        bot.stop_bot()
        ws_client.disconnect()

if __name__ == "__main__":
    main()
```

---

## 🔧 Testing

### Frontend Testing
```typescript
// tests/api.test.ts
import { renderHook } from '@testing-library/react';
import { useVaultStatus } from '../hooks/useVault';

describe('Vault API', () => {
  it('should fetch vault status', async () => {
    const { result } = renderHook(() => useVaultStatus());
    
    // Wait for data to load
    await waitFor(() => {
      expect(result.current.data).toBeDefined();
    });
    
    expect(result.current.data?.success).toBe(true);
  });
});
```

### Bot Testing
```python
# tests/test_trading_bot.py
import unittest
from trading_bot import DexonicTradingBot

class TestTradingBot(unittest.TestCase):
    def setUp(self):
        self.bot = DexonicTradingBot()
    
    def test_start_bot(self):
        user_address = "0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d"
        response = self.bot.start_rebalancing_bot(user_address)
        
        self.assertTrue(response['success'])
        self.assertIsNotNone(response['data']['bot_id'])
    
    def test_get_market_analysis(self):
        analysis = self.bot.get_market_analysis()
        
        self.assertIn('apt_price', analysis)
        self.assertIn('trend', analysis)
        self.assertIn('rebalance_needed', analysis)

if __name__ == '__main__':
    unittest.main()
```

---

## 🚀 Deployment

### Frontend Deployment
```bash
# Build for production
npm run build

# Deploy to Vercel
vercel --prod

# Deploy to Netlify
netlify deploy --prod
```

### Bot Deployment
```bash
# Docker deployment
docker build -t dexonic-bot .
docker run -d --name dexonic-bot dexonic-bot

# Kubernetes deployment
kubectl apply -f k8s/deployment.yaml
```

---

## 📊 Monitoring

### Frontend Monitoring
- **Error Tracking**: Sentry integration
- **Performance**: Lighthouse CI
- **Analytics**: Google Analytics
- **Uptime**: StatusCake

### Bot Monitoring
- **Logs**: ELK Stack
- **Metrics**: Prometheus + Grafana
- **Alerts**: PagerDuty
- **Health Checks**: Custom health endpoints

---

## 🎯 Conclusion

Hướng dẫn tích hợp này cung cấp:
- ✅ Complete API integration examples
- ✅ Real-time WebSocket connections
- ✅ Error handling và monitoring
- ✅ Testing strategies
- ✅ Deployment instructions

**Status**: 🟢 **READY FOR DEVELOPMENT** 