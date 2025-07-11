# 🔌 API Documentation - Dexonic Asset Vault

## 📋 Tổng quan API

Dexonic Asset Vault cung cấp RESTful API để tương tác với smart contracts và quản lý vault operations.

### 🔗 Base URLs
- **Development**: `http://localhost:5001/api`
- **Production**: `https://api.dexonic-vault.com/api`
- **WebSocket**: `wss://api.dexonic-vault.com/ws`

---

## 🏦 Vault API Endpoints

### 📊 Vault Status

#### GET `/vault/status`
Lấy thông tin tổng quan của vault

**Response:**
```json
{
  "success": true,
  "data": {
    "total_shares": "1000000000",
    "total_usdt": "500000000",
    "total_apt": "250000000",
    "apt_price_usd": "8.50",
    "vault_value_usd": "4625000",
    "apy": "12.5",
    "last_rebalance": "1702123456",
    "rebalance_threshold": "10",
    "target_ratio": {
      "usdt": "50",
      "apt": "50"
    }
  }
}
```

#### GET `/vault/performance`
Lấy thông tin performance của vault

**Response:**
```json
{
  "success": true,
  "data": {
    "daily_return": "0.85",
    "weekly_return": "5.2",
    "monthly_return": "18.7",
    "total_return": "45.3",
    "volatility": "12.4",
    "sharpe_ratio": "1.8",
    "max_drawdown": "-8.2",
    "rebalance_count": 15,
    "last_rebalance_profit": "2.1"
  }
}
```

### 👤 User Operations

#### GET `/vault/balance/{address}`
Lấy balance của user

**Parameters:**
- `address` (string): Aptos address của user

**Response:**
```json
{
  "success": true,
  "data": {
    "shares": "10000000",
    "usdt_balance": "5000000",
    "apt_balance": "2500000",
    "total_value_usd": "46250",
    "last_deposit": "1702123456",
    "last_withdraw": "1702000000",
    "profit_loss": "1250.50",
    "profit_loss_percentage": "2.8"
  }
}
```

#### POST `/vault/deposit`
Deposit USDT vào vault

**Request Body:**
```json
{
  "user_address": "0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d",
  "amount": "1000000",
  "slippage": "0.5"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transaction_hash": "0xabc123...",
    "shares_minted": "10000000",
    "gas_used": "5085",
    "explorer_url": "https://explorer.aptoslabs.com/txn/0xabc123..."
  }
}
```

#### POST `/vault/withdraw`
Withdraw shares từ vault

**Request Body:**
```json
{
  "user_address": "0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d",
  "shares": "5000000",
  "slippage": "0.5"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transaction_hash": "0xdef456...",
    "usdt_received": "5000000",
    "gas_used": "4200",
    "explorer_url": "https://explorer.aptoslabs.com/txn/0xdef456..."
  }
}
```

#### POST `/vault/rebalance`
Trigger manual rebalancing

**Request Body:**
```json
{
  "owner_address": "0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d",
  "usdt_amount": "1000000"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transaction_hash": "0xghi789...",
    "usdt_swapped": "1000000",
    "apt_received": "117647",
    "gas_used": "6500",
    "explorer_url": "https://explorer.aptoslabs.com/txn/0xghi789..."
  }
}
```

---

## 🌉 LayerZero Bridge API

### 🔗 Bridge Operations

#### GET `/bridge/status/{tx_hash}`
Kiểm tra trạng thái bridge transaction

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "completed",
    "source_chain": "ethereum",
    "destination_chain": "aptos",
    "amount": "1000000",
    "fee": "15000000",
    "estimated_time": "300",
    "elapsed_time": "450",
    "explorer_url": "https://layerzeroscan.com/tx/0xabc123..."
  }
}
```

#### POST `/bridge/initiate`
Khởi tạo bridge transaction

**Request Body:**
```json
{
  "source_chain": "ethereum",
  "amount": "1000000",
      "recipient_address": "0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d",
  "user_address": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "bridge_id": "bridge_123456",
    "transaction_hash": "0xabc123...",
    "estimated_time": "600",
    "fee": "15000000",
    "status": "pending"
  }
}
```

#### GET `/bridge/history/{address}`
Lấy lịch sử bridge của user

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "bridge_id": "bridge_123456",
      "source_chain": "ethereum",
      "amount": "1000000",
      "status": "completed",
      "created_at": "1702123456",
      "completed_at": "1702124056",
      "transaction_hash": "0xabc123..."
    }
  ]
}
```

---

## 🤖 Trading Bot API

### 📊 Market Data

#### GET `/trading/market-data`
Lấy dữ liệu thị trường real-time

**Response:**
```json
{
  "success": true,
  "data": {
    "apt_price_usd": "8.50",
    "apt_price_change_24h": "2.5",
    "apt_volume_24h": "15000000",
    "usdt_apt_ratio": "0.1176",
    "market_cap": "2850000000",
    "fear_greed_index": "65",
    "volatility": "12.4",
    "trend": "bullish"
  }
}
```

#### GET `/trading/price-history`
Lấy lịch sử giá APT

**Parameters:**
- `timeframe` (string): `1h`, `4h`, `1d`, `1w`, `1m`
- `limit` (number): Số lượng data points

**Response:**
```json
{
  "success": true,
  "data": {
    "timeframe": "1d",
    "prices": [
      {
        "timestamp": "1702123456",
        "price": "8.45",
        "volume": "15000000"
      }
    ]
  }
}
```

### 🤖 Bot Operations

#### POST `/trading/bot/start`
Khởi động trading bot

**Request Body:**
```json
{
  "strategy": "rebalancing",
  "parameters": {
    "rebalance_threshold": "10",
    "target_ratio": {
      "usdt": "50",
      "apt": "50"
    },
    "max_slippage": "0.5",
    "gas_limit": "100000"
  },
  "auto_trading": true,
  "notification": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "bot_id": "bot_123456",
    "status": "running",
    "strategy": "rebalancing",
    "started_at": "1702123456",
    "estimated_apy": "15.2"
  }
}
```

#### POST `/trading/bot/stop`
Dừng trading bot

**Request Body:**
```json
{
  "bot_id": "bot_123456"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "bot_id": "bot_123456",
    "status": "stopped",
    "stopped_at": "1702123456",
    "total_trades": 25,
    "total_profit": "1250.50"
  }
}
```

#### GET `/trading/bot/status/{bot_id}`
Lấy trạng thái trading bot

**Response:**
```json
{
  "success": true,
  "data": {
    "bot_id": "bot_123456",
    "status": "running",
    "strategy": "rebalancing",
    "started_at": "1702123456",
    "total_trades": 25,
    "successful_trades": 23,
    "failed_trades": 2,
    "total_profit": "1250.50",
    "current_balance": {
      "usdt": "5000000",
      "apt": "2500000"
    },
    "last_trade": {
      "timestamp": "1702123456",
      "type": "buy",
      "amount": "1000000",
      "price": "8.50"
    }
  }
}
```

#### GET `/trading/bot/history/{bot_id}`
Lấy lịch sử giao dịch của bot

**Response:**
```json
{
  "success": true,
  "data": {
    "bot_id": "bot_123456",
    "trades": [
      {
        "trade_id": "trade_123",
        "timestamp": "1702123456",
        "type": "buy",
        "amount": "1000000",
        "price": "8.50",
        "gas_used": "5085",
        "status": "success",
        "profit": "50.25"
      }
    ]
  }
}
```

### 📈 Analytics

#### GET `/trading/analytics/performance`
Lấy analytics performance

**Response:**
```json
{
  "success": true,
  "data": {
    "total_trades": 150,
    "win_rate": "85.3",
    "average_profit": "45.20",
    "max_profit": "250.00",
    "max_loss": "-25.50",
    "sharpe_ratio": "1.8",
    "sortino_ratio": "2.1",
    "calmar_ratio": "3.2",
    "max_drawdown": "-8.2",
    "profit_factor": "2.5"
  }
}
```

#### GET `/trading/analytics/risk`
Lấy risk metrics

**Response:**
```json
{
  "success": true,
  "data": {
    "var_95": "2.5",
    "var_99": "4.8",
    "volatility": "12.4",
    "beta": "0.85",
    "correlation": "0.72",
    "downside_deviation": "8.5",
    "ulcer_index": "2.1"
  }
}
```

---

## 🔔 WebSocket API

### 📡 Real-time Updates

#### Connection
```javascript
const ws = new WebSocket('wss://api.dexonic-vault.com/ws');

ws.onopen = () => {
  // Subscribe to channels
  ws.send(JSON.stringify({
    action: 'subscribe',
    channels: ['vault_status', 'price_updates', 'bot_alerts']
  }));
};
```

#### Message Types

**Vault Status Update:**
```json
{
  "type": "vault_status",
  "data": {
    "total_shares": "1000000000",
    "total_usdt": "500000000",
    "total_apt": "250000000",
    "vault_value_usd": "4625000",
    "apy": "12.5"
  }
}
```

**Price Update:**
```json
{
  "type": "price_update",
  "data": {
    "apt_price_usd": "8.50",
    "apt_price_change_24h": "2.5",
    "timestamp": "1702123456"
  }
}
```

**Bot Alert:**
```json
{
  "type": "bot_alert",
  "data": {
    "bot_id": "bot_123456",
    "alert_type": "rebalance_triggered",
    "message": "Vault rebalanced: USDT 45% → 50%",
    "timestamp": "1702123456"
  }
}
```

---

## 🔐 Authentication

### API Keys
```bash
# Header
Authorization: Bearer YOUR_API_KEY
```

### Rate Limits
- **Free Tier**: 100 requests/hour
- **Pro Tier**: 1000 requests/hour
- **Enterprise**: Custom limits

---

## 📝 Error Codes

| Code | Message | Description |
|------|---------|-------------|
| 400 | Bad Request | Invalid parameters |
| 401 | Unauthorized | Missing or invalid API key |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

---

## 🚀 SDK Examples

### JavaScript/TypeScript
```javascript
import { DexonicAPI } from '@dexonic/api';

const api = new DexonicAPI({
  apiKey: 'YOUR_API_KEY',
  baseURL: 'https://api.dexonic-vault.com/api'
});

// Get vault status
const status = await api.vault.getStatus();

// Deposit USDT
const deposit = await api.vault.deposit({
  userAddress: '0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d',
  amount: '1000000'
});

// Start trading bot
const bot = await api.trading.startBot({
  strategy: 'rebalancing',
  parameters: {
    rebalanceThreshold: 10,
    targetRatio: { usdt: 50, apt: 50 }
  }
});
```

### Python
```python
from dexonic_api import DexonicAPI

api = DexonicAPI(
    api_key='YOUR_API_KEY',
    base_url='https://api.dexonic-vault.com/api'
)

# Get vault status
status = api.vault.get_status()

# Deposit USDT
deposit = api.vault.deposit(
    user_address='0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d',
    amount='1000000'
)

# Start trading bot
bot = api.trading.start_bot(
    strategy='rebalancing',
    parameters={
        'rebalance_threshold': 10,
        'target_ratio': {'usdt': 50, 'apt': 50}
    }
)
```

---

## 📊 API Status

### Health Check
```bash
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "1702123456",
  "version": "1.0.0",
  "services": {
    "vault": "healthy",
    "bridge": "healthy",
    "trading": "healthy",
    "database": "healthy"
  }
}
```

---

## 🎯 Conclusion

API này cung cấp đầy đủ các endpoint để:
- ✅ Quản lý vault operations
- ✅ Bridge cross-chain assets
- ✅ Trading bot automation
- ✅ Real-time market data
- ✅ Analytics và reporting

**Status**: 🟢 **READY FOR INTEGRATION** 